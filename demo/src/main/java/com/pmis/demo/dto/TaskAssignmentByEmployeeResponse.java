package com.pmis.demo.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TaskAssignmentByEmployeeResponse {
    private final Long taskId;
    private final String taskName;
}
