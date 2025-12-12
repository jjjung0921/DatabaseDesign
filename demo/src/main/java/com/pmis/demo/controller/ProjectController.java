package com.pmis.demo.controller;

import com.pmis.demo.domain.entity.Project;
import com.pmis.demo.domain.enums.ProjectStatus;
import com.pmis.demo.dto.ProjectResponse;
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
    public List<ProjectResponse> getAll() {
        return projectService.getAll();
    }

    @GetMapping("/{id}")
    public ProjectResponse getOne(@PathVariable Long id) {
        return projectService.getById(id);
    }

    @PutMapping("/{id}")
    public Project update(@PathVariable Long id,
                          @RequestParam Long employeeId,
                          @RequestBody ProjectUpdateRequest request) {
        Project project = Project.builder()
                .name(request.getName())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .status(request.getStatus())
                .build();
        return projectService.update(id, employeeId, request.getManagerId(), project);
    }

    @PatchMapping("/{id}/status")
    public Project updateStatus(@PathVariable Long id,
                                @RequestParam ProjectStatus status,
                                @RequestParam Long employeeId) {
        return projectService.updateStatus(id, employeeId, status);
    }

    @PostMapping("/{id}/departments/{departmentId}")
    public void addDepartment(@PathVariable Long id,
                              @PathVariable Long departmentId,
                              @RequestParam Long employeeId) {
        projectService.addDepartment(id, departmentId, employeeId);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id,
                       @RequestParam Long employeeId) {
        projectService.delete(id, employeeId);
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
