package com.pmis.demo.service;

import com.pmis.demo.domain.entity.Employee;
import com.pmis.demo.domain.entity.Task;
import com.pmis.demo.domain.entity.TaskWorkLog;
import com.pmis.demo.repository.EmployeeRepository;
import com.pmis.demo.repository.TaskRepository;
import com.pmis.demo.repository.TaskWorkLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class WorkLogService {

    private final TaskWorkLogRepository workLogRepository;
    private final TaskRepository taskRepository;
    private final EmployeeRepository employeeRepository;

    public TaskWorkLog logWork(Long taskId, Long employeeId, LocalDate date, BigDecimal hours, String note) {
        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new IllegalArgumentException("Task not found"));
        Employee employee = employeeRepository.findById(employeeId)
                .orElseThrow(() -> new IllegalArgumentException("Employee not found"));

        TaskWorkLog log = TaskWorkLog.builder()
                .task(task)
                .employee(employee)
                .workDate(date)
                .hours(hours)
                .note(note)
                .build();

        return workLogRepository.save(log);
    }

    public List<TaskWorkLog> getTaskLogs(Long taskId) {
        return workLogRepository.findByTaskId(taskId);
    }
}
