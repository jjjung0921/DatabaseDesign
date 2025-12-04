package com.pmis.demo.service;

import com.pmis.demo.domain.entity.Department;
import com.pmis.demo.domain.entity.Employee;
import com.pmis.demo.domain.entity.Project;
import com.pmis.demo.domain.entity.ProjectDepartment;
import com.pmis.demo.domain.enums.ProjectStatus;
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

    public List<Project> getAll() {
        return projectRepository.findAll();
    }

    public Project getById(Long id) {
        return projectRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Project not found"));
    }

    public Project update(Long id, Long managerId, Project update) {
        Project project = getById(id);

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

    public void delete(Long id) {
        projectRepository.deleteById(id);
    }

    public Project updateStatus(Long id, ProjectStatus status) {
        Project project = getById(id);
        project.setStatus(status);
        return projectRepository.save(project);
    }

    public void addDepartment(Long projectId, Long departmentId) {
        Project project = getById(projectId);
        Department dept = departmentRepository.findById(departmentId)
                .orElseThrow(() -> new IllegalArgumentException("Department not found"));
        ProjectDepartment pd = ProjectDepartment.builder()
                .project(project)
                .department(dept)
                .build();
        projectDepartmentRepository.save(pd);
    }
}
