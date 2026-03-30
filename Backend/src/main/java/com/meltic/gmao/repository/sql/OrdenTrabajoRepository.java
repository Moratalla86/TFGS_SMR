package com.meltic.gmao.repository.sql;

import com.meltic.gmao.model.OrdenTrabajo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrdenTrabajoRepository extends JpaRepository<OrdenTrabajo, Long>, JpaSpecificationExecutor<OrdenTrabajo> {
    List<OrdenTrabajo> findByTecnicoId(Long tecnicoId);
    List<OrdenTrabajo> findByMaquinaId(Long maquinaId);
}