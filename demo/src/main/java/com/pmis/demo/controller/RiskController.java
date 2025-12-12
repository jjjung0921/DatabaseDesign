package com.pmis.demo.controller;

import com.pmis.demo.domain.entity.ProjectRisk;
import com.pmis.demo.domain.enums.RiskLevel;
import com.pmis.demo.dto.ProjectRiskResponse;
import com.pmis.demo.service.RiskService;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/projects/{projectId}/risks")
@RequiredArgsConstructor
public class RiskController {

    private final RiskService riskService;

    @PostMapping
    public ProjectRisk createRisk(@PathVariable Long projectId,
                                  @RequestParam Long employeeId,
                                  @RequestBody RiskCreateRequest request) {
        return riskService.createRisk(
                projectId,
                employeeId,
                request.getOwnerId(),
                request.getTitle(),
                request.getDescription(),
                request.getLevel()
        );
    }

    @GetMapping
    public List<ProjectRiskResponse> getRisks(@PathVariable Long projectId) {
        return riskService.getRisksByProject(projectId);
    }

    @PatchMapping("/{riskId}/status")
    public ProjectRisk updateStatus(@PathVariable Long projectId,
                                    @PathVariable Long riskId,
                                    @RequestParam String status,
                                    @RequestParam Long employeeId) {
        return riskService.updateStatus(projectId, riskId, status, employeeId);
    }

    @Getter @Setter
    public static class RiskCreateRequest {
        private Long ownerId;
        private String title;
        private String description;
        private RiskLevel level;
    }
}
