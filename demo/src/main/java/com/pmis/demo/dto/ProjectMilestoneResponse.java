package com.pmis.demo.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class ProjectMilestoneResponse {
    private final Long id;
    private final Long projectId;
    private final String name;
    private final LocalDate dueDate;
    private final Boolean isCompleted;
}
