package com.pmis.demo.controller;

import com.pmis.demo.domain.entity.TaskComment;
import com.pmis.demo.service.CommentService;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tasks/{taskId}/comments")
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;

    @PostMapping
    public TaskComment addComment(@PathVariable Long taskId,
                                  @RequestBody CommentRequest request) {
        return commentService.addComment(taskId, request.getEmployeeId(), request.getContent());
    }

    @GetMapping
    public List<TaskComment> getComments(@PathVariable Long taskId) {
        return commentService.getComments(taskId);
    }

    @Getter @Setter
    public static class CommentRequest {
        private Long employeeId;
        private String content;
    }
}
