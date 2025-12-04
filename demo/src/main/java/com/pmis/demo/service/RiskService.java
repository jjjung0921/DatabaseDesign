package com.pmis.demo.service;

import com.pmis.demo.domain.entity.Employee;
import com.pmis.demo.domain.entity.Project;
import com.pmis.demo.domain.entity.ProjectRisk;
import com.pmis.demo.domain.enums.RiskLevel;
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

    public ProjectRisk createRisk(Long projectId, Long ownerId,
                                  String title, String description, RiskLevel level) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new IllegalArgumentException("Project not found"));

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

    public List<ProjectRisk> getRisksByProject(Long projectId) {
        return riskRepository.findByProjectId(projectId);
    }

    public ProjectRisk updateStatus(Long riskId, String status) {
        ProjectRisk risk = riskRepository.findById(riskId)
                .orElseThrow(() -> new IllegalArgumentException("Risk not found"));
        risk.setStatus(status);
        risk.setUpdatedAt(LocalDateTime.now());
        return riskRepository.save(risk);
    }
}
