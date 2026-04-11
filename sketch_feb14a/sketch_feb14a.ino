#include <SPI.h>
#include <Ethernet.h>
#include <MFRC522.h>
#include <DHT.h>

/**
 * 🛰️ MELTIC GMAO INDUSTRIAL - FIRMWARE V5.0 (MODO SERVIDOR)
 * Optimizada para polling dinámico desde GMAO Backend (Spring Boot).
 * 
 * IP Controllino: 192.168.1.11
 * Escucha en puerto: 80
 */

// --- CONFIGURACIÓN DE RED ---
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
IPAddress ip(192, 168, 1, 11); // IP fija del PLC
EthernetServer server(80);     // Ahora actuamos como servidor

// --- PINES CONTROLLINO ---
#define ETH_CS    10
#define RFID_CS   53
#define RST_PIN   5
#define DHTPIN    2
#define DHTTYPE   DHT11

MFRC522 rfid(RFID_CS, RST_PIN);
DHT dht(DHTPIN, DHTTYPE);

// --- ESTADO GLOBAL ---
String rfidActual = "N/A";
float tActual = 0.0, hActual = 0.0;
unsigned long tiempoUltimaLecturaRFID = 0;
unsigned long ultimoSensorUpdate = 0;
const unsigned long delayLimpiezaRFID = 3000; // 3s para considerar tarjeta retirada

void setup() {
  Serial.begin(9600);
  
  // 1. Aislamiento SPI (Crítico en Controllino/Mega)
  pinMode(ETH_CS, OUTPUT);  digitalWrite(ETH_CS, HIGH); 
  pinMode(RFID_CS, OUTPUT); digitalWrite(RFID_CS, HIGH); 
  pinMode(4, OUTPUT);       digitalWrite(4, HIGH); // SD Pin
  pinMode(RST_PIN, OUTPUT); digitalWrite(RST_PIN, HIGH);

  delay(1000);
  SPI.begin();

  // 2. Inicializar Sensores 
  rfid.PCD_Init();
  dht.begin();
  
  // 3. Inicializar Red
  Ethernet.begin(mac, ip);
  server.begin();
  
  Serial.println(F("--- MELTIC PLC SERVER OPERATIVO ---"));
  Serial.print(F("📍 IP PLC: ")); Serial.println(Ethernet.localIP());
  Serial.println(F("🕒 Esperando peticiones de GMAO..."));
}

void loop() {
  // A. Actualizar Sensores DHT cada 5 segundos
  if (millis() - ultimoSensorUpdate > 5000) {
    float nt = dht.readTemperature();
    float nh = dht.readHumidity();
    if (!isnan(nt) && !isnan(nh) && nt > 0.5) {
      tActual = nt;
      hActual = nh;
    }
    ultimoSensorUpdate = millis();
  }

  // B. Escanear RFID (Aislamiento SPI)
  digitalWrite(ETH_CS, HIGH); // Desactivar Ethernet temporalmente
  digitalWrite(RFID_CS, LOW); // Activar RFID
  
  if (rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial()) {
    String currentID = "";
    for (byte i = 0; i < rfid.uid.size; i++) {
      currentID += (rfid.uid.uidByte[i] < 0x10 ? "0" : "");
      currentID += String(rfid.uid.uidByte[i], HEX);
      if (i < rfid.uid.size - 1) currentID += ":";
    }
    currentID.toUpperCase();
    rfidActual = currentID;
    tiempoUltimaLecturaRFID = millis();
    
    rfid.PICC_HaltA();
    rfid.PCD_StopCrypto1();
  } else {
    // Si ha pasado el tiempo de gracia, limpiar el tag
    if (rfidActual != "N/A" && (millis() - tiempoUltimaLecturaRFID > delayLimpiezaRFID)) {
      rfidActual = "N/A";
    }
  }
  digitalWrite(RFID_CS, HIGH);

  // C. Gestionar Petición Web (PULL de GMAO)
  EthernetClient client = server.available();
  if (client) {
    Serial.println(F("📡 Consulta desde GMAO detectada"));
    boolean currentLineIsBlank = true;
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        if (c == '\n' && currentLineIsBlank) {
          // Envío de cabeceras HTTP
          client.println(F("HTTP/1.1 200 OK"));
          client.println(F("Content-Type: application/json"));
          client.println(F("Access-Control-Allow-Origin: *")); // Habilitar CORS
          client.println(F("Connection: close"));
          client.println();
          
          // Envío de JSON
          client.print(F("{"));
          client.print(F("\"maquinaId\": 1,"));
          client.print(F("\"temperatura\": ")); client.print(tActual); client.print(F(","));
          client.print(F("\"humedad\": ")); client.print(hActual); client.print(F(","));
          client.print(F("\"rfid\": \"")); client.print(rfidActual); client.print(F("\","));
          client.print(F("\"motorOn\": true"));
          client.println(F("}"));
          break;
        }
        if (c == '\n') currentLineIsBlank = true;
        else if (c != '\r') currentLineIsBlank = false;
      }
    }
    client.stop();
    Serial.println(F("✅ Telemetría entregada"));
  }
  
  delay(10);
}