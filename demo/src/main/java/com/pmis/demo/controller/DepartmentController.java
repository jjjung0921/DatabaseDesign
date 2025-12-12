package com.pmis.demo.controller;

import com.pmis.demo.domain.entity.Department;
import com.pmis.demo.dto.DepartmentResponse;
import com.pmis.demo.service.DepartmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/departments")
@RequiredArgsConstructor
public class DepartmentController {

    private final DepartmentService departmentService;

    @PostMapping
    public Department create(@RequestBody Department department) {
        return departmentService.create(department);
    }

    @GetMapping
    public List<DepartmentResponse> getAll() {
        return departmentService.getAll();
    }

    @GetMapping("/{id}")
    public DepartmentResponse getOne(@PathVariable Long id) {
        return departmentService.getById(id);
    }

    @PutMapping("/{id}")
    public Department update(@PathVariable Long id, @RequestBody Department department) {
        return departmentService.update(id, department);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        departmentService.delete(id);
    }
}
