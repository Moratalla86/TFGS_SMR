package com.meltic.gmao.service;

import com.meltic.gmao.model.nosql.Telemetria;
import com.meltic.gmao.repository.nosql.TelemetriaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.aggregation.*;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

@Service
public class TelemetriaService {

    private static final int MAX_HISTORIC_POINTS = 2000;

    @Autowired
    private TelemetriaRepository telemetriaRepository;

    @Autowired
    private MongoTemplate mongoTemplate;

    public Telemetria guardar(Telemetria telemetria) {
        if (telemetria.getTimestamp() == null) {
            telemetria.setTimestamp(Instant.now());
        }
        return telemetriaRepository.save(telemetria);
    }

    /**
     * Carga inicial: devuelve los últimos 3600 registros ordenados ASC.
     * (preload del historian live — equivalente a abrir una pantalla SCADA)
     */
    public List<Telemetria> obtenerPorMaquina(Long maquinaId) {
        return telemetriaRepository.findTop3600ByMaquinaIdOrderByTimestampAsc(maquinaId);
    }

    /**
     * Consulta incremental SCADA: solo los registros más nuevos que `since`.
     * (report-by-exception / OPC DA subscription update)
     */
    public List<Telemetria> obtenerDesde(Long maquinaId, Instant since) {
        return telemetriaRepository.findByMaquinaIdAndTimestampAfterOrderByTimestampAsc(maquinaId, since);
    }

    /**
     * Consulta histórica multi-escala:
     * Devuelve hasta MAX_HISTORIC_POINTS puntos representativos de cualquier rango temporal.
     *
     * Algoritmo:
     *  1. Si el rango contiene ≤ MAX_HISTORIC_POINTS registros → devuelve todos (exactos).
     *  2. Si hay más → usa MongoDB $sample para muestreo estadístico uniforme + $sort ASC.
     *     Esto es equivalente al "data compression" de PI System o al "decimation" de Wonderware.
     *
     * Resultado: siempre ≤ 2000 puntos, renderizables en cualquier gráfica,
     * independientemente del rango temporal (1 día, 6 meses, 10 años).
     */
    public List<Telemetria> obtenerHistorico(Long maquinaId, Instant desde, Instant hasta) {
        if (desde == null || hasta == null) return List.of();
        MatchOperation match = Aggregation.match(
            Criteria.where("maquinaId").is(maquinaId)
                    .and("timestamp").gte(desde).lte(hasta)
        );
        SortOperation sort = Aggregation.sort(Sort.by(Sort.Direction.ASC, "timestamp"));

        // Contar primero para saber si necesitamos muestrear
        if (maquinaId == null || desde == null || hasta == null) return List.of();
        long total = mongoTemplate.count(
            org.springframework.data.mongodb.core.query.Query.query(
                Criteria.where("maquinaId").is(maquinaId)
                        .and("timestamp").gte(desde).lte(hasta)
            ),
            Telemetria.class
        );

        Aggregation agg;
        if (total <= MAX_HISTORIC_POINTS) {
            // Rango pequeño: devolver todos ordenados
            agg = Aggregation.newAggregation(match, sort);
        } else {
            // Rango grande: muestreo aleatorio representativo + ordenar por tiempo
            // $sample elige N documentos al azar del conjunto filtrado (eficiente en MongoDB 4+)
            SampleOperation sample = Aggregation.sample(MAX_HISTORIC_POINTS);
            agg = Aggregation.newAggregation(match, sample, sort);
        }

        AggregationResults<Telemetria> results = mongoTemplate.aggregate(agg, "telemetria", Telemetria.class);
        return results.getMappedResults();
    }
}
