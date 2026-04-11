package com.meltic.gmao;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.annotation.Bean;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.data.mongodb.repository.config.EnableMongoRepositories;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.lang.NonNull;

@SpringBootApplication
@EnableScheduling
@EntityScan(basePackages = "com.meltic.gmao.model")
@EnableJpaRepositories(basePackages = "com.meltic.gmao.repository.sql")
@EnableMongoRepositories(basePackages = "com.meltic.gmao.repository.nosql")
public class MelticGmaoApplication {

    public static void main(String[] args) {
        SpringApplication.run(MelticGmaoApplication.class, args);
    }

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(@NonNull CorsRegistry registry) {
                registry.addMapping("/**").allowedOrigins("*").allowedMethods("*");
            }
        };
    }
}