package com.pmis.demo.domain.entity;

import lombok.*;

import java.io.Serializable;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
public class TaskAssignmentId implements Serializable {
    private Long task;
    private Long employee;
    private Long role;
}
