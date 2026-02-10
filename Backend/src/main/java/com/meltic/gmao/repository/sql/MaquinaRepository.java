package com.meltic.gmao.repository.sql;

import com.meltic.gmao.model.Maquina;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface MaquinaRepository extends JpaRepository<Maquina, Long> {
    // Métodos Spring como save(), findAll(), deleteById(), etc.
}