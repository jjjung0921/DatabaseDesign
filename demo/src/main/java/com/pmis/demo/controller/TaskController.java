package com.pmis.demo.controller;

import com.pmis.demo.domain.entity.Task;
import com.pmis.demo.domain.enums.TaskStatus;
import com.pmis.demo.dto.TaskCreateRequest;
import com.pmis.demo.dto.TaskResponse;
import com.pmis.demo.service.TaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/projects/{projectId}/tasks")
@RequiredArgsConstructor
public class TaskController {

    private final TaskService taskService;

    @PostMapping
    public Task createTask(@PathVariable Long projectId,
                           @RequestParam Long employeeId,
                           @RequestBody TaskCreateRequest request) {
        Task task = Task.builder()
                .name(request.getName())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .status(request.getStatus())
                .priority(request.getPriority())
                .build();
        return taskService.createTask(projectId, employeeId, task);
    }

    @GetMapping
    public List<TaskResponse> getTasks(@PathVariable Long projectId) {
        return taskService.getTasksByProject(projectId);
    }

    @PatchMapping("/{taskId}/status")
    public Task updateStatus(@PathVariable Long projectId,
                             @PathVariable Long taskId,
                             @RequestParam TaskStatus status,
                             @RequestParam Long employeeId) {
        return taskService.updateStatus(projectId, taskId, status, employeeId);
    }

    @DeleteMapping("/{taskId}")
    public void deleteTask(@PathVariable Long projectId,
                           @PathVariable Long taskId,
                           @RequestParam Long employeeId) {
        taskService.deleteTask(projectId, taskId, employeeId);
    }
}
