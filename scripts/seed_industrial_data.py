import urllib.request
import json
import random
from datetime import datetime, timedelta

BASE_URL = "http://localhost:8080/api"

def api_call(endpoint, method="GET", data=None, token=None):
    url = f"{BASE_URL}{endpoint}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    
    req_data = json.dumps(data).encode("utf-8") if data else None
    req = urllib.request.Request(url, data=req_data, headers=headers, method=method)
    
    try:
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read().decode("utf-8"))
    except Exception as e:
        return None

def seed():
    print("--- Iniciando siembra industrial PRO (Clean Print) ---")
    
    # 1. Login
    login_res = api_call("/auth/login", method="POST", data={"email": "admin@meltic.com", "password": "Meltic@2024!"})
    if not login_res:
        print("Error de login")
        return
    token = login_res.get("token")

    # 2. Crear Catalogo con Telemetria
    def get_configs():
        return [
            {"nombreMetrica": "Temperatura", "unidadSeleccionada": "°C", "limiteMB": 10.0, "limiteB": 20.0, "limiteA": 65.0, "limiteMA": 85.0, "habilitado": True},
            {"nombreMetrica": "Vibracion", "unidadSeleccionada": "mm/s", "limiteMB": 0.5, "limiteB": 1.5, "limiteA": 6.5, "limiteMA": 9.5, "habilitado": True},
            {"nombreMetrica": "Presion", "unidadSeleccionada": "bar", "limiteMB": 2.0, "limiteB": 4.0, "limiteA": 12.0, "limiteMA": 15.0, "habilitado": True}
        ]

    catalogo = [
        {"nombre": "TORNO CNC - OKUMA VT-50", "modelo": "VT-50", "descripcion": "Torno de alta precision para ejes", "ubicacion": "Taller A1", "plcUrl": "192.168.1.50", "configs": get_configs()},
        {"nombre": "INYECTORA PLASTICO - ARBURG 470", "modelo": "470C", "descripcion": "Inyeccion de componentes termoplasticos", "ubicacion": "Linea 2", "plcUrl": "192.168.1.51", "configs": get_configs()},
        {"nombre": "BRAZO ROBOTICO - FANUC R2000", "modelo": "R2000iB", "descripcion": "Paletizado automatico de cajas", "ubicacion": "Final Linea 3", "plcUrl": "192.168.1.52", "configs": get_configs()},
        {"nombre": "PRENSA HIDRAULICA - PH-500", "modelo": "PH-500-S", "descripcion": "Estampacion de paneles metalicos", "ubicacion": "Zona Forja", "plcUrl": "192.168.1.53", "configs": get_configs()},
        {"nombre": "COMPRESOR AIRE - ATLAS COPCO GA", "modelo": "GA30", "descripcion": "Suministro aire neumatica planta", "ubicacion": "Sala Maquinas", "plcUrl": "192.168.1.54", "configs": get_configs()}
    ]

    for m in catalogo:
        res = api_call("/maquinas", method="POST", data=m, token=token)
        if res: print(f"Creada (con Sensores): {m['nombre']}")

    # 3. Datos
    machines = api_call("/maquinas", token=token)
    users = api_call("/usuarios", token=token)
    tecnicos = [u for u in users if u['rol'] in ['TECNICO', 'JEFE_MANTENIMIENTO']]
    sig = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="

    print("Generando 200 OTs...")
    now = datetime.now()
    for i in range(200):
        m = random.choice(machines)
        t = random.choice(tecnicos)
        days_ago = random.randint(0, 180)
        creation_date = now - timedelta(days=days_ago, hours=random.randint(1, 12))
        
        threshold = 80 if days_ago < 30 else (60 if days_ago < 90 else 40)
        tipo = "PREVENTIVA" if random.randint(0, 100) < threshold else "CORRECTIVA"
        
        ot_data = {
            "maquina": {"id": m['id']},
            "tecnico": {"id": t['id']},
            "descripcion": f"{'Mantenimiento' if tipo == 'PREVENTIVA' else 'Averia'} #{i}",
            "prioridad": "ALTA" if tipo == "CORRECTIVA" else "MEDIA",
            "tipo": tipo,
            "fechaCreacion": creation_date.strftime("%Y-%m-%dT%H:%M:%S")
        }
        
        ot_res = api_call("/ordenes", method="POST", data=ot_data, token=token)
        if ot_res and days_ago > 2:
            start = creation_date + timedelta(minutes=30)
            end = start + timedelta(minutes=random.randint(60, 200))
            close_data = {
                "trabajosRealizados": f"Cierre automatico historial. Maquina: {m['nombre']}",
                "firmaTecnico": sig,
                "checklists": "{}",
                "fechaInicio": start.strftime("%Y-%m-%dT%H:%M:%S"),
                "fechaFin": end.strftime("%Y-%m-%dT%H:%M:%S")
            }
            api_call(f"/ordenes/{ot_res['id']}/cerrar", method="PATCH", data=close_data, token=token)

    # 4. Inyectar Telemetria Inicial
    print("Inyectando telemetria inicial para graficas...")
    for m in machines:
        tele_data = {
            "maquina": {"id": m['id']},
            "temperatura": random.uniform(35.0, 55.0),
            "vibracion": random.uniform(1.0, 3.5),
            "presion": random.uniform(5.0, 8.0),
            "humedad": random.uniform(30.0, 50.0),
            "timestamp": now.strftime("%Y-%m-%dT%H:%M:%S")
        }
        api_call("/telemetrias", method="POST", data=tele_data, token=token)

    print("Planta poblada con exito.")

if __name__ == "__main__":
    seed()
