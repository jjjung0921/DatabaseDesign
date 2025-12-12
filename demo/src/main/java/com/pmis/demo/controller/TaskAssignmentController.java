package com.pmis.demo.controller;

import com.pmis.demo.domain.entity.TaskAssignment;
import com.pmis.demo.dto.TaskAssignmentByEmployeeResponse;
import com.pmis.demo.dto.TaskAssignmentByTaskResponse;
import com.pmis.demo.service.TaskAssignmentService;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class TaskAssignmentController {

    private final TaskAssignmentService assignmentService;

    @PostMapping("/tasks/{taskId}/assignments")
    public TaskAssignment assign(@PathVariable Long taskId,
                                 @RequestBody AssignmentRequest request) {
        return assignmentService.assign(taskId, request.getEmployeeId(), request.getRoleId());
    }

    @GetMapping("/tasks/{taskId}/assignments")
    public List<TaskAssignmentByTaskResponse> getByTask(@PathVariable Long taskId) {
        return assignmentService.getByTask(taskId);
    }

    @GetMapping("/employees/{employeeId}/assignments")
    public List<TaskAssignmentByEmployeeResponse> getByEmployee(@PathVariable Long employeeId) {
        return assignmentService.getByEmployee(employeeId);
    }

    @DeleteMapping("/tasks/{taskId}/assignments")
    public void delete(@PathVariable Long taskId,
                       @RequestParam Long employeeId,
                       @RequestParam Long roleId) {
        assignmentService.remove(taskId, employeeId, roleId);
    }

    @Getter
    @Setter
    public static class AssignmentRequest {
        private Long employeeId;
        private Long roleId;
    }
}
