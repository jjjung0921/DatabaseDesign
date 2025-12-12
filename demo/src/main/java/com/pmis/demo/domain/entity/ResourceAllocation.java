package com.pmis.demo.domain.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "resource_allocation")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
@IdClass(ResourceAllocationId.class)
public class ResourceAllocation {

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "task_id")
    private Task task;

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resource_id")
    private Resource resource;

    @Column(nullable = false)
    private Integer amountUsed;
}
