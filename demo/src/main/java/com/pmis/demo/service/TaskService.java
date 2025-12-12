package com.pmis.demo.service;

import com.pmis.demo.domain.entity.Project;
import com.pmis.demo.domain.entity.Task;
import com.pmis.demo.domain.enums.TaskStatus;
import com.pmis.demo.dto.TaskResponse;
import com.pmis.demo.repository.ProjectRepository;
import com.pmis.demo.repository.TaskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TaskService {

    private final TaskRepository taskRepository;
    private final ProjectRepository projectRepository;

    public Task createTask(Long projectId, Long employeeId, Task task) {
        Project project = assertManagerAndGet(projectId, employeeId);
        task.setProject(project);
        if (task.getStatus() == null) {
            task.setStatus(TaskStatus.TODO);
        }
        return taskRepository.save(task);
    }

    public List<TaskResponse> getTasksByProject(Long projectId) {
        return taskRepository.findByProjectId(projectId).stream()
                .map(this::toResponse)
                .toList();
    }

    public Task updateStatus(Long projectId, Long taskId, TaskStatus status, Long employeeId) {
        Task task = findTaskInProject(projectId, taskId);
        assertManagerAndGet(projectId, employeeId);
        task.setStatus(status);
        return taskRepository.save(task);
    }

    public void deleteTask(Long projectId, Long taskId, Long employeeId) {
        findTaskInProject(projectId, taskId);
        assertManagerAndGet(projectId, employeeId);
        taskRepository.deleteById(taskId);
    }

    private TaskResponse toResponse(Task task) {
        Long projectId = task.getProject() != null ? task.getProject().getId() : null;
        return TaskResponse.builder()
                .id(task.getId())
                .name(task.getName())
                .projectId(projectId)
                .startDate(task.getStartDate())
                .endDate(task.getEndDate())
                .status(task.getStatus())
                .priority(task.getPriority())
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
            throw new IllegalArgumentException("Only the project manager can modify this project");
        }
        return project;
    }

    private Task findTaskInProject(Long projectId, Long taskId) {
        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new IllegalArgumentException("Task not found"));
        Long taskProjectId = task.getProject() != null ? task.getProject().getId() : null;
        if (taskProjectId == null || !taskProjectId.equals(projectId)) {
            throw new IllegalArgumentException("Task does not belong to the specified project");
        }
        return task;
    }
}
