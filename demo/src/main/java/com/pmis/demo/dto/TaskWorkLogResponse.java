package com.pmis.demo.dto;

import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
@Builder
public class TaskWorkLogResponse {
    private final Long id;
    private final Long taskId;
    private final Long employeeId;
    private final LocalDate workDate;
    private final BigDecimal hours;
    private final String note;
}
