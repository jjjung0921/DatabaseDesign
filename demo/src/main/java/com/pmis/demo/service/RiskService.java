package com.pmis.demo.service;

import com.pmis.demo.domain.entity.Employee;
import com.pmis.demo.domain.entity.Project;
import com.pmis.demo.domain.entity.ProjectRisk;
import com.pmis.demo.domain.enums.RiskLevel;
import com.pmis.demo.dto.ProjectRiskResponse;
import com.pmis.demo.repository.EmployeeRepository;
import com.pmis.demo.repository.ProjectRepository;
import com.pmis.demo.repository.ProjectRiskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RiskService {

    private final ProjectRiskRepository riskRepository;
    private final ProjectRepository projectRepository;
    private final EmployeeRepository employeeRepository;

    public ProjectRisk createRisk(Long projectId, Long employeeId, Long ownerId,
                                  String title, String description, RiskLevel level) {
        Project project = assertManagerAndGet(projectId, employeeId);

        Employee owner = null;
        if (ownerId != null) {
            owner = employeeRepository.findById(ownerId)
                    .orElseThrow(() -> new IllegalArgumentException("Owner not found"));
        }

        ProjectRisk risk = ProjectRisk.builder()
                .project(project)
                .owner(owner)
                .title(title)
                .description(description)
                .level(level)
                .status("OPEN")
                .createdAt(LocalDateTime.now())
                .build();

        return riskRepository.save(risk);
    }

    public List<ProjectRiskResponse> getRisksByProject(Long projectId) {
        return riskRepository.findByProjectId(projectId).stream()
                .map(this::toResponse)
                .toList();
    }

    public ProjectRisk updateStatus(Long projectId, Long riskId, String status, Long employeeId) {
        assertManagerAndGet(projectId, employeeId);
        ProjectRisk risk = riskRepository.findById(riskId)
                .orElseThrow(() -> new IllegalArgumentException("Risk not found"));
        Long riskProjectId = risk.getProject() != null ? risk.getProject().getId() : null;
        if (riskProjectId == null || !riskProjectId.equals(projectId)) {
            throw new IllegalArgumentException("Risk does not belong to the specified project");
        }
        risk.setStatus(status);
        risk.setUpdatedAt(LocalDateTime.now());
        return riskRepository.save(risk);
    }

    private ProjectRiskResponse toResponse(ProjectRisk risk) {
        Long projectId = risk.getProject() != null ? risk.getProject().getId() : null;
        Long ownerId = risk.getOwner() != null ? risk.getOwner().getId() : null;
        return ProjectRiskResponse.builder()
                .id(risk.getId())
                .projectId(projectId)
                .title(risk.getTitle())
                .description(risk.getDescription())
                .level(risk.getLevel())
                .status(risk.getStatus())
                .ownerId(ownerId)
                .createdAt(risk.getCreatedAt())
                .updatedAt(risk.getUpdatedAt())
                .build();
    }

    private Project assertManagerAndGet(Long projectId, Long employeeId) {
        if (employeeId == null) {
            throw new IllegalArgumentException("Employee ID is required");
        }
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new IllegalArgumentException("Project not found"));
        Long managerId = project.getManager() != null ? project.getManager().getId() : null;
        if (managerId == null || !managerId.equals(employeeId)) {
            throw new IllegalArgumentException("Only the project manager can modify risks for this project");
        }
        return project;
    }
}
