package com.meltic.gmao.repository.nosql;

import com.meltic.gmao.model.nosql.Telemetria;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface TelemetriaRepository extends MongoRepository<Telemetria, String> {

    /** Carga inicial: últimos N registros ordenados ASC (más antiguo primero) */
    List<Telemetria> findTop3600ByMaquinaIdOrderByTimestampAsc(Long maquinaId);

    /** Consulta incremental SCADA "since=T": solo lo nuevo desde el último timestamp conocido */
    List<Telemetria> findByMaquinaIdAndTimestampAfterOrderByTimestampAsc(Long maquinaId, Instant since);
}
