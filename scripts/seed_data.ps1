# Seeder Industrial PRO para Mèltic GMAO - Masivo 6 Meses
$baseUrl = "http://localhost:8080/api"
$loginBody = @{ email = "admin@meltic.com"; password = "Meltic@2024!" } | ConvertTo-Json
$loginRes = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$token = $loginRes.token
$headers = @{ Authorization = "Bearer $token" }

# 1. CREAR CATÁLOGO DE MÁQUINAS (Si no existen)
Write-Host "🏭 Configurando catálogo de activos industriales..." -ForegroundColor Cyan
$catalogo = @(
    @{ nombre = "TORNO CNC - OKUMA VT-50"; modelo="VT-50"; descripcion="Torno de alta precision para ejes"; ubicacion="Taller A1"; plcUrl="192.168.1.50" }
    @{ nombre = "INYECTORA PLASTICO - ARBURG 470"; modelo="470C"; descripcion="Inyeccion de componentes termoplasticos"; ubicacion="Linea 2"; plcUrl="192.168.1.51" }
    @{ nombre = "BRAZO ROBOTICO - FANUC R2000"; modelo="R2000iB"; descripcion="Paletizado automatico de cajas"; ubicacion="Final Linea 3"; plcUrl="192.168.1.52" }
    @{ nombre = "PRENSA HIDRAULICA - PH-500"; modelo="PH-500-S"; descripcion="Estampacion de paneles metalicos"; ubicacion="Zona Forja"; plcUrl="192.168.1.53" }
    @{ nombre = "COMPRESOR AIRE - ATLAS COPCO GA"; modelo="GA30"; descripcion="Suministro aire neumatica planta"; ubicacion="Sala Maquinas"; plcUrl="192.168.1.54" }
)

foreach ($mBody in $catalogo) {
    try {
        $json = $mBody | ConvertTo-Json
        Invoke-RestMethod -Uri "$baseUrl/maquinas" -Method Post -Body $json -ContentType "application/json" -Headers $headers
        Write-Host "✅ Creada: $($mBody.nombre)" -ForegroundColor Gray
    } catch {
        Write-Host "ℹ️ Ya existe o error: $($mBody.nombre)" -ForegroundColor Yellow
    }
}

# Obtener máquinas y técnicos finales
$machines = Invoke-RestMethod -Uri "$baseUrl/maquinas" -Headers $headers
$users = Invoke-RestMethod -Uri "$baseUrl/usuarios" -Headers $headers
$tecnicos = $users | Where-Object { $_.rol -match "TECNICO|JEFE" }
$base64Sig = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="

# 2. GENERAR HISTORIAL MASIVO (~200 OTs)
Write-Host "🚀 Generando historial masivo de 6 meses (~200 OTs)..." -ForegroundColor Cyan
$now = [DateTime]::Now

for ($i = 0; $i -lt 200; $i++) {
    $m = $machines | Get-Random
    $t = $tecnicos | Get-Random
    
    $daysAgo = Get-Random -Minimum 0 -Maximum 180
    $hourOffset = Get-Random -Minimum 1 -Maximum 12
    $fechaCreacion = $now.AddDays(-$daysAgo).AddHours(-$hourOffset)
    
    # Simular una tendencia: los últimos 2 meses tienen más preventivo que correctivo
    $threshold = if ($daysAgo -lt 60) { 75 } else { 50 }
    $tipo = if ((Get-Random -Minimum 0 -Maximum 100) -lt $threshold) { "PREVENTIVA" } else { "CORRECTIVA" }
    
    $desc = if ($tipo -eq "PREVENTIVA") { "Inspeccion tecnica programada" } else { "Intervencion por fallo inesperado" }
    $prioridad = if ($tipo -eq "CORRECTIVA") { "ALTA" } else { "MEDIA" }
    
    $body = @{
        maquina = @{ id = $m.id }
        tecnico = @{ id = $t.id }
        descripcion = "$desc - [PRO-HISTORICAL-#$i]"
        prioridad = $prioridad
        tipo = $tipo
        fechaCreacion = $fechaCreacion.ToString("yyyy-MM-ddTHH:mm:ss")
    } | ConvertTo-Json

    $ot = Invoke-RestMethod -Uri "$baseUrl/ordenes" -Method Post -Body $body -ContentType "application/json" -Headers $headers
    $otId = $ot.id
    
    if ($daysAgo -gt 3) {
        $minutosRespuesta = Get-Random -Minimum 5 -Maximum 90
        $fechaInicio = $fechaCreacion.AddMinutes($minutosRespuesta)
        $minutosReparacion = Get-Random -Minimum 20 -Maximum 180
        $fechaFin = $fechaInicio.AddMinutes($minutosReparacion)
        
        $closeBody = @{
            trabajosRealizados = "Mantenimiento profesional realizado. MTTR: $minutosReparacion min."
            firmaTecnico = $base64Sig
            checklists = "{}"
            fechaInicio = $fechaInicio.ToString("yyyy-MM-ddTHH:mm:ss")
            fechaFin = $fechaFin.ToString("yyyy-MM-ddTHH:mm:ss")
        } | ConvertTo-Json
        
        Invoke-RestMethod -Uri "$baseUrl/ordenes/$otId/cerrar" -Method Patch -Body $closeBody -ContentType "application/json" -Headers $headers
    }
}
Write-Host "✅ Planta expandida y 200 OTs históricas generadas." -ForegroundColor Green
