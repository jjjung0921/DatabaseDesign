package com.pmis.demo.controller;

import com.pmis.demo.domain.entity.TaskDependency;
import com.pmis.demo.domain.enums.DependencyType;
import com.pmis.demo.dto.TaskDependencyResponse;
import com.pmis.demo.service.TaskDependencyService;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tasks/{taskId}/dependencies")
@RequiredArgsConstructor
public class TaskDependencyController {

    private final TaskDependencyService taskDependencyService;

    @PostMapping
    public TaskDependency addDependency(@PathVariable Long taskId,
                                        @RequestParam Long employeeId,
                                        @RequestBody DependencyRequest request) {
        return taskDependencyService.addDependency(taskId, employeeId, request.getPredecessorTaskId(),
                request.getType(), request.getLagDays());
    }

    @GetMapping
    public List<TaskDependencyResponse> getDependencies(@PathVariable Long taskId) {
        return taskDependencyService.getDependencies(taskId);
    }

    @DeleteMapping
    public void deleteDependency(@PathVariable Long taskId,
                                 @RequestParam Long predecessorTaskId,
                                 @RequestParam Long employeeId) {
        taskDependencyService.deleteDependency(taskId, predecessorTaskId, employeeId);
    }

    @Getter @Setter
    public static class DependencyRequest {
        private Long predecessorTaskId;
        private DependencyType type;
        private Integer lagDays;
    }
}
