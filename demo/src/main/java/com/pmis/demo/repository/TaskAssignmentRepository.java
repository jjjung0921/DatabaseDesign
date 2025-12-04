package com.pmis.demo.repository;

import com.pmis.demo.domain.entity.TaskAssignment;
import com.pmis.demo.domain.entity.TaskAssignmentId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TaskAssignmentRepository
        extends JpaRepository<TaskAssignment, TaskAssignmentId> {

    List<TaskAssignment> findByTaskId(Long taskId);
    List<TaskAssignment> findByEmployeeId(Long employeeId);
}
