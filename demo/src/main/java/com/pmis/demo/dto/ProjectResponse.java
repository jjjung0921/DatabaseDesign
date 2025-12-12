package com.pmis.demo.dto;

import com.pmis.demo.domain.enums.ProjectStatus;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class ProjectResponse {
    private final Long id;
    private final String name;
    private final LocalDate startDate;
    private final LocalDate endDate;
    private final ProjectStatus status;
    private final Long managerId;
}
