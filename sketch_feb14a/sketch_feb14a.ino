#include <SPI.h>
#include <Ethernet.h>
#include <MFRC522.h>
#include <DHT.h>

// --- RED CONFIG ---
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
IPAddress ip(192, 168, 1, 11);          // IP del Controllino (estática)
IPAddress server(192, 168, 1, 10);     // IP de tu PC (Ethernet 4)
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

// --- VARIABLES DE ESTADO ---
String ultimoID = "N/A";
unsigned long ultimoEnvio = 0;
const unsigned long intervalo = 30000; // 30 segundos

void setup() {
  Serial.begin(9600);
  
  // 1. Limpieza del bus SPI (Específico para Controllino Mega)
  pinMode(ETH_CS, OUTPUT);  digitalWrite(ETH_CS, HIGH);
  pinMode(RFID_CS, OUTPUT); digitalWrite(RFID_CS, HIGH);
  pinMode(4, OUTPUT);       digitalWrite(4, HIGH); 
  pinMode(11, OUTPUT);      digitalWrite(11, HIGH); // RTC (Reloj interno)

  delay(500);
  SPI.begin();

  // 2. Inicio de sensores
  rfid.PCD_Init();
  dht.begin();

  // 3. Conexión Directa (Modo TFG)
  Ethernet.begin(mac, ip);

  Serial.println(F("🚀 MODO TFG LISTO (Directo al PC)"));
  Serial.print(F("IP Controllino: ")); Serial.println(Ethernet.localIP());
  Serial.print(F("Servidor (PC): ")); Serial.println(server);
}

void loop() {
  // 1. GESTIÓN RFID
  digitalWrite(ETH_CS, HIGH); 
  digitalWrite(RFID_CS, LOW);

  if (rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial()) {
    ultimoID = "";
    for (byte i = 0; i < rfid.uid.size; i++) {
      ultimoID += (rfid.uid.uidByte[i] < 0x10 ? "0" : "");
      ultimoID += String(rfid.uid.uidByte[i], HEX);
      if (i < rfid.uid.size - 1) ultimoID += ":";
    }
    ultimoID.toUpperCase();
    
    Serial.print(F("💳 RFID DETECTADO: "));
    Serial.println(ultimoID);
    
    enviarAlBackend(ultimoID); // Envío inmediato por evento
    rfid.PICC_HaltA();
  }
  digitalWrite(RFID_CS, HIGH);

  // 2. ENVÍO PERIÓDICO (Cada 30s)
  if (millis() - ultimoEnvio > intervalo) {
    enviarAlBackend(ultimoID);
    ultimoEnvio = millis();
  }
}

void enviarAlBackend(String rfidTag) {
  digitalWrite(ETH_CS, LOW);
  float t = dht.readTemperature();
  float h = dht.readHumidity();

  if (isnan(t) || isnan(h)) {
    Serial.println(F("❌ Error leyendo sensores DHT"));
    return;
  }

  Serial.println(F("Connecting to backend..."));
  if (client.connect(server, port)) {
    Serial.println(F("✅ Conectado. Enviando POST..."));
    
    // Construir JSON manualmente para evitar librerías pesadas
    String json = "{";
    json += "\"maquinaId\": 1,"; // Asumimos ID 1 para este PLC
    json += "\"temperatura\": " + String(t) + ",";
    json += "\"humedad\": " + String(h) + ",";
    json += "\"rfidTag\": \"" + rfidTag + "\",";
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

    Serial.println(F("📤 Datos enviados correctamente"));
  } else {
    Serial.println(F("❌ Fallo en la conexión al backend"));
  }
  client.stop();
  digitalWrite(ETH_CS, HIGH);
}