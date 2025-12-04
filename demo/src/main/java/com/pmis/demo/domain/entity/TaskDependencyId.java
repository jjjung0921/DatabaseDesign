package com.pmis.demo.domain.entity;

import lombok.*;

import java.io.Serializable;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
public class TaskDependencyId implements Serializable {
    private Long predecessor;
    private Long successor;
}
