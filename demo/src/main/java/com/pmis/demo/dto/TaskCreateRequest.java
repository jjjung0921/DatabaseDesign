package com.pmis.demo.dto;

import com.pmis.demo.domain.enums.PriorityLevel;
import com.pmis.demo.domain.enums.TaskStatus;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Getter @Setter
public class TaskCreateRequest {
    private String name;
    private LocalDate startDate;
    private LocalDate endDate;
    private TaskStatus status;
    private PriorityLevel priority;
}
