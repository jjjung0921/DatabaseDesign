package com.pmis.demo.service;

import com.pmis.demo.domain.entity.Department;
import com.pmis.demo.domain.entity.Employee;
import com.pmis.demo.domain.entity.Project;
import com.pmis.demo.domain.entity.ProjectDepartment;
import com.pmis.demo.domain.enums.ProjectStatus;
import com.pmis.demo.dto.ProjectResponse;
import com.pmis.demo.repository.DepartmentRepository;
import com.pmis.demo.repository.EmployeeRepository;
import com.pmis.demo.repository.ProjectDepartmentRepository;
import com.pmis.demo.repository.ProjectRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ProjectService {

    private final ProjectRepository projectRepository;
    private final EmployeeRepository employeeRepository;
    private final DepartmentRepository departmentRepository;
    private final ProjectDepartmentRepository projectDepartmentRepository;

    public Project create(Long managerId, Project project) {
        Employee manager = employeeRepository.findById(managerId)
                .orElseThrow(() -> new IllegalArgumentException("Manager not found"));
        project.setManager(manager);
        if (project.getStatus() == null) {
            project.setStatus(ProjectStatus.PLANNED);
        }
        return projectRepository.save(project);
    }

    public List<ProjectResponse> getAll() {
        return projectRepository.findAll().stream()
                .map(this::toResponse)
                .toList();
    }

    public ProjectResponse getById(Long id) {
        return toResponse(findProject(id));
    }

    public Project update(Long id, Long employeeId, Long managerId, Project update) {
        Project project = assertManagerAndGet(id, employeeId);

        if (managerId != null) {
            Employee manager = employeeRepository.findById(managerId)
                    .orElseThrow(() -> new IllegalArgumentException("Manager not found"));
            project.setManager(manager);
        }

        project.setName(update.getName());
        project.setStartDate(update.getStartDate());
        project.setEndDate(update.getEndDate());
        project.setStatus(update.getStatus());

        return projectRepository.save(project);
    }

    public void delete(Long id, Long employeeId) {
        assertManagerAndGet(id, employeeId);
        projectRepository.deleteById(id);
    }

    public Project updateStatus(Long id, Long employeeId, ProjectStatus status) {
        Project project = assertManagerAndGet(id, employeeId);
        project.setStatus(status);
        return projectRepository.save(project);
    }

    public void addDepartment(Long projectId, Long departmentId, Long employeeId) {
        Project project = assertManagerAndGet(projectId, employeeId);
        Department dept = departmentRepository.findById(departmentId)
                .orElseThrow(() -> new IllegalArgumentException("Department not found"));
        ProjectDepartment pd = ProjectDepartment.builder()
                .project(project)
                .department(dept)
                .build();
        projectDepartmentRepository.save(pd);
    }

    private Project findProject(Long id) {
        return projectRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Project not found"));
    }

    private Project assertManagerAndGet(Long projectId, Long employeeId) {
        if (employeeId == null) {
            throw new IllegalArgumentException("Employee ID is required");
        }
        Project project = findProject(projectId);
        Long managerId = project.getManager() != null ? project.getManager().getId() : null;
        if (managerId == null || !managerId.equals(employeeId)) {
            throw new IllegalArgumentException("Only the project manager can modify this project");
        }
        return project;
    }

    private ProjectResponse toResponse(Project project) {
        Long managerId = project.getManager() != null ? project.getManager().getId() : null;
        return ProjectResponse.builder()
                .id(project.getId())
                .name(project.getName())
                .startDate(project.getStartDate())
                .endDate(project.getEndDate())
                .status(project.getStatus())
                .managerId(managerId)
                .build();
    }
}
