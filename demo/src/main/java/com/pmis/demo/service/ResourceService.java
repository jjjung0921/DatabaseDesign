package com.pmis.demo.service;

import com.pmis.demo.domain.entity.Resource;
import com.pmis.demo.domain.entity.ResourceAllocation;
import com.pmis.demo.domain.entity.Task;
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

    public List<Resource> getAll() {
        return resourceRepository.findAll();
    }

    public Resource getById(Long id) {
        return resourceRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Resource not found"));
    }

    public Resource update(Long id, Resource update) {
        Resource resource = getById(id);
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

    public List<ResourceAllocation> getAllocationsByTask(Long taskId) {
        return allocationRepository.findByTaskId(taskId);
    }
}
