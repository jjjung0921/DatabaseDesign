package com.pmis.demo.repository;

import com.pmis.demo.domain.entity.ProjectRisk;
import com.pmis.demo.domain.enums.RiskLevel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ProjectRiskRepository extends JpaRepository<ProjectRisk, Long> {
    List<ProjectRisk> findByProjectId(Long projectId);
    List<ProjectRisk> findByLevel(RiskLevel level);
}
