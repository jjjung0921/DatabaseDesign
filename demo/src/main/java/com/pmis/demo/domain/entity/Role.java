package com.pmis.demo.domain.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "Role")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Role {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false, length = 100)
    private String name;
}
