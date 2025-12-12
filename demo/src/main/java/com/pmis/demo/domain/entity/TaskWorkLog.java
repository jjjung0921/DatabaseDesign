package com.pmis.demo.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "task_work_log")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class TaskWorkLog {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "task_id", nullable = false)
    private Task task;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_id", nullable = false)
    private Employee employee;

    @Column(nullable = false)
    private LocalDate workDate;

    @Column(nullable = false, precision = 5, scale = 2)
    private BigDecimal hours;

    @Column(length = 1000)
    private String note;
}
