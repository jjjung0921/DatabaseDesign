package com.pmis.demo.domain.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "role")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Role {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false, length = 100)
    private String name;

    @Column(name = "can_read", nullable = false)
    private Boolean canRead = true;

    @Column(name = "can_write", nullable = false)
    private Boolean canWrite = false;

    @Column(name = "can_delete", nullable = false)
    private Boolean canDelete = false;
}
