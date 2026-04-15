package com.meltic.gmao.config;

import com.meltic.gmao.model.*;
import com.meltic.gmao.repository.sql.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

@Configuration
public class DataInitializer {

    @Autowired
    private BCryptPasswordEncoder encoder;

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

            System.out.println("🚀 Invocando DataInitializer por primera vez...");

            // Contraseña inicial leída de variable de entorno (con default seguro)
            String adminPassword = System.getenv().getOrDefault("ADMIN_INITIAL_PASSWORD", "Meltic@2024!");

            // Máquina de prueba
            Maquina m1 = new Maquina();
            m1.setNombre("Torno Industrial X1");
            m1.setModelo("Alpha-2000");
            m1.setUbicacion("Planta Norte");
            m1.setEstado("OK");

            m1.addConfig(new MetricConfig("temperatura", "°C", 10.0, 15.0, 45.0, 60.0));
            m1.addConfig(new MetricConfig("humedad", "%", 20.0, 30.0, 70.0, 85.0));

            maquinaRepo.save(m1);

            // Usuario Admin
            Usuario adminUser = new Usuario();
            adminUser.setNombre("Admin");
            adminUser.setApellido1("Meltic");
            adminUser.setUsername("admin@meltic.com");
            adminUser.setEmail("admin@meltic.com");
            adminUser.setPassword(encoder.encode(adminPassword));
            adminUser.setRol("ADMIN");
            adminUser.setRfidTag("40:91:F3:61");
            adminUser.setActivo(true);
            usuarioRepo.save(adminUser);
            System.out.println("👤 Usuario Admin creado: admin@meltic.com");

            // Usuario Jefe de Mantenimiento
            Usuario jefe = new Usuario();
            jefe.setNombre("Carlos");
            jefe.setApellido1("Gómez");
            jefe.setUsername("jefe@meltic.com");
            jefe.setEmail("jefe@meltic.com");
            jefe.setPassword(encoder.encode("Jefe@Meltic2024!"));
            jefe.setRol("JEFE_MANTENIMIENTO");
            jefe.setRfidTag("RFID_JEFE");
            jefe.setActivo(true);
            usuarioRepo.save(jefe);
            System.out.println("👤 Usuario Jefe creado: jefe@meltic.com");

            // Usuario Técnico
            Usuario tecnico = new Usuario();
            tecnico.setNombre("Juan");
            tecnico.setApellido1("Tecnico");
            tecnico.setUsername("tecnico@meltic.com");
            tecnico.setEmail("tecnico@meltic.com");
            tecnico.setPassword(encoder.encode("Tecnico@Meltic2024!"));
            tecnico.setRol("TECNICO");
            tecnico.setRfidTag("RFID_TECNICO");
            tecnico.setActivo(true);
            usuarioRepo.save(tecnico);
            System.out.println("👤 Usuario Técnico creado: tecnico@meltic.com");

            // Orden de Trabajo de muestra
            OrdenTrabajo ot1 = new OrdenTrabajo();
            ot1.setDescripcion("Revisión preventiva mensual");
            ot1.setPrioridad("MEDIA");
            ot1.setEstado("PENDIENTE");
            ot1.setTipo("PREVENTIVA");
            ot1.setMaquina(m1);
            ot1.setTecnico(tecnico);
            ordenTrabajoRepo.save(ot1);

            System.out.println("✅ Base de datos inicializada. Total usuarios: " + usuarioRepo.count());
        };
    }
}
