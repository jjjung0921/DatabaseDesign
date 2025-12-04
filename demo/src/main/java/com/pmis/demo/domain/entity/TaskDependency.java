package com.pmis.demo.domain.entity;

import com.pmis.demo.domain.enums.DependencyType;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "TaskDependency")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
@IdClass(TaskDependencyId.class)
public class TaskDependency {

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "predecessor_task_id")
    private Task predecessor;

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "successor_task_id")
    private Task successor;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 5)
    private DependencyType type;

    private Integer lagDays;
}
