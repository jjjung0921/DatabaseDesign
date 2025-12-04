package com.pmis.demo.controller;

import com.pmis.demo.domain.entity.ProjectMilestone;
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
                                   @RequestBody MilestoneCreateRequest request) {
        return milestoneService.createMilestone(projectId, request.getName(), request.getDueDate());
    }

    @GetMapping
    public List<ProjectMilestone> getAll(@PathVariable Long projectId) {
        return milestoneService.getMilestones(projectId);
    }

    @PatchMapping("/{milestoneId}/complete")
    public ProjectMilestone complete(@PathVariable Long projectId,
                                     @PathVariable Long milestoneId) {
        return milestoneService.completeMilestone(milestoneId);
    }

    @Getter @Setter
    public static class MilestoneCreateRequest {
        private String name;
        private LocalDate dueDate;
    }
}
