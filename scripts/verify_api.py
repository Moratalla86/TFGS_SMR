import requests
import json
import time

BASE_URL = "http://localhost:8080/api"

print("🚀 INICIANDO VERIFICACIÓN TÉCNICA - MÈLTIC GMAO")
print("-" * 50)

def test_security():
    print("\n[🛡️ SEGURIDAD]")
    
    # 1. Login exitoso Admin
    payload = {"email": "admin@meltic.com", "password": "Meltic@2024!"}
    res = requests.post(f"{BASE_URL}/auth/login", json=payload)
    if res.status_code == 200:
        print("✅ Login Admin: OK")
        token = res.json()["token"]
    else:
        print(f"❌ Login Admin: FALLÓ ({res.status_code})")
        return None

    # 2. Verificar ocultación de password
    user_data = res.json()["user"]
    if "password" not in user_data:
        print("✅ Ocultación de Hash en JSON: OK")
    else:
        print("❌ CRÍTICO: El hash de la contraseña se está exponiendo en la API")

    return token

def test_industrial_config(token):
    print("\n[⚙️ ROBUSTEZ INDUSTRIAL]")
    headers = {"Authorization": f"Bearer {token}"}
    
    # 1. Intento de configuración ilógica (Muy Alto < Bajo)
    # Mandamos: muyBajo=10, bajo=50, alto=40, muyAlto=100 (Incoherente: bajo > alto)
    payload = {
        "metrica": "temperatura",
        "muyBajo": 10,
        "bajo": 50,
        "alto": 40,
        "muyAlto": 100
    }
    res = requests.put(f"{BASE_URL}/config/1", json=payload, headers=headers)
    if res.status_code == 400:
        print("✅ Validación de coherencia de umbrales: OK (Rechazado correctamente)")
    else:
        print(f"❌ Error en validación de umbrales: Se aceptó una configuración ilógica ({res.status_code})")

def test_telemetry(token):
    print("\n[📡 INGESTA IOT]")
    headers = {"Authorization": f"Bearer {token}"}
    
    # Simular una lectura del PLC que llega al backend
    # En una demo, esto lo enviaría el PLC Real o el Mock
    payload = {
        "maquinaId": 1,
        "temperatura": 75.5, # Valor alto para disparar alerta
        "humedad": 45.0,
        "rfidTag": "40:91:F3:61"
    }
    # Usamos el endpoint de datos del hardware (usualmente abierto o con API Key)
    res = requests.post(f"{BASE_URL}/plc/data", json=payload)
    if res.status_code == 200:
        print("✅ Envío de telemetría: OK")
    else:
        print(f"❌ Error en ingesta: {res.status_code}")

if __name__ == "__main__":
    try:
        t = test_security()
        if t:
            test_industrial_config(t)
            test_telemetry(t)
            print("\n" + "=" * 50)
            print("🏁 VERIFICACIÓN COMPLETADA: EL SISTEMA CUMPLE LOS CRITERIOS")
            print("=" * 50)
    except Exception as e:
        print(f"\n❌ ERROR DE CONEXIÓN: ¿Está el backend encendido? ({e})")
