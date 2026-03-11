package com.meltic.gmao.config;

import com.meltic.gmao.model.*;
import com.meltic.gmao.repository.sql.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

@Configuration
public class DataInitializer {

    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    @Bean
    CommandLineRunner initDatabase(
            MaquinaRepository maquinaRepo,
            UsuarioRepository usuarioRepo,
            OrdenTrabajoRepository ordenTrabajoRepo) {

        return args -> {
            // Limpieza total
            ordenTrabajoRepo.deleteAll();
            usuarioRepo.deleteAll();
            maquinaRepo.deleteAll();

            // Máquina de prueba
            Maquina m1 = new Maquina();
            m1.setNombre("Torno Industrial X1");
            m1.setModelo("Alpha-2000");
            m1.setUbicacion("Planta Norte");
            m1.setEstado("OK");
            maquinaRepo.save(m1);

            // Usuario técnico de ejemplo
            Usuario u1 = new Usuario();
            u1.setNombre("Santiago");
            u1.setApellido1("Moreno");
            u1.setApellido2("Ruiz");
            u1.setUsername("smoreno@meltic.com");
            u1.setEmail("smoreno@meltic.com");
            u1.setEmailPersonal("santiago@gmail.com");
            u1.setTelefonoPersonal("600111222");
            u1.setTelefonoProfesional("912345678");
            u1.setPassword(encoder.encode("1234"));
            u1.setRol("TECNICO");
            u1.setRfidTag("A1B2C3D4");
            u1.setActivo(true);
            usuarioRepo.save(u1);

            // Usuario Admin
            Usuario adminUser = new Usuario();
            adminUser.setNombre("Admin");
            adminUser.setApellido1("Meltic");
            adminUser.setUsername("admin@meltic.com");
            adminUser.setEmail("admin@meltic.com");
            adminUser.setPassword(encoder.encode("admin"));
            adminUser.setRol("ADMIN");
            adminUser.setRfidTag("ADMIN_RFID");
            adminUser.setActivo(true);
            usuarioRepo.save(adminUser);

            // Orden de Trabajo de prueba
            OrdenTrabajo ot1 = new OrdenTrabajo();
            ot1.setDescripcion("Revisión preventiva mensual");
            ot1.setPrioridad("MEDIA");
            ot1.setEstado("PENDIENTE");
            ot1.setMaquina(m1);
            ot1.setTecnico(u1);
            ordenTrabajoRepo.save(ot1);

            System.out.println("✅ Base de datos inicializada correctamente.");
        };
    }
}