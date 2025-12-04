package com.pmis.demo.repository;

import com.pmis.demo.domain.entity.ResourceAllocation;
import com.pmis.demo.domain.entity.ResourceAllocationId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ResourceAllocationRepository
        extends JpaRepository<ResourceAllocation, ResourceAllocationId> {

    List<ResourceAllocation> findByTaskId(Long taskId);
    List<ResourceAllocation> findByResourceId(Long resourceId);
}
