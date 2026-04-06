#include <SPI.h>
#include <Ethernet.h>
#include <MFRC522.h>
#include <DHT.h>

// --- CONFIGURACIÓN DE RED (Manteniendo tus IPs actuales que conectan bien) ---
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
IPAddress ip(192, 168, 1, 11);
IPAddress server(192, 168, 1, 10); 
int port = 8080;

EthernetClient client;

// --- PINES ---
#define ETH_CS    10
#define RFID_CS   53
#define RST_PIN   5
#define DHTPIN    2
#define DHTTYPE   DHT11

MFRC522 rfid(RFID_CS, RST_PIN);
DHT dht(DHTPIN, DHTTYPE);

String ultimoID = "N/A";
unsigned long ultimoEnvio = 0;
const unsigned long intervalo = 30000; // Volvemos a los 30s originales

void setup() {
  Serial.begin(9600);
  
  // 1. Aislamiento CRÍTICO: Desactivar Ethernet antes de nada
  pinMode(ETH_CS, OUTPUT);  digitalWrite(ETH_CS, HIGH); // Pin 10
  pinMode(RFID_CS, OUTPUT); digitalWrite(RFID_CS, HIGH); // Pin 53
  pinMode(4, OUTPUT);       digitalWrite(4, HIGH);       // SD Card
  pinMode(RST_PIN, OUTPUT); digitalWrite(RST_PIN, HIGH); // Reset RFID

  delay(1000);
  SPI.begin();

  // 2. Inicializar Sensores con la red apagada
  rfid.PCD_Init();
  dht.begin();
  Serial.println(F("--- Sensores RFID/DHT Listos ---"));

  // 3. Inicializar Red
  Ethernet.begin(mac, ip);
  Serial.println(F("🚀 SISTEMA MELTIC 4.0 OPERATIVO"));
}

unsigned long tiempoUltimaLectura = 0;
unsigned long ultimoSensorUpdate = 0;
const unsigned long delayLimpieza = 2500; 
float tActual = 0.0, hActual = 0.0;

void loop() {
  // 1. Actualizar Sensores cada 5 segundos (DHT11 es lento)
  if (millis() - ultimoSensorUpdate > 5000 || ultimoSensorUpdate == 0) {
    float nt = dht.readTemperature();
    float nh = dht.readHumidity();
    if (!isnan(nt) && !isnan(nh) && nt > 0.5) {
      tActual = nt;
      hActual = nh;
    }
    ultimoSensorUpdate = millis();
  }

  // Aislamiento SPI para el lector RFID
  digitalWrite(ETH_CS, HIGH); 
  digitalWrite(4, HIGH);
  digitalWrite(RFID_CS, LOW);

  // 2. Lógica RFID: ¿Hay tarjeta nueva?
  if (rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial()) {
    String currentID = "";
    for (byte i = 0; i < rfid.uid.size; i++) {
      currentID += (rfid.uid.uidByte[i] < 0x10 ? "0" : "");
      currentID += String(rfid.uid.uidByte[i], HEX);
      if (i < rfid.uid.size - 1) currentID += ":";
    }
    currentID.toUpperCase();

    if (currentID != ultimoID) {
      ultimoID = currentID;
      Serial.print(F("💳 TARJETA: "));
      Serial.println(ultimoID);
      enviarAlBackend(ultimoID, tActual, hActual);
    }
    
    tiempoUltimaLectura = millis(); 
    rfid.PICC_HaltA();
    rfid.PCD_StopCrypto1();
  } else {
    // Si no hay tarjeta, ¿ha pasado el tiempo de gracia?
    if (ultimoID != "N/A" && (millis() - tiempoUltimaLectura > delayLimpieza)) {
      Serial.println(F("🔄 Lector disponible"));
      ultimoID = "N/A";
      enviarAlBackend("N/A", tActual, hActual);
    }
  }

  // 3. ENVÍO PERIÓDICO (Telemetría de seguridad cada 30s)
  if (millis() - ultimoEnvio > intervalo) {
    enviarAlBackend(ultimoID, tActual, hActual);
    ultimoEnvio = millis();
  }

  digitalWrite(RFID_CS, HIGH);
  delay(150); 
}

void enviarAlBackend(String tag, float t, float h) {
  // Aislamiento SPI para Red
  digitalWrite(RFID_CS, HIGH);
  delay(100); // Margen de seguridad para el bus SPI
  digitalWrite(ETH_CS, LOW);
  
  bool conectado = false;
  int intentos = 0;

  // Reintento 3 veces antes de rendirse
  while (!conectado && intentos < 3) {
    if (client.connect(server, port)) {
      conectado = true;
    } else {
      intentos++;
      Serial.print(F("⚠️ Reintentando conexión... ("));
      Serial.print(intentos);
      Serial.println(F("/3)"));
      delay(500);
    }
  }

  if (conectado) {
    Serial.print(F("🛰️ Enviando... (TAG: "));
    Serial.print(tag);
    Serial.println(F(")"));

    String json = "{";
    json += "\"maquinaId\": 1,";
    json += "\"temperatura\": " + String(t) + ",";
    json += "\"humedad\": " + String(h) + ",";
    json += "\"rfidTag\": \"" + tag + "\",";
    json += "\"motorOn\": true,";
    json += "\"alarma\": null";
    json += "}";

    client.println("POST /api/plc/data HTTP/1.1");
    client.print("Host: "); client.println(server);
    client.println("Content-Type: application/json");
    client.print("Content-Length: "); client.println(json.length());
    client.println("Connection: close");
    client.println();
    client.println(json);
    
    Serial.print(F("✅ Envío OK (Temp: "));
    Serial.print(t);
    Serial.print(F(" C)"));
    if (tag != "N/A") Serial.println(F(" - LOGIN OK")); else Serial.println();
    
  } else {
    Serial.println(F("❌ ERROR FINAL: No se pudo conectar tras 3 intentos."));
  }
  
  client.stop();
  delay(50); // Pausa post-conexión
  digitalWrite(ETH_CS, HIGH);
}