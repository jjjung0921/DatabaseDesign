package com.pmis.demo.service;

import com.pmis.demo.domain.entity.Employee;
import com.pmis.demo.domain.entity.Task;
import com.pmis.demo.domain.entity.TaskComment;
import com.pmis.demo.repository.EmployeeRepository;
import com.pmis.demo.repository.TaskCommentRepository;
import com.pmis.demo.repository.TaskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class CommentService {

    private final TaskCommentRepository commentRepository;
    private final TaskRepository taskRepository;
    private final EmployeeRepository employeeRepository;

    public TaskComment addComment(Long taskId, Long employeeId, String content) {
        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new IllegalArgumentException("Task not found"));
        Employee employee = employeeRepository.findById(employeeId)
                .orElseThrow(() -> new IllegalArgumentException("Employee not found"));

        TaskComment comment = TaskComment.builder()
                .task(task)
                .employee(employee)
                .commentedAt(LocalDateTime.now())
                .content(content)
                .build();
        return commentRepository.save(comment);
    }

    public List<TaskComment> getComments(Long taskId) {
        return commentRepository.findByTaskIdOrderByCommentedAtAsc(taskId);
    }
}
