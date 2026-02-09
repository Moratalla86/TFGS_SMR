package com.meltic.gmao.config;

import com.meltic.gmao.model.Maquina;
import com.meltic.gmao.repository.sql.MaquinaRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class DataInitializer {

    @Bean
    CommandLineRunner initDatabase(MaquinaRepository repository) {
        return args -> { // Solo 'args', sin 'String[]' delante
            if (repository.count() == 0) {
                Maquina m1 = new Maquina();
                m1.setNombre("Torno Industrial X1");
                m1.setModelo("Alpha-2000");
                m1.setUbicacion("Planta Norte");
                m1.setEstado("OK");
                repository.save(m1);
            }
        };
    }
}