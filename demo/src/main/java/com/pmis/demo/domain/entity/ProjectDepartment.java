package com.pmis.demo.domain.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "project_department")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
@IdClass(ProjectDepartmentId.class)
public class ProjectDepartment {

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "project_id")
    private Project project;

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "department_id")
    private Department department;
}
