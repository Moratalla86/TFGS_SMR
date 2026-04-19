package com.meltic.gmao.repository.sql;

import com.meltic.gmao.model.Alerta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface AlertaRepository extends JpaRepository<Alerta, Long> {
    List<Alerta> findByActivaTrueOrderByTimestampDesc();
    List<Alerta> findByMaquinaIdAndActivaTrue(Long maquinaId);
    long countByActivaTrue();
}
