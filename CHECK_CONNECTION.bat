@echo off
title Meltic GMAO - Verificación de Conexión
color 0B
echo ======================================================
echo    Meltic GMAO - MODO PRESENTACION PROFESIONAL
echo ======================================================
echo.

:: 1. Comprobar si el Hotspot de Windows está activo (IP 192.168.137.1)
echo [1/2] Verificando IP del Hotspot (192.168.137.1)...
ipconfig | findstr "192.168.137.1" > nul
if %errorlevel% equ 0 (
    echo [OK] El Hotspot de Windows esta ACTIVO.
) else (
    color 0C
    echo [ERROR] El Hotspot NO esta activo o no tiene la IP 192.168.137.1.
    echo.
    echo SOLUCION: Ve a Configuracion ^> Red e Internet ^> Zona con cobertura inalambrica movil y activala.
    echo.
    pause
    exit /b
)

echo.

:: 2. Comprobar si el puerto 8080 está abierto (Escuchando)
echo [2/2] Verificando si el Backend (Spring Boot) esta escuchando en el puerto 8080...
powershell -Command "$check = Test-NetConnection -ComputerName 192.168.137.1 -Port 8080; if($check.TcpTestSucceeded) { echo '[OK] Puerto 8080 ABIERTO y Backend detectado.' } else { echo '[ERROR] El puerto 8080 esta CERRADO. Accion: Revisa el Firewall o que el Backend este iniciado.' }"

echo.
echo ======================================================
echo    TODO LISTO PARA EL JURADO. ¡MUCHA SUERTE!
echo ======================================================
pause
