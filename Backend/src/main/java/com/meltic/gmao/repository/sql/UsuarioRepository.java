package com.meltic.gmao.repository.sql;

import com.meltic.gmao.model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface UsuarioRepository extends JpaRepository<Usuario, Long> {
    Optional<Usuario> findByEmail(String email);
    Optional<Usuario> findByRfidTagIgnoreCase(String rfidTag);
}