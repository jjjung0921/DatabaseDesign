package com.pmis.demo.controller;

import com.pmis.demo.domain.entity.Project;
import com.pmis.demo.domain.enums.ProjectStatus;
import com.pmis.demo.service.ProjectService;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/projects")
@RequiredArgsConstructor
public class ProjectController {

    private final ProjectService projectService;

    @PostMapping
    public Project create(@RequestBody ProjectCreateRequest request) {
        Project project = Project.builder()
                .name(request.getName())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .status(request.getStatus())
                .build();
        return projectService.create(request.getManagerId(), project);
    }

    @GetMapping
    public List<Project> getAll() {
        return projectService.getAll();
    }

    @GetMapping("/{id}")
    public Project getOne(@PathVariable Long id) {
        return projectService.getById(id);
    }

    @PutMapping("/{id}")
    public Project update(@PathVariable Long id,
                          @RequestBody ProjectUpdateRequest request) {
        Project project = Project.builder()
                .name(request.getName())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .status(request.getStatus())
                .build();
        return projectService.update(id, request.getManagerId(), project);
    }

    @PatchMapping("/{id}/status")
    public Project updateStatus(@PathVariable Long id,
                                @RequestParam ProjectStatus status) {
        return projectService.updateStatus(id, status);
    }

    @PostMapping("/{id}/departments/{departmentId}")
    public void addDepartment(@PathVariable Long id,
                              @PathVariable Long departmentId) {
        projectService.addDepartment(id, departmentId);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        projectService.delete(id);
    }

    @Getter @Setter
    public static class ProjectCreateRequest {
        private String name;
        private LocalDate startDate;
        private LocalDate endDate;
        private ProjectStatus status;
        private Long managerId;
    }

    @Getter @Setter
    public static class ProjectUpdateRequest {
        private String name;
        private LocalDate startDate;
        private LocalDate endDate;
        private ProjectStatus status;
        private Long managerId;
    }
}
