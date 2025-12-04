package com.pmis.demo.repository;

import com.pmis.demo.domain.entity.Project;
import com.pmis.demo.domain.enums.ProjectStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ProjectRepository extends JpaRepository<Project, Long> {
    List<Project> findByStatus(ProjectStatus status);
}
