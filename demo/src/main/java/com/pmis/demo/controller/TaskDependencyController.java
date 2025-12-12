package com.pmis.demo.controller;

import com.pmis.demo.domain.entity.Task;
import com.pmis.demo.domain.entity.TaskDependency;
import com.pmis.demo.domain.enums.DependencyType;
import com.pmis.demo.dto.TaskDependencyResponse;
import com.pmis.demo.repository.TaskDependencyRepository;
import com.pmis.demo.repository.TaskRepository;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tasks/{taskId}/dependencies")
@RequiredArgsConstructor
public class TaskDependencyController {

    private final TaskRepository taskRepository;
    private final TaskDependencyRepository dependencyRepository;

    @PostMapping
    public TaskDependency addDependency(@PathVariable Long taskId,
                                        @RequestBody DependencyRequest request) {
        Task predecessor = taskRepository.findById(request.getPredecessorTaskId())
                .orElseThrow(() -> new IllegalArgumentException("Predecessor task not found"));
        Task successor = taskRepository.findById(taskId)
                .orElseThrow(() -> new IllegalArgumentException("Successor task not found"));

        TaskDependency dependency = TaskDependency.builder()
                .predecessor(predecessor)
                .successor(successor)
                .type(request.getType())
                .lagDays(request.getLagDays())
                .build();
        return dependencyRepository.save(dependency);
    }

    @GetMapping
    public List<TaskDependencyResponse> getDependencies(@PathVariable Long taskId) {
        return dependencyRepository.findBySuccessorId(taskId).stream()
                .map(dep -> TaskDependencyResponse.builder()
                        .predecessorTaskId(dep.getPredecessor().getId())
                        .successorTaskId(dep.getSuccessor().getId())
                        .type(dep.getType())
                        .lagDays(dep.getLagDays())
                        .build())
                .toList();
    }

    @DeleteMapping
    public void deleteDependency(@PathVariable Long taskId,
                                 @RequestParam Long predecessorTaskId) {
        dependencyRepository.deleteById(
                new com.pmis.demo.domain.entity.TaskDependencyId(
                        predecessorTaskId, taskId
                )
        );
    }

    @Getter @Setter
    public static class DependencyRequest {
        private Long predecessorTaskId;
        private DependencyType type;
        private Integer lagDays;
    }
}
