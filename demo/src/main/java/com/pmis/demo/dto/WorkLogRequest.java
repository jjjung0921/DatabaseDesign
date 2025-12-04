package com.pmis.demo.dto;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter @Setter
public class WorkLogRequest {
    private Long employeeId;
    private LocalDate workDate;
    private BigDecimal hours;
    private String note;
}
