package com.pmis.demo.domain.entity;

import com.pmis.demo.domain.enums.ResourceType;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "Resource")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Resource {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 150)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ResourceType type;

    @Column(nullable = false)
    private Integer quantity;
}
