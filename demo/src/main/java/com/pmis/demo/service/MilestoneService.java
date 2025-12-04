package com.pmis.demo.service;

import com.pmis.demo.domain.entity.Project;
import com.pmis.demo.domain.entity.ProjectMilestone;
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

    public ProjectMilestone createMilestone(Long projectId, String name, LocalDate dueDate) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new IllegalArgumentException("Project not found"));

        ProjectMilestone milestone = ProjectMilestone.builder()
                .project(project)
                .name(name)
                .dueDate(dueDate)
                .isCompleted(false)
                .build();

        return milestoneRepository.save(milestone);
    }

    public List<ProjectMilestone> getMilestones(Long projectId) {
        // 단순 예시: 프로젝트 기준 전체 조회
        return milestoneRepository.findByProjectId(projectId);
    }

    public ProjectMilestone completeMilestone(Long milestoneId) {
        ProjectMilestone m = milestoneRepository.findById(milestoneId)
                .orElseThrow(() -> new IllegalArgumentException("Milestone not found"));
        m.setIsCompleted(true);
        return milestoneRepository.save(m);
    }
}
