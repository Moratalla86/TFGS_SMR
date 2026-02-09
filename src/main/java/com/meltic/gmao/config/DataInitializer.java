package com.meltic.gmao.config;

import com.meltic.gmao.model.Maquina;
import com.meltic.gmao.model.Usuario;
import com.meltic.gmao.repository.sql.MaquinaRepository;
import com.meltic.gmao.repository.sql.UsuarioRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

@Configuration
public class DataInitializer {
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
    @Bean
    CommandLineRunner initDatabase(MaquinaRepository maquinaRepo, UsuarioRepository usuarioRepo) {
        return args -> {
            // Inicializar Máquina si no hay ninguna
            if (maquinaRepo.count() == 0) {
                Maquina m1 = new Maquina();
                m1.setNombre("Torno Industrial X1");
                m1.setModelo("Alpha-2000");
                m1.setUbicacion("Planta Norte");
                m1.setEstado("OK");
                maquinaRepo.save(m1);
                System.out.println("✅ Máquina de prueba creada.");
            }

            // Inicializar Usuario si no hay ninguno
            if (usuarioRepo.count() == 0) {
                Usuario u1 = new Usuario();
                u1.setNombre("Santi Técnico");
                u1.setEmail("santi@meltic.com");
                u1.setPassword(encoder.encode("1234"));
                u1.setRol("TECNICO");
                usuarioRepo.save(u1);
                System.out.println("✅ Usuario de prueba creado: santi@meltic.com");
            }
        };
    }
}