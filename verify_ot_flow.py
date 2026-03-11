import http.client
import json

BASE_HOST = "localhost"
BASE_PORT = 8080

def request(method, path, body=None):
    conn = http.client.HTTPConnection(BASE_HOST, BASE_PORT)
    headers = {"Content-Type": "application/json"}
    conn.request(method, path, body=json.dumps(body) if body else None, headers=headers)
    res = conn.getresponse()
    data = res.read().decode()
    conn.close()
    return res.status, data

def test_flow():
    # 1. Login
    print("Logging in...")
    status, data = request("POST", "/api/auth/login", {"email": "admin@meltic.com", "password": "admin"})
    if status != 200:
        print(f"Login failed: {status} {data}")
        return
    
    admin_data = json.loads(data)
    print(f"Logged in as {admin_data['nombre']} (Rol: {admin_data['rol']})")

    # 2. Get machines and Santiago
    status, u_data = request("GET", "/api/usuarios")
    usuarios = json.loads(u_data)
    santiago = next((u for u in usuarios if u['email'] == 'santiago.moreno@meltic.com'), None)
    if not santiago:
        print("Santiago not found, using admin as technician")
        santiago = admin_data

    status, m_data = request("GET", "/api/maquinas")
    maquinas = json.loads(m_data)
    maquina = maquinas[0] if maquinas else None
    
    # 3. Create OT
    print("Creating OT...")
    ot_payload = {
        "descripcion": "Revisión preventiva de prueba STD LIB",
        "prioridad": "ALTA",
        "tecnico": {"id": santiago['id']},
        "maquina": {"id": maquina['id']} if maquina else None
    }
    status, ot_res_data = request("POST", "/api/ordenes", ot_payload)
    if status not in [200, 201]:
        print(f"Failed to create OT: {status} {ot_res_data}")
        return
    
    ot = json.loads(ot_res_data)
    ot_id = ot['id']
    print(f"Created OT #{ot_id}")

    # 4. Iniciar OT
    print(f"Starting OT #{ot_id}...")
    status, _ = request("PATCH", f"/api/ordenes/{ot_id}/iniciar")
    if status == 200:
        print("OT started successfully")
    else:
        print(f"Failed to start OT: {status}")

    # 5. Add actions
    print("Updating actions...")
    status, _ = request("PATCH", f"/api/ordenes/{ot_id}/acciones", {"trabajosRealizados": "Std lib test actions."})
    if status == 200:
        print("Actions updated")

    # 6. Cerrar OT
    print(f"Closing OT #{ot_id}...")
    close_payload = {
        "trabajosRealizados": "Finalized via std lib script.",
        "firmaTecnico": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==",
        "firmaCliente": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
    }
    status, final_data = request("PATCH", f"/api/ordenes/{ot_id}/cerrar", close_payload)
    if status == 200:
        print("OT CLOSED SUCCESSFULLY")
        final_ot = json.loads(final_data)
        print(f"Estado final: {final_ot['estado']}, Inicio: {final_ot.get('fechaInicio')}, Fin: {final_ot.get('fechaFin')}")
    else:
        print(f"Failed to close OT: {status} {final_data}")

if __name__ == "__main__":
    test_flow()
