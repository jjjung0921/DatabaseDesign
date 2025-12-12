package com.pmis.demo.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class RoleResponse {
    private final Long id;
    private final String name;
}
