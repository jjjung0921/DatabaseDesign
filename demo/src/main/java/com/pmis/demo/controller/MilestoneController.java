package com.pmis.demo.controller;

import com.pmis.demo.domain.entity.ProjectMilestone;
import com.pmis.demo.dto.ProjectMilestoneResponse;
import com.pmis.demo.service.MilestoneService;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/projects/{projectId}/milestones")
@RequiredArgsConstructor
public class MilestoneController {

    private final MilestoneService milestoneService;

    @PostMapping
    public ProjectMilestone create(@PathVariable Long projectId,
                                   @RequestParam Long employeeId,
                                   @RequestBody MilestoneCreateRequest request) {
        return milestoneService.createMilestone(projectId, employeeId, request.getName(), request.getDueDate());
    }

    @GetMapping
    public List<ProjectMilestoneResponse> getAll(@PathVariable Long projectId) {
        return milestoneService.getMilestones(projectId);
    }

    @PatchMapping("/{milestoneId}/complete")
    public ProjectMilestone complete(@PathVariable Long projectId,
                                     @PathVariable Long milestoneId,
                                     @RequestParam Long employeeId) {
        return milestoneService.completeMilestone(projectId, milestoneId, employeeId);
    }

    @Getter @Setter
    public static class MilestoneCreateRequest {
        private String name;
        private LocalDate dueDate;
    }
}
