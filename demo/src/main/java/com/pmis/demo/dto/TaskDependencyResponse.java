package com.pmis.demo.dto;

import com.pmis.demo.domain.enums.DependencyType;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TaskDependencyResponse {
    private final Long predecessorTaskId;
    private final Long successorTaskId;
    private final DependencyType type;
    private final Integer lagDays;
}
