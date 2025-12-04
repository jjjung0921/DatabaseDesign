package com.pmis.demo.repository;

import com.pmis.demo.domain.entity.TaskDependency;
import com.pmis.demo.domain.entity.TaskDependencyId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TaskDependencyRepository
        extends JpaRepository<TaskDependency, TaskDependencyId> {

    List<TaskDependency> findByPredecessorId(Long predecessorId);
    List<TaskDependency> findBySuccessorId(Long successorId);
}
