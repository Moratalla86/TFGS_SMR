package com.meltic.gmao;

import com.meltic.gmao.model.Usuario;
import com.meltic.gmao.repository.sql.UsuarioRepository;
import com.meltic.gmao.service.TokenService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class SecurityIntegrationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TokenService tokenService;

    @Autowired
    private UsuarioRepository usuarioRepo;

    @Test
    void whenNoToken_thenUnauthorized() throws Exception {
        mockMvc.perform(get("/api/maquinas"))
                .andExpect(status().isForbidden()); // Spring Security por defecto devuelve 403 si falla el filtro
    }

    @Test
    void whenValidToken_thenOk() throws Exception {
        // Buscamos el admin creado por el DataInitializer
        Usuario admin = usuarioRepo.findByEmail("admin@meltic.com").orElse(null);
        if (admin != null) {
            String token = tokenService.generateToken(admin);
            mockMvc.perform(get("/api/maquinas")
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk());
        }
    }
}
