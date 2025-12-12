package com.pmis.demo.dto;

import com.pmis.demo.domain.enums.PriorityLevel;
import com.pmis.demo.domain.enums.TaskStatus;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class TaskResponseForEmployee {
    private final Long id;
    private final String name;
    private final Long projectId;
}
