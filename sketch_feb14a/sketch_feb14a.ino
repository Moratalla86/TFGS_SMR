#include <SPI.h>
#include <MFRC522.h>
#include <DHT.h>
#include <Ethernet.h>

// --- CONFIGURACIÓN HARDWARE ---
#define DHTPIN 2          // Pin digital para DHT11
#define DHTTYPE DHT11
#define RST_PIN 9         // Reset para RC522
#define SS_PIN 53         // SDA (SS) para RC522 en Controllino Mega/Maxi

// --- RED ---
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
IPAddress server(192, 168, 1, 100); // IP de tu PC donde corre Spring Boot
EthernetClient client;

DHT dht(DHTPIN, DHTTYPE);
MFRC522 mfrc522(SS_PIN, RST_PIN);

void setup() {
  Serial.begin(9600);
  SPI.begin();
  mfrc522.PCD_Init();
  dht.begin();
  
  if (Ethernet.begin(mac) == 0) {
    Serial.println("Error al configurar Ethernet mediante DHCP");
  }
  delay(1000);
  Serial.println("Controllino listo. Esperando lectura...");
}

void loop() {
  leerRFID();
  enviarTelemetria();
  delay(5000); // Enviar datos cada 5 segundos según Fase 3
}

void leerRFID() {
  if (!mfrc522.PICC_IsNewCardPresent() || !mfrc522.PICC_ReadCardSerial()) return;

  String uid = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    uid += String(mfrc522.uid.uidByte[i] < 0x10 ? "0" : "");
    uid += String(mfrc522.uid.uidByte[i], HEX);
  }
  uid.toUpperCase();
  Serial.print("RFID Detectado: "); Serial.println(uid);
  
  // Enviar GET a AuthController /api/usuarios/rfid/{tag}
  if (client.connect(server, 8080)) {
    client.println("GET /api/usuarios/rfid/" + uid + " HTTP/1.1");
    client.println("Host: 192.168.1.100");
    client.println("Connection: close");
    client.println();
    client.stop();
  }
  mfrc522.PICC_HaltA();
}

void enviarTelemetria() {
  float h = dht.readHumidity();
  float t = dht.readTemperature();

  if (isnan(h) || isnan(t)) return;

  // JSON para MongoDB
  String json = "{\"maquinaId\":1, \"temperatura\":" + String(t) + ", \"humedad\":" + String(h) + "}";
  enviarAlBackend("/api/plc/data", json);
}

void enviarAlBackend(String endpoint, String data) {
  if (client.connect(server, 8080)) {
    client.println("POST " + endpoint + " HTTP/1.1");
    client.println("Host: 192.168.1.100");
    client.println("Content-Type: application/json");
    client.print("Content-Length: "); client.println(data.length());
    client.println();
    client.print(data);
    client.stop();
  }
}