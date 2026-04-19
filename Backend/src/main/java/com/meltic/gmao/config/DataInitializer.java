package com.meltic.gmao.config;

import com.meltic.gmao.model.*;
import com.meltic.gmao.repository.sql.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.time.LocalDateTime;
import java.util.Objects;

@Configuration
public class DataInitializer {

    @Autowired
    private BCryptPasswordEncoder encoder;

    private static final String[] PREV_DESCS = {
        "Revisión preventiva mensual",
        "Lubricación y ajuste de ejes",
        "Calibración de sensores de posición",
        "Inspección de seguridad eléctrica",
        "Cambio de filtros hidráulicos",
        "Verificación del circuito neumático"
    };

    private static final String[] CORR_DESCS = {
        "Avería en sistema hidráulico",
        "Fallo de comunicación PLC",
        "Parada por sobrecalentamiento de motor",
        "Error en encoder rotativo",
        "Rotura de correa de transmisión",
        "Fuga de aceite detectada",
        "Sensor de posición defectuoso"
    };

    @Bean
    CommandLineRunner initDatabase(
            MaquinaRepository maquinaRepo,
            UsuarioRepository usuarioRepo,
            OrdenTrabajoRepository ordenTrabajoRepo) {

        return args -> {
            if (usuarioRepo.count() > 0) {
                System.out.println("✅ Base de datos ya inicializada. Omitiendo DataInitializer.");
                return;
            }

            System.out.println("🚀 Invocando DataInitializer industrial...");
            String adminPassword = System.getenv().getOrDefault("ADMIN_INITIAL_PASSWORD", "Meltic@2024!");

            // ── USUARIOS ──────────────────────────────────────────────────────────
            Usuario admin = crearUsuario("Admin",   "Meltic",  "admin@meltic.com",   adminPassword,          "ADMIN",              "40:91:F3:61");
            Usuario jefe  = crearUsuario("Carlos",  "Gómez",   "jefe@meltic.com",    "Jefe@Meltic2024!",     "JEFE_MANTENIMIENTO", "RFID_JEFE");
            Usuario tec1  = crearUsuario("Juan",    "Pérez",   "tecnico@meltic.com", "Tecnico@Meltic2024!",  "TECNICO",            "RFID_TECNICO");
            Usuario tec2  = crearUsuario("Marta",   "Ruiz",    "marta@meltic.com",   "Tecnico@Meltic2024!",  "TECNICO",            "RFID_MARTA");

            usuarioRepo.save(Objects.requireNonNull(admin));
            usuarioRepo.save(Objects.requireNonNull(jefe));
            usuarioRepo.save(Objects.requireNonNull(tec1));
            usuarioRepo.save(Objects.requireNonNull(tec2));
            System.out.println("👤 Usuarios creados: 4");

            // ── MÁQUINAS ──────────────────────────────────────────────────────────
            Maquina m0 = crearMaquina("OKUMA LB3000",     "LB3000-EX",     "Torno CNC de precisión 2 ejes",          "Línea A",       "OK");
            Maquina m1 = crearMaquina("OKUMA MX-56",      "MX-56",         "Centro de mecanizado vertical 5 ejes",   "Línea A",       "OK");
            Maquina m2 = crearMaquina("ARBURG 470C",      "470C-2500",     "Inyectora de plásticos 2500 kN",         "Línea B",       "OK");
            Maquina m3 = crearMaquina("ARBURG 520C",      "520C-3200",     "Inyectora de plásticos 3200 kN",         "Línea B",       "WARNING");
            Maquina m4 = crearMaquina("FANUC M-10iA",     "M-10iA/12",     "Robot soldadura 6 ejes 12 kg payload",   "Línea C",       "OK");
            Maquina m5 = crearMaquina("FANUC R-2000iB",   "R-2000iB/210F", "Robot paletizador 210 kg payload",       "Línea C",       "OK");
            Maquina m6 = crearMaquina("Atlas Copco GA45", "GA45+",         "Compresor de tornillo 45 kW",            "Sala Técnica",  "WARNING");
            Maquina m7 = crearMaquina("Cinta CT-01",      "CT-01-FLEX",    "Cinta transportadora flexible Línea A-B","Línea A-B",     "ERROR");

            // Configuración de métricas
            m0.addConfig(new MetricConfig("temperatura", "°C",   10.0, 20.0, 65.0, 80.0));
            m0.addConfig(new MetricConfig("vibracion",   "mm/s",  0.0,  0.5,  4.0,  7.0));
            m1.addConfig(new MetricConfig("temperatura", "°C",   10.0, 20.0, 70.0, 85.0));
            m1.addConfig(new MetricConfig("vibracion",   "mm/s",  0.0,  0.5,  4.5,  7.5));
            m2.addConfig(new MetricConfig("presion",     "bar",   5.0, 10.0,200.0,250.0));
            m2.addConfig(new MetricConfig("temp_molde",  "°C",   20.0, 40.0,200.0,240.0));
            m3.addConfig(new MetricConfig("presion",     "bar",   5.0, 10.0,200.0,250.0));
            m3.addConfig(new MetricConfig("temp_molde",  "°C",   20.0, 40.0,200.0,240.0));
            m4.addConfig(new MetricConfig("temp_motor",  "°C",   10.0, 20.0, 60.0, 75.0));
            m5.addConfig(new MetricConfig("temp_motor",  "°C",   10.0, 20.0, 60.0, 75.0));
            m6.addConfig(new MetricConfig("presion_out", "bar",   5.0,  6.0,  8.5, 10.0));
            m6.addConfig(new MetricConfig("temperatura", "°C",   10.0, 20.0, 85.0,100.0));
            m7.addConfig(new MetricConfig("velocidad",   "m/min", 0.0,  5.0, 45.0, 55.0));

            Maquina[] maquinas = {m0, m1, m2, m3, m4, m5, m6, m7};
            for (Maquina m : maquinas) {
                m.setSimulado(true);
                maquinaRepo.save(m);
            }
            System.out.println("🏭 Máquinas creadas: " + maquinas.length);

            // ── ÓRDENES DE TRABAJO ────────────────────────────────────────────────
            // Por máquina: [prevPerMonth, corrPerMonth, corrRepairHours, prevRepairHours]
            int[][] cfg = {
                {2, 2, 6, 2},  // OKUMA LB3000    — alta fiabilidad
                {2, 1, 5, 2},  // OKUMA MX-56     — buena fiabilidad
                {2, 1, 7, 3},  // ARBURG 470C     — media fiabilidad
                {1, 2, 8, 2},  // ARBURG 520C     — baja fiabilidad (WARNING)
                {1, 1, 4, 2},  // FANUC M-10iA    — alta fiabilidad
                {1, 1, 5, 2},  // FANUC R-2000iB  — alta fiabilidad
                {2, 3, 9, 3},  // Atlas Copco GA45— muy baja fiabilidad (WARNING)
                {1, 3, 8, 2},  // Cinta CT-01     — crítica (ERROR)
            };

            Usuario[] tecnicos = {tec1, tec2};
            LocalDateTime now   = LocalDateTime.now();
            int totalOts        = 0;

            for (int monthsAgo = 5; monthsAgo >= 0; monthsAgo--) {
                LocalDateTime base = now.minusMonths(monthsAgo)
                    .withDayOfMonth(1).withHour(7).withMinute(0).withSecond(0);

                for (int mi = 0; mi < maquinas.length; mi++) {
                    Maquina maq  = maquinas[mi];
                    Usuario tec  = tecnicos[mi % 2];
                    int prevN    = cfg[mi][0];
                    int corrN    = cfg[mi][1];
                    int corrH    = cfg[mi][2];
                    int prevH    = cfg[mi][3];

                    // Preventive OTs
                    for (int p = 0; p < prevN; p++) {
                        LocalDateTime fecha = base.plusDays(5 + p * 12 + mi).plusHours(mi + p * 2);
                        String estado = estadoPrev(monthsAgo, p + mi);
                        OrdenTrabajo ot = buildOT(
                            maq, tec,
                            PREV_DESCS[(mi + p + monthsAgo) % PREV_DESCS.length],
                            "PREVENTIVA", estado, fecha, "BAJA",
                            prevH, 1, estado.equals("CERRADA"));
                        ordenTrabajoRepo.save(Objects.requireNonNull(ot));
                        totalOts++;
                    }

                    // Corrective OTs
                    for (int c = 0; c < corrN; c++) {
                        LocalDateTime fecha = base.plusDays(2 + c * 8 + mi).plusHours(c * 3 + mi * 2);
                        String estado  = estadoCorr(monthsAgo, c + mi);
                        String prior   = (corrN >= 3 || mi >= 6) ? "ALTA" : "MEDIA";
                        OrdenTrabajo ot = buildOT(
                            maq, tec,
                            CORR_DESCS[(mi + c + monthsAgo) % CORR_DESCS.length],
                            "CORRECTIVA", estado, fecha, prior,
                            corrH, 2, estado.equals("CERRADA"));
                        ordenTrabajoRepo.save(Objects.requireNonNull(ot));
                        totalOts++;
                    }
                }
            }

            System.out.println("📋 Órdenes de trabajo creadas: " + totalOts);
            System.out.println("✅ Seed industrial completado. Total OTs: " + totalOts);
        };
    }

    // ── Determina estado según antigüedad ──────────────────────────────────────
    private static String estadoPrev(int monthsAgo, int variant) {
        if (monthsAgo >= 3) return "CERRADA";
        if (monthsAgo == 2) return (variant % 5 == 0) ? "EN_PROCESO" : "CERRADA";
        if (monthsAgo == 1) return (variant % 3 == 0) ? "EN_PROCESO" : "CERRADA";
        return (variant % 2 == 0) ? "PENDIENTE" : "EN_PROCESO";
    }

    private static String estadoCorr(int monthsAgo, int variant) {
        if (monthsAgo >= 3) return "CERRADA";
        if (monthsAgo == 2) return (variant % 4 == 0) ? "EN_PROCESO" : "CERRADA";
        if (monthsAgo == 1) {
            int v = variant % 3;
            return v == 0 ? "PENDIENTE" : (v == 1 ? "EN_PROCESO" : "CERRADA");
        }
        return (variant % 3 == 0) ? "EN_PROCESO" : "PENDIENTE";
    }

    // ── Constructores helper ───────────────────────────────────────────────────
    private static OrdenTrabajo buildOT(
            Maquina maquina, Usuario tecnico, String desc, String tipo, String estado,
            LocalDateTime fecha, String prioridad, int repairHours, int startDelayHours,
            boolean setClosed) {

        OrdenTrabajo ot = new OrdenTrabajo();
        ot.setMaquina(maquina);
        ot.setTecnico(tecnico);
        ot.setDescripcion(desc);
        ot.setTipo(tipo);
        ot.setEstado(estado);
        ot.setPrioridad(prioridad);
        ot.setFechaCreacion(fecha);

        if (setClosed) {
            LocalDateTime inicio = fecha.plusHours(startDelayHours);
            ot.setFechaInicio(inicio);
            ot.setFechaFin(inicio.plusHours(repairHours));
        } else if ("EN_PROCESO".equals(estado)) {
            ot.setFechaInicio(fecha.plusHours(1));
        }
        return ot;
    }

    private Maquina crearMaquina(String nombre, String modelo, String desc, String ubicacion, String estado) {
        Maquina m = new Maquina();
        m.setNombre(nombre);
        m.setModelo(modelo);
        m.setDescripcion(desc);
        m.setUbicacion(ubicacion);
        m.setEstado(estado);
        return m;
    }

    private Usuario crearUsuario(String nombre, String apellido, String email, String rawPwd, String rol, String rfid) {
        Usuario u = new Usuario();
        u.setNombre(nombre);
        u.setApellido1(apellido);
        u.setUsername(email);
        u.setEmail(email);
        u.setPassword(encoder.encode(rawPwd));
        u.setRol(rol);
        u.setRfidTag(rfid);
        u.setActivo(true);
        return u;
    }
}
