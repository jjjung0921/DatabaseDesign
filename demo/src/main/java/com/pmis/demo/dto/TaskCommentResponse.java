package com.pmis.demo.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class TaskCommentResponse {
    private final Long id;
    private final Long taskId;
    private final Long employeeId;
    private final LocalDateTime commentedAt;
    private final String content;
}
