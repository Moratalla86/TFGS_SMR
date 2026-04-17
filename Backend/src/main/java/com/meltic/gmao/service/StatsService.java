package com.meltic.gmao.service;

import com.meltic.gmao.model.Maquina;
import com.meltic.gmao.model.OrdenTrabajo;
import com.meltic.gmao.repository.sql.MaquinaRepository;
import com.meltic.gmao.repository.sql.OrdenTrabajoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class StatsService {

    @Autowired
    private OrdenTrabajoRepository otRepo;

    @Autowired
    private MaquinaRepository maquinaRepo;

    private static final String[] MESES = {
        "ENE","FEB","MAR","ABR","MAY","JUN","JUL","AGO","SEP","OCT","NOV","DIC"
    };

    public Map<String, Object> getDashboardStats() {
        List<OrdenTrabajo> todas = otRepo.findAll();
        List<Maquina> maquinas   = maquinaRepo.findAll();

        // ── Disponibilidad ─────────────────────────────────────────────────────
        long enOk = maquinas.stream().filter(m -> "OK".equals(m.getEstado())).count();
        double disponibilidad = maquinas.isEmpty() ? 100.0 : (enOk * 100.0) / maquinas.size();

        // ── Ratio preventivo / correctivo ──────────────────────────────────────
        long prev = todas.stream().filter(ot -> "PREVENTIVA".equals(ot.getTipo())).count();
        long corr = todas.stream().filter(ot -> "CORRECTIVA".equals(ot.getTipo())).count();
        double prevRatio = (prev + corr) > 0 ? (double) prev / (prev + corr) : 0.0;

        // ── OEE (A × P × Q) ───────────────────────────────────────────────────
        // Rendimiento: mejor ratio preventivo → menos degradación → mayor P
        double rendimiento = 0.72 + (prevRatio * 0.18);
        double calidad     = 0.94; // calidad de proceso simulada constante
        double oee         = (disponibilidad / 100.0) * Math.min(rendimiento, 1.0) * calidad * 100.0;

        // ── MTTR (horas medias de reparación: correctivas cerradas) ────────────
        OptionalDouble mttrOpt = todas.stream()
            .filter(ot -> "CORRECTIVA".equals(ot.getTipo())
                    && "CERRADA".equals(ot.getEstado())
                    && ot.getFechaInicio() != null
                    && ot.getFechaFin()   != null)
            .mapToDouble(ot ->
                Duration.between(ot.getFechaInicio(), ot.getFechaFin()).toMinutes() / 60.0)
            .average();
        double mttr = mttrOpt.isPresent()
            ? Math.round(mttrOpt.getAsDouble() * 10.0) / 10.0
            : 0.0;

        // ── MTBF (horas medias entre fallos: período observación / nº fallos) ──
        double observationHours = 6.0 * 30.0 * 24.0; // ventana de 6 meses
        double mtbf = corr > 0
            ? Math.round((observationHours / corr) * 10.0) / 10.0
            : observationHours;

        // ── OTs por estado ─────────────────────────────────────────────────────
        Map<String, Long> otsPorEstado = todas.stream()
            .collect(Collectors.groupingBy(
                ot -> ot.getEstado() != null ? ot.getEstado() : "DESCONOCIDO",
                Collectors.counting()));

        // ── Ranking incidencias (top 5 máquinas con más OT correctivas) ────────
        Map<String, Long> corrByMachine = todas.stream()
            .filter(ot -> "CORRECTIVA".equals(ot.getTipo()) && ot.getMaquina() != null)
            .collect(Collectors.groupingBy(
                ot -> ot.getMaquina().getNombre(), Collectors.counting()));

        List<Map<String, Object>> rankingIncidencias = corrByMachine.entrySet().stream()
            .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
            .limit(5)
            .map(e -> {
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("maquina",     e.getKey());
                item.put("incidencias", e.getValue());
                return item;
            })
            .collect(Collectors.toList());

        // ── Evolución mensual (últimos 6 meses) ────────────────────────────────
        LocalDateTime now = LocalDateTime.now();
        List<Map<String, Object>> evolucionMensual = new ArrayList<>();

        for (int i = 5; i >= 0; i--) {
            LocalDateTime mesStart = now.minusMonths(i)
                .withDayOfMonth(1).withHour(0).withMinute(0).withSecond(0);
            LocalDateTime mesEnd = mesStart.plusMonths(1);
            String mesLabel = MESES[mesStart.getMonthValue() - 1];

            long prevMes = todas.stream()
                .filter(ot -> "PREVENTIVA".equals(ot.getTipo())
                        && ot.getFechaCreacion() != null
                        && !ot.getFechaCreacion().isBefore(mesStart)
                        && ot.getFechaCreacion().isBefore(mesEnd))
                .count();

            long corrMes = todas.stream()
                .filter(ot -> "CORRECTIVA".equals(ot.getTipo())
                        && ot.getFechaCreacion() != null
                        && !ot.getFechaCreacion().isBefore(mesStart)
                        && ot.getFechaCreacion().isBefore(mesEnd))
                .count();

            Map<String, Object> mes = new LinkedHashMap<>();
            mes.put("mes",        mesLabel);
            mes.put("preventivo", prevMes);
            mes.put("correctivo", corrMes);
            evolucionMensual.add(mes);
        }

        // ── Respuesta ──────────────────────────────────────────────────────────
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("oeeGlobal",                  round1(oee));
        result.put("mtbfHoras",                  mtbf);
        result.put("mttrHoras",                  mttr);
        result.put("disponibilidadPct",           round1(disponibilidad));
        result.put("ratioPreventivoCorrectivo",   Map.of("preventivas", prev, "correctivas", corr));
        result.put("otsPorEstado",                otsPorEstado);
        result.put("rankingIncidencias",          rankingIncidencias);
        result.put("evolucionMensual",            evolucionMensual);
        return result;
    }

    private static double round1(double v) {
        return Math.round(v * 10.0) / 10.0;
    }
}
