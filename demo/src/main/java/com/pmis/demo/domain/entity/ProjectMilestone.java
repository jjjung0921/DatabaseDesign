package com.pmis.demo.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Table(name = "project_milestone")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class ProjectMilestone {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "project_id", nullable = false)
    private Project project;

    @Column(nullable = false, length = 150)
    private String name;

    @Column(nullable = false)
    private LocalDate dueDate;

    @Column(nullable = false)
    @Builder.Default
    private Boolean isCompleted = false;
}
