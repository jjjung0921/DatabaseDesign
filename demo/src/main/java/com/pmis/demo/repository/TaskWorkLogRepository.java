package com.pmis.demo.repository;

import com.pmis.demo.domain.entity.TaskWorkLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface TaskWorkLogRepository extends JpaRepository<TaskWorkLog, Long> {
    List<TaskWorkLog> findByTaskId(Long taskId);
    List<TaskWorkLog> findByEmployeeIdAndWorkDateBetween(Long employeeId, LocalDate from, LocalDate to);
}
