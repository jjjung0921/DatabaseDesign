package com.pmis.demo.service;

import com.pmis.demo.domain.entity.Project;
import com.pmis.demo.domain.entity.ProjectMilestone;
import com.pmis.demo.dto.ProjectMilestoneResponse;
import com.pmis.demo.repository.ProjectMilestoneRepository;
import com.pmis.demo.repository.ProjectRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MilestoneService {

    private final ProjectMilestoneRepository milestoneRepository;
    private final ProjectRepository projectRepository;

    public ProjectMilestone createMilestone(Long projectId, Long employeeId, String name, LocalDate dueDate) {
        Project project = assertManagerAndGet(projectId, employeeId);

        ProjectMilestone milestone = ProjectMilestone.builder()
                .project(project)
                .name(name)
                .dueDate(dueDate)
                .isCompleted(false)
                .build();

        return milestoneRepository.save(milestone);
    }

    public List<ProjectMilestoneResponse> getMilestones(Long projectId) {
        return milestoneRepository.findByProjectId(projectId).stream()
                .map(this::toResponse)
                .toList();
    }

    public ProjectMilestone completeMilestone(Long projectId, Long milestoneId, Long employeeId) {
        assertManagerAndGet(projectId, employeeId);
        ProjectMilestone m = milestoneRepository.findById(milestoneId)
                .orElseThrow(() -> new IllegalArgumentException("Milestone not found"));
        Long milestoneProjectId = m.getProject() != null ? m.getProject().getId() : null;
        if (milestoneProjectId == null || !milestoneProjectId.equals(projectId)) {
            throw new IllegalArgumentException("Milestone does not belong to the specified project");
        }
        m.setIsCompleted(true);
        return milestoneRepository.save(m);
    }

    private ProjectMilestoneResponse toResponse(ProjectMilestone milestone) {
        Long projectId = milestone.getProject() != null ? milestone.getProject().getId() : null;
        return ProjectMilestoneResponse.builder()
                .id(milestone.getId())
                .projectId(projectId)
                .name(milestone.getName())
                .dueDate(milestone.getDueDate())
                .isCompleted(milestone.getIsCompleted())
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
            throw new IllegalArgumentException("Only the project manager can modify milestones for this project");
        }
        return project;
    }
}
