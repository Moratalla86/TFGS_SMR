package com.meltic.gmao.service;

import com.meltic.gmao.model.Maquina;
import com.meltic.gmao.model.OrdenTrabajo;
import com.meltic.gmao.model.Usuario;
import com.meltic.gmao.repository.sql.MaquinaRepository;
import com.meltic.gmao.repository.sql.OrdenTrabajoRepository;
import com.meltic.gmao.repository.sql.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

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

    // ── Creación (Jefe) ────────────────────────────────────────────────────────
    public OrdenTrabajo crearOrden(OrdenTrabajo ordenTrabajo) {
        ordenTrabajo.setFechaCreacion(LocalDateTime.now());
        if (ordenTrabajo.getEstado() == null || ordenTrabajo.getEstado().isEmpty()) {
            ordenTrabajo.setEstado("PENDIENTE");
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
            if (payload.containsKey("trabajosRealizados")) {
                ot.setTrabajosRealizados(payload.get("trabajosRealizados"));
            }
            if (payload.containsKey("firmaTecnico")) {
                ot.setFirmaTecnico(payload.get("firmaTecnico"));
            }
            if (payload.containsKey("firmaCliente")) {
                ot.setFirmaCliente(payload.get("firmaCliente"));
            }
            return ordenTrabajoRepository.save(ot);
        });
    }

    // ── Guardar firmas ─────────────────────────────────────────────────────────
    public Optional<OrdenTrabajo> guardarFirmas(Long id, String firmaTecnico, String firmaCliente) {
        return ordenTrabajoRepository.findById(id).map(ot -> {
            if (firmaTecnico != null) ot.setFirmaTecnico(firmaTecnico);
            if (firmaCliente != null) ot.setFirmaCliente(firmaCliente);
            return ordenTrabajoRepository.save(ot);
        });
    }

    // ── Eliminar (Jefe) ────────────────────────────────────────────────────────
    public void eliminarOrden(Long id) {
        ordenTrabajoRepository.deleteById(id);
    }
}
