package com.pmis.demo.controller;

import com.pmis.demo.domain.entity.Resource;
import com.pmis.demo.domain.entity.ResourceAllocation;
import com.pmis.demo.domain.enums.ResourceType;
import com.pmis.demo.dto.ResourceAllocationResponse;
import com.pmis.demo.dto.ResourceResponse;
import com.pmis.demo.service.ResourceService;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/resources")
@RequiredArgsConstructor
public class ResourceController {

    private final ResourceService resourceService;

    @PostMapping
    public Resource create(@RequestBody ResourceRequest request) {
        Resource resource = Resource.builder()
                .name(request.getName())
                .type(request.getType())
                .quantity(request.getQuantity())
                .build();
        return resourceService.create(resource);
    }

    @GetMapping
    public List<ResourceResponse> getAll() {
        return resourceService.getAll();
    }

    @GetMapping("/{id}")
    public ResourceResponse getOne(@PathVariable Long id) {
        return resourceService.getById(id);
    }

    @PutMapping("/{id}")
    public Resource update(@PathVariable Long id,
                           @RequestBody ResourceRequest request) {
        Resource resource = Resource.builder()
                .name(request.getName())
                .type(request.getType())
                .quantity(request.getQuantity())
                .build();
        return resourceService.update(id, resource);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        resourceService.delete(id);
    }

    // 자원 할당

    @PostMapping("/{resourceId}/allocate")
    public ResourceAllocation allocate(@PathVariable Long resourceId,
                                       @RequestBody AllocationRequest request) {
        return resourceService.allocateToTask(
                request.getTaskId(), resourceId, request.getAmountUsed()
        );
    }

    @GetMapping("/tasks/{taskId}/allocations")
    public List<ResourceAllocationResponse> getAllocationsByTask(@PathVariable Long taskId) {
        return resourceService.getAllocationsByTask(taskId);
    }

    @Getter @Setter
    public static class ResourceRequest {
        private String name;
        private ResourceType type;
        private Integer quantity;
    }

    @Getter @Setter
    public static class AllocationRequest {
        private Long taskId;
        private Integer amountUsed;
    }
}
