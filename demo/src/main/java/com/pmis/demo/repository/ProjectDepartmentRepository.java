package com.pmis.demo.repository;

import com.pmis.demo.domain.entity.ProjectDepartment;
import com.pmis.demo.domain.entity.ProjectDepartmentId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ProjectDepartmentRepository
        extends JpaRepository<ProjectDepartment, ProjectDepartmentId> {

    List<ProjectDepartment> findByProjectId(Long projectId);
}
