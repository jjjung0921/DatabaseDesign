package com.pmis.demo.service;

import com.pmis.demo.domain.entity.Project;
import com.pmis.demo.domain.entity.Task;
import com.pmis.demo.domain.entity.TaskDependency;
import com.pmis.demo.domain.entity.TaskDependencyId;
import com.pmis.demo.domain.enums.DependencyType;
import com.pmis.demo.dto.TaskDependencyResponse;
import com.pmis.demo.repository.ProjectRepository;
import com.pmis.demo.repository.TaskDependencyRepository;
import com.pmis.demo.repository.TaskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TaskDependencyService {

    private final TaskRepository taskRepository;
    private final TaskDependencyRepository dependencyRepository;
    private final ProjectRepository projectRepository;

    public TaskDependency addDependency(Long successorTaskId, Long employeeId, Long predecessorTaskId,
                                        DependencyType type, Integer lagDays) {
        Task predecessor = taskRepository.findById(predecessorTaskId)
                .orElseThrow(() -> new IllegalArgumentException("Predecessor task not found"));
        Task successor = taskRepository.findById(successorTaskId)
                .orElseThrow(() -> new IllegalArgumentException("Successor task not found"));

        Long projectId = getSameProjectId(predecessor, successor);
        assertManager(projectId, employeeId);

        TaskDependency dependency = TaskDependency.builder()
                .predecessor(predecessor)
                .successor(successor)
                .type(type)
                .lagDays(lagDays)
                .build();
        return dependencyRepository.save(dependency);
    }

    public List<TaskDependencyResponse> getDependencies(Long successorTaskId) {
        return dependencyRepository.findBySuccessorId(successorTaskId).stream()
                .map(dep -> TaskDependencyResponse.builder()
                        .predecessorTaskId(dep.getPredecessor().getId())
                        .successorTaskId(dep.getSuccessor().getId())
                        .type(dep.getType())
                        .lagDays(dep.getLagDays())
                        .build())
                .toList();
    }

    public void deleteDependency(Long successorTaskId, Long predecessorTaskId, Long employeeId) {
        Task predecessor = taskRepository.findById(predecessorTaskId)
                .orElseThrow(() -> new IllegalArgumentException("Predecessor task not found"));
        Task successor = taskRepository.findById(successorTaskId)
                .orElseThrow(() -> new IllegalArgumentException("Successor task not found"));

        Long projectId = getSameProjectId(predecessor, successor);
        assertManager(projectId, employeeId);

        dependencyRepository.deleteById(new TaskDependencyId(predecessorTaskId, successorTaskId));
    }

    private Long getSameProjectId(Task predecessor, Task successor) {
        Long preProjectId = predecessor.getProject() != null ? predecessor.getProject().getId() : null;
        Long sucProjectId = successor.getProject() != null ? successor.getProject().getId() : null;
        if (preProjectId == null || sucProjectId == null || !preProjectId.equals(sucProjectId)) {
            throw new IllegalArgumentException("Tasks must belong to the same project");
        }
        return preProjectId;
    }

    private void assertManager(Long projectId, Long employeeId) {
        if (employeeId == null) {
            throw new IllegalArgumentException("Employee ID is required");
        }
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new IllegalArgumentException("Project not found"));
        Long managerId = project.getManager() != null ? project.getManager().getId() : null;
        if (managerId == null || !managerId.equals(employeeId)) {
            throw new IllegalArgumentException("Only the project manager can modify task dependencies");
        }
    }
}
