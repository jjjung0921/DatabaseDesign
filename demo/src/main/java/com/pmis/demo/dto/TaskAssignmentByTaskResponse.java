package com.pmis.demo.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TaskAssignmentByTaskResponse {
    private final Long employeeId;
    private final String employeeName;
    private final Long roleId;
}
