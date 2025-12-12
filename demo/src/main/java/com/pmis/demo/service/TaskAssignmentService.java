package com.pmis.demo.service;

import com.pmis.demo.domain.entity.Employee;
import com.pmis.demo.domain.entity.Role;
import com.pmis.demo.domain.entity.Task;
import com.pmis.demo.domain.entity.TaskAssignment;
import com.pmis.demo.domain.entity.TaskAssignmentId;
import com.pmis.demo.dto.TaskAssignmentByEmployeeResponse;
import com.pmis.demo.dto.TaskAssignmentByTaskResponse;
import com.pmis.demo.repository.EmployeeRepository;
import com.pmis.demo.repository.RoleRepository;
import com.pmis.demo.repository.TaskAssignmentRepository;
import com.pmis.demo.repository.TaskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TaskAssignmentService {

    private final TaskAssignmentRepository assignmentRepository;
    private final TaskRepository taskRepository;
    private final EmployeeRepository employeeRepository;
    private final RoleRepository roleRepository;

    public TaskAssignment assign(Long taskId, Long employeeId, Long roleId) {
        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new IllegalArgumentException("Task not found"));
        Employee employee = employeeRepository.findById(employeeId)
                .orElseThrow(() -> new IllegalArgumentException("Employee not found"));
        Role role = roleRepository.findById(roleId)
                .orElseThrow(() -> new IllegalArgumentException("Role not found"));

        TaskAssignment assignment = TaskAssignment.builder()
                .task(task)
                .employee(employee)
                .role(role)
                .build();
        return assignmentRepository.save(assignment);
    }

    public List<TaskAssignmentByTaskResponse> getByTask(Long taskId) {
        return assignmentRepository.findByTaskId(taskId).stream()
                .map(assignment -> TaskAssignmentByTaskResponse.builder()
                        .employeeId(assignment.getEmployee().getId())
                        .employeeName(assignment.getEmployee().getName())
                        .roleId(assignment.getRole().getId())
                        .build())
                .toList();
    }

    public List<TaskAssignmentByEmployeeResponse> getByEmployee(Long employeeId) {
        return assignmentRepository.findByEmployeeId(employeeId).stream()
                .map(assignment -> TaskAssignmentByEmployeeResponse.builder()
                        .taskId(assignment.getTask().getId())
                        .taskName(assignment.getTask().getName())
                        .build())
                .toList();
    }

    public void remove(Long taskId, Long employeeId, Long roleId) {
        TaskAssignmentId id = new TaskAssignmentId(taskId, employeeId, roleId);
        assignmentRepository.deleteById(id);
    }
}
