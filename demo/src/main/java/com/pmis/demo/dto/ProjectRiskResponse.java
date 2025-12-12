package com.pmis.demo.dto;

import com.pmis.demo.domain.enums.RiskLevel;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class ProjectRiskResponse {
    private final Long id;
    private final Long projectId;
    private final String title;
    private final String description;
    private final RiskLevel level;
    private final String status;
    private final Long ownerId;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;
}
