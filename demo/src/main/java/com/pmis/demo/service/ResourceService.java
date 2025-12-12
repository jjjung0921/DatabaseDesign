package com.pmis.demo.service;

import com.pmis.demo.domain.entity.Resource;
import com.pmis.demo.domain.entity.ResourceAllocation;
import com.pmis.demo.domain.entity.Task;
import com.pmis.demo.dto.ResourceAllocationResponse;
import com.pmis.demo.dto.ResourceResponse;
import com.pmis.demo.repository.ResourceAllocationRepository;
import com.pmis.demo.repository.ResourceRepository;
import com.pmis.demo.repository.TaskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ResourceService {

    private final ResourceRepository resourceRepository;
    private final ResourceAllocationRepository allocationRepository;
    private final TaskRepository taskRepository;

    public Resource create(Resource resource) {
        return resourceRepository.save(resource);
    }

    public List<ResourceResponse> getAll() {
        return resourceRepository.findAll().stream()
                .map(this::toResponse)
                .toList();
    }

    public ResourceResponse getById(Long id) {
        return toResponse(findResource(id));
    }

    public Resource update(Long id, Resource update) {
        Resource resource = findResource(id);
        resource.setName(update.getName());
        resource.setType(update.getType());
        resource.setQuantity(update.getQuantity());
        return resourceRepository.save(resource);
    }

    public void delete(Long id) {
        resourceRepository.deleteById(id);
    }

    // 자원 할당 관련

    public ResourceAllocation allocateToTask(Long taskId, Long resourceId, Integer amountUsed) {
        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new IllegalArgumentException("Task not found"));
        Resource resource = resourceRepository.findById(resourceId)
                .orElseThrow(() -> new IllegalArgumentException("Resource not found"));

        ResourceAllocation allocation = ResourceAllocation.builder()
                .task(task)
                .resource(resource)
                .amountUsed(amountUsed)
                .build();

        return allocationRepository.save(allocation);
    }

    public List<ResourceAllocationResponse> getAllocationsByTask(Long taskId) {
        return allocationRepository.findByTaskId(taskId).stream()
                .map(this::toAllocationResponse)
                .toList();
    }

    private Resource findResource(Long id) {
        return resourceRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Resource not found"));
    }

    private ResourceResponse toResponse(Resource resource) {
        return ResourceResponse.builder()
                .id(resource.getId())
                .name(resource.getName())
                .type(resource.getType())
                .quantity(resource.getQuantity())
                .build();
    }

    private ResourceAllocationResponse toAllocationResponse(ResourceAllocation allocation) {
        return ResourceAllocationResponse.builder()
                .taskId(allocation.getTask().getId())
                .resourceId(allocation.getResource().getId())
                .resourceName(allocation.getResource().getName())
                .amountUsed(allocation.getAmountUsed())
                .build();
    }
}
