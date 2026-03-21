#include <SPI.h>
#include <Ethernet.h>
#include <MFRC522.h>
#include <DHT.h>

// --- RED ---
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
IPAddress ip(192, 168, 1, 177);
EthernetServer server(80);

// --- PINES ---
#define ETH_CS    10
#define RFID_CS   53
#define RST_PIN   5
#define DHTPIN    2
#define DHTTYPE   DHT11

MFRC522 rfid(RFID_CS, RST_PIN);
DHT dht(DHTPIN, DHTTYPE);

// Variable global para guardar el último ID leído
String ultimoID = "Ninguna tarjeta detectada";

void setup() {
  Serial.begin(9600);
  
  pinMode(10, OUTPUT);  digitalWrite(10, HIGH);
  pinMode(53, OUTPUT);  digitalWrite(53, HIGH);
  pinMode(4, OUTPUT);   digitalWrite(4, HIGH); 

  Ethernet.begin(mac, ip);
  server.begin();
  dht.begin();
  SPI.begin();
  rfid.PCD_Init();

  Serial.println(F("✅ Visor de IDs MELTIC listo..."));
}

void loop() {
  // 1. GESTIÓN RFID (Le damos prioridad)
  digitalWrite(ETH_CS, HIGH); // Apagamos Ethernet un momento
  
  if (rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial()) {
    ultimoID = ""; // Limpiamos el ID anterior
    for (byte i = 0; i < rfid.uid.size; i++) {
      ultimoID += (rfid.uid.uidByte[i] < 0x10 ? "0" : "");
      ultimoID += String(rfid.uid.uidByte[i], HEX);
      if (i < rfid.uid.size - 1) ultimoID += ":";
    }
    ultimoID.toUpperCase(); // Lo ponemos en mayúsculas para que quede profesional
    
    Serial.print(F("💳 NUEVA TARJETA: "));
    Serial.println(ultimoID);
    
    rfid.PICC_HaltA(); // Paramos la lectura para no saturar
  }
  digitalWrite(RFID_CS, HIGH); // Liberamos el bus para Ethernet

  // 2. SERVIDOR WEB
  EthernetClient client = server.available();
  if (client) {
    bool currentLineIsBlank = true;
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        if (c == '\n' && currentLineIsBlank) {
          client.println("HTTP/1.1 200 OK\nContent-Type: application/json\nConnection: close\n");
          
          client.print("{");
          client.print("\"temperatura\": "); client.print(dht.readTemperature()); client.print(", ");
          client.print("\"humedad\": "); client.print(dht.readHumidity()); client.print(", ");
          client.print("\"rfid\": \""); client.print(ultimoID); client.print("\"");
          client.println("}");
          break;
        }
        if (c == '\n') currentLineIsBlank = true;
        else if (c != '\r') currentLineIsBlank = false;
      }
    }
    client.stop();
  }
}