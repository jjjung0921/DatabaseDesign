package com.pmis.demo.dto;

import com.pmis.demo.domain.enums.ResourceType;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ResourceResponse {
    private final Long id;
    private final String name;
    private final ResourceType type;
    private final Integer quantity;
}
