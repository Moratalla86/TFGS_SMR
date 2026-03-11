package com.meltic.gmao.repository.nosql;

import com.meltic.gmao.model.nosql.Telemetria;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TelemetriaRepository extends MongoRepository<Telemetria, String> {
    List<Telemetria> findByMaquinaIdOrderByTimestampDesc(Long maquinaId);
}
