package com.meltic.gmao.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final TokenAuthFilter tokenAuthFilter;

    public SecurityConfig(TokenAuthFilter tokenAuthFilter) {
        this.tokenAuthFilter = tokenAuthFilter;
    }

    @Bean
    public BCryptPasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**", "/swagger-ui.html", "/swagger-resources/**", "/webjars/**").permitAll()

                // --- PLC: Telemetría y Control ---
                .requestMatchers(org.springframework.http.HttpMethod.POST, "/api/plc/data").permitAll() // Hardware
                .requestMatchers(org.springframework.http.HttpMethod.GET, "/api/plc/last-rfid").permitAll() // Login
                .requestMatchers("/api/plc/simulate/**").hasRole("ADMIN")
                .requestMatchers("/api/plc/maquina/**").hasAnyRole("ADMIN", "JEFE_MANTENIMIENTO", "TECNICO")
                .requestMatchers("/api/plc/**").authenticated()

                // --- FCM TOKEN REGISTRATION ---
                .requestMatchers("/api/fcm/**").authenticated()

                // --- RESTRICCIONES DE ROL (RBAC) ---
                .requestMatchers(org.springframework.http.HttpMethod.GET, "/api/maquinas/**").authenticated()
                .requestMatchers(org.springframework.http.HttpMethod.GET, "/api/config/**").authenticated()
                .requestMatchers(org.springframework.http.HttpMethod.GET, "/api/usuarios/**").hasAnyRole("ADMIN", "JEFE_MANTENIMIENTO")
                .requestMatchers(org.springframework.http.HttpMethod.POST, "/api/maquinas/**", "/api/usuarios/**").hasAnyRole("ADMIN", "SUPERADMIN")
                .requestMatchers(org.springframework.http.HttpMethod.PUT, "/api/maquinas/**", "/api/usuarios/**", "/api/config/**").hasAnyRole("ADMIN", "SUPERADMIN")
                .requestMatchers(org.springframework.http.HttpMethod.DELETE, "/api/maquinas/**", "/api/usuarios/**").hasAnyRole("ADMIN", "SUPERADMIN")

                // --- ORDENES Y ALERTAS (RBAC explícito) ---
                .requestMatchers(org.springframework.http.HttpMethod.POST, "/api/alertas/forzar").hasAnyRole("ADMIN", "JEFE_MANTENIMIENTO")
                .requestMatchers(org.springframework.http.HttpMethod.DELETE, "/api/ordenes/**").hasAnyRole("ADMIN", "JEFE_MANTENIMIENTO")
                .requestMatchers(org.springframework.http.HttpMethod.PATCH, "/api/ordenes/*/asignar", "/api/ordenes/*/estado").hasAnyRole("ADMIN", "JEFE_MANTENIMIENTO")

                .anyRequest().authenticated()
            )
            .addFilterBefore(tokenAuthFilter, org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(Arrays.asList("*"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(false);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
