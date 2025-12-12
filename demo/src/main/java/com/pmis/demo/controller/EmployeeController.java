package com.pmis.demo.controller;

import com.pmis.demo.domain.entity.Employee;
import com.pmis.demo.dto.EmployeeResponse;
import com.pmis.demo.service.EmployeeService;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/employees")
@RequiredArgsConstructor
public class EmployeeController {

    private final EmployeeService employeeService;

    @PostMapping
    public Employee create(@RequestBody EmployeeCreateRequest request) {
        Employee employee = Employee.builder()
                .name(request.getName())
                .build();
        return employeeService.create(request.getDepartmentId(), employee);
    }

    @GetMapping
    public List<EmployeeResponse> getAll() {
        return employeeService.getAll();
    }

    @GetMapping("/{id}")
    public EmployeeResponse getOne(@PathVariable Long id) {
        return employeeService.getById(id);
    }

    @GetMapping("/department/{departmentId}")
    public List<EmployeeResponse> getByDepartment(@PathVariable Long departmentId) {
        return employeeService.getByDepartment(departmentId);
    }

    @PutMapping("/{id}")
    public Employee update(@PathVariable Long id,
                           @RequestBody EmployeeUpdateRequest request) {
        Employee employee = Employee.builder()
                .name(request.getName())
                .build();
        return employeeService.update(id, request.getDepartmentId(), employee);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        employeeService.delete(id);
    }

    @Getter @Setter
    public static class EmployeeCreateRequest {
        private String name;
        private Long departmentId;
    }

    @Getter @Setter
    public static class EmployeeUpdateRequest {
        private String name;
        private Long departmentId;
    }
}
