package com.meltic.gmao.service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.meltic.gmao.model.Maquina;
import com.meltic.gmao.model.OrdenTrabajo;
import com.meltic.gmao.model.Usuario;
import com.meltic.gmao.repository.sql.MaquinaRepository;
import com.meltic.gmao.repository.sql.OrdenTrabajoRepository;
import com.meltic.gmao.repository.sql.UsuarioRepository;

@Service
public class MantenimientoService {

    @Autowired
    private OrdenTrabajoRepository ordenTrabajoRepository;

    @Autowired
    private MaquinaRepository maquinaRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    // ── Consultas ──────────────────────────────────────────────────────────────
    public List<OrdenTrabajo> obtenerTodas() {
        return ordenTrabajoRepository.findAll();
    }

    public Optional<OrdenTrabajo> obtenerPorId(Long id) {
        return ordenTrabajoRepository.findById(id);
    }

    public List<OrdenTrabajo> obtenerPorTecnico(Long tecnicoId) {
        return ordenTrabajoRepository.findByTecnicoId(tecnicoId);
    }

    public List<OrdenTrabajo> obtenerPorMaquina(Long maquinaId) {
        return ordenTrabajoRepository.findByMaquinaId(maquinaId);
    }

    public List<OrdenTrabajo> buscarConFiltros(Long tecnicoId, Long maquinaId, String estado, String prioridad,
            LocalDateTime fechaDesde, LocalDateTime fechaHasta) {

        return ordenTrabajoRepository.findAll((root, query, cb) -> {
            List<jakarta.persistence.criteria.Predicate> predicates = new ArrayList<>();

            if (tecnicoId != null) {
                predicates.add(cb.equal(root.get("tecnico").get("id"), tecnicoId));
            }
            if (maquinaId != null) {
                predicates.add(cb.equal(root.get("maquina").get("id"), maquinaId));
            }
            if (estado != null && !estado.isEmpty()) {
                predicates.add(cb.equal(root.get("estado"), estado));
            }
            if (prioridad != null && !prioridad.isEmpty()) {
                predicates.add(cb.equal(root.get("prioridad"), prioridad));
            }
            if (fechaDesde != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("fechaCreacion"), fechaDesde));
            }
            if (fechaHasta != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("fechaCreacion"), fechaHasta));
            }

            return cb.and(predicates.toArray(new jakarta.persistence.criteria.Predicate[0]));
        });
    }

    // ── Creación (Jefe) ────────────────────────────────────────────────────────
    public OrdenTrabajo crearOrden(OrdenTrabajo ordenTrabajo) {
        ordenTrabajo.setFechaCreacion(LocalDateTime.now());
        if (ordenTrabajo.getEstado() == null || ordenTrabajo.getEstado().isEmpty()) {
            if (ordenTrabajo.getTecnico() == null) {
                ordenTrabajo.setEstado("SOLICITADA");
            } else {
                ordenTrabajo.setEstado("PENDIENTE");
            }
        }
        return ordenTrabajoRepository.save(ordenTrabajo);
    }

    // ── Asignación (Jefe) ──────────────────────────────────────────────────────
    public Optional<OrdenTrabajo> asignarTecnicoYMaquina(Long id, Long tecnicoId, Long maquinaId) {
        return ordenTrabajoRepository.findById(id).map(ot -> {
            if (tecnicoId != null) {
                Optional<Usuario> tecnico = usuarioRepository.findById(tecnicoId);
                tecnico.ifPresent(ot::setTecnico);
            }
            if (maquinaId != null) {
                Optional<Maquina> maquina = maquinaRepository.findById(maquinaId);
                maquina.ifPresent(ot::setMaquina);
            }
            return ordenTrabajoRepository.save(ot);
        });
    }

    // ── Cambio de estado genérico (Jefe) ──────────────────────────────────────
    public Optional<OrdenTrabajo> actualizarEstado(Long id, String nuevoEstado) {
        return ordenTrabajoRepository.findById(id).map(ot -> {
            ot.setEstado(nuevoEstado);
            return ordenTrabajoRepository.save(ot);
        });
    }

    // ── Iniciar OT (Técnico) → EN_PROCESO + fechaInicio ───────────────────────
    public Optional<OrdenTrabajo> iniciarOT(Long id) {
        return ordenTrabajoRepository.findById(id).map(ot -> {
            ot.setEstado("EN_PROCESO");
            if (ot.getFechaInicio() == null) {
                ot.setFechaInicio(LocalDateTime.now());
            }
            return ordenTrabajoRepository.save(ot);
        });
    }

    // ── Actualizar acciones/trabajos realizados (Técnico) ─────────────────────
    public Optional<OrdenTrabajo> actualizarTrabajosRealizados(Long id, String trabajos) {
        return ordenTrabajoRepository.findById(id).map(ot -> {
            ot.setTrabajosRealizados(trabajos);
            return ordenTrabajoRepository.save(ot);
        });
    }

    // ── Cerrar OT (Técnico) → CERRADA + fechaFin + firmas ─────────────────────
    public Optional<OrdenTrabajo> cerrarOT(Long id, Map<String, String> payload) {
        return ordenTrabajoRepository.findById(id).map(ot -> {
            ot.setEstado("CERRADA");
            ot.setFechaFin(LocalDateTime.now());

            Optional.ofNullable(payload.get("trabajosRealizados")).ifPresent(ot::setTrabajosRealizados);
            Optional.ofNullable(payload.get("firmaTecnico")).ifPresent(ot::setFirmaTecnico);
            Optional.ofNullable(payload.get("firmaCliente")).ifPresent(ot::setFirmaCliente);

            if (payload.containsKey("checklists")) {
                ot.setChecklists(payload.get("checklists"));
            }
            if (payload.containsKey("fotoBase64")) {
                ot.setFotoBase64(payload.get("fotoBase64"));
            }
            if (payload.containsKey("reportePdfBase64")) {
                ot.setReportePdfBase64(payload.get("reportePdfBase64"));
            }
            return ordenTrabajoRepository.save(ot);
        });
    }

    // ── Guardar firmas ─────────────────────────────────────────────────────────
    public Optional<OrdenTrabajo> guardarFirmas(Long id, String firmaTecnico, String firmaCliente) {
        return ordenTrabajoRepository.findById(id).map(ot -> {
            if (firmaTecnico != null)
                ot.setFirmaTecnico(firmaTecnico);
            if (firmaCliente != null)
                ot.setFirmaCliente(firmaCliente);
            return ordenTrabajoRepository.save(ot);
        });
    }

    // ── Generación de PDF "Al Vuelo" ──────────────────────────────────────────
    public byte[] obtenerReportePdf(Long id) {
        return ordenTrabajoRepository.findById(id).map(ot -> {
            if (ot.getReportePdfBase64() == null || ot.getReportePdfBase64().isEmpty()) {
                // En una implementación real, aquí usaríamos iText o Thymeleaf-to-PDF
                // para generar el documento usando los datos de la OT (firmas, fotos,
                // checklists).
                // Por ahora, simulamos la generación persistiendo un placeholder si no existe.
                String dummyContent = "REPORTE FORMAL MÈLTIC GMAO 4.0\nOT ID: " + ot.getId() +
                        "\nEstado: " + ot.getEstado() + "\nFecha: " + LocalDateTime.now();
                String base64 = java.util.Base64.getEncoder().encodeToString(dummyContent.getBytes());
                ot.setReportePdfBase64(base64);
                ordenTrabajoRepository.save(ot);
            }
            return java.util.Base64.getDecoder().decode(ot.getReportePdfBase64());
        }).orElseThrow(() -> new RuntimeException("Orden no encontrada"));
    }

    // ── Eliminar (Jefe) ────────────────────────────────────────────────────────
    public void eliminarOrden(Long id) {
        ordenTrabajoRepository.deleteById(id);
    }
}
