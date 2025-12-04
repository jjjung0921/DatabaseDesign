package com.pmis.demo.domain.entity;

import lombok.*;

import java.io.Serializable;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
public class ProjectDepartmentId implements Serializable {
    private Long project;
    private Long department;
}
