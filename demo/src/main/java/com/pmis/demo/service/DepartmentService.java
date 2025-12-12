package com.pmis.demo.service;

import com.pmis.demo.domain.entity.Department;
import com.pmis.demo.dto.DepartmentResponse;
import com.pmis.demo.repository.DepartmentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class DepartmentService {

    private final DepartmentRepository departmentRepository;

    public Department create(Department department) {
        return departmentRepository.save(department);
    }

    public List<DepartmentResponse> getAll() {
        return departmentRepository.findAll().stream()
                .map(this::toResponse)
                .toList();
    }

    public DepartmentResponse getById(Long id) {
        return toResponse(findDepartment(id));
    }

    public Department update(Long id, Department update) {
        Department dept = findDepartment(id);
        dept.setName(update.getName());
        return departmentRepository.save(dept);
    }

    public void delete(Long id) {
        departmentRepository.deleteById(id);
    }

    private Department findDepartment(Long id) {
        return departmentRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Department not found"));
    }

    private DepartmentResponse toResponse(Department department) {
        return DepartmentResponse.builder()
                .id(department.getId())
                .name(department.getName())
                .build();
    }
}
