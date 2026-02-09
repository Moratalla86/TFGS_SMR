package com.meltic.gmao.repository.sql;

import com.meltic.gmao.model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface UsuarioRepository extends JpaRepository<Usuario, Long> {
    // futuro Login
    Optional<Usuario> findByEmail(String email);
}