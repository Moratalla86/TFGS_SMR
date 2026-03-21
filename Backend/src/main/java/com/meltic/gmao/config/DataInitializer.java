package com.meltic.gmao.config;

import com.meltic.gmao.model.*;
import com.meltic.gmao.repository.sql.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.util.List;

@Configuration
public class DataInitializer {

    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    @Bean
    CommandLineRunner initDatabase(
            MaquinaRepository maquinaRepo,
            UsuarioRepository usuarioRepo,
            OrdenTrabajoRepository ordenTrabajoRepo) {

        return args -> {
            System.out.println("🚀 Invocando DataInitializer...");

            // Limpieza si es necesario (con ddl-auto=create ya está vacío, pero por si acaso)
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

            // Usuario Admin
            Usuario adminUser = new Usuario();
            adminUser.setNombre("Admin");
            adminUser.setApellido1("Meltic");
            adminUser.setUsername("admin@meltic.com");
            adminUser.setEmail("admin@meltic.com");
            adminUser.setPassword(encoder.encode("admin"));
            adminUser.setRol("ADMIN");
            adminUser.setRfidTag("RFID_ADMIN"); // Cambiado para que sea más claro
            adminUser.setActivo(true);
            usuarioRepo.save(adminUser);
            System.out.println("👤 Usuario Admin creado: admin@meltic.com / admin");

            // Usuario Técnico
            Usuario tecnico = new Usuario();
            tecnico.setNombre("Juan");
            tecnico.setApellido1("Tecnico");
            tecnico.setUsername("tecnico@meltic.com");
            tecnico.setEmail("tecnico@meltic.com");
            tecnico.setPassword(encoder.encode("tecnico"));
            tecnico.setRol("TECNICO");
            tecnico.setRfidTag("RFID_TECNICO");
            tecnico.setActivo(true);
            usuarioRepo.save(tecnico);
            System.out.println("👤 Usuario Técnico creado: tecnico@meltic.com / tecnico");

            // Orden de Trabajo
            OrdenTrabajo ot1 = new OrdenTrabajo();
            ot1.setDescripcion("Revisión preventiva mensual");
            ot1.setPrioridad("MEDIA");
            ot1.setEstado("PENDIENTE");
            ot1.setMaquina(m1);
            ot1.setTecnico(tecnico);
            ordenTrabajoRepo.save(ot1);

            List<Usuario> usuarios = usuarioRepo.findAll();
            System.out.println("✅ Base de datos inicializada. Total usuarios: " + usuarios.size());
            for (Usuario u : usuarios) {
                System.out.println("   - " + u.getEmail() + " [Tag: " + u.getRfidTag() + "]");
            }
        };
    }
}