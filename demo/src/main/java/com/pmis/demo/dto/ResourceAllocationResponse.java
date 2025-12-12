package com.pmis.demo.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ResourceAllocationResponse {
    private final Long taskId;
    private final Long resourceId;
    private final String resourceName;
    private final Integer amountUsed;
}
