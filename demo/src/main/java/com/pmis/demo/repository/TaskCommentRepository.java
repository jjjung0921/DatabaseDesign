package com.pmis.demo.repository;

import com.pmis.demo.domain.entity.TaskComment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TaskCommentRepository extends JpaRepository<TaskComment, Long> {
    List<TaskComment> findByTaskIdOrderByCommentedAtAsc(Long taskId);
}
