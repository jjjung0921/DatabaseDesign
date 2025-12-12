package com.pmis.demo.service;

import com.pmis.demo.domain.entity.Department;
import com.pmis.demo.domain.entity.Employee;
import com.pmis.demo.dto.EmployeeResponse;
import com.pmis.demo.repository.DepartmentRepository;
import com.pmis.demo.repository.EmployeeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class EmployeeService {

    private final EmployeeRepository employeeRepository;
    private final DepartmentRepository departmentRepository;

    public Employee create(Long departmentId, Employee employee) {
        Department dept = departmentRepository.findById(departmentId)
                .orElseThrow(() -> new IllegalArgumentException("Department not found"));
        employee.setDepartment(dept);
        return employeeRepository.save(employee);
    }

    public List<EmployeeResponse> getAll() {
        return employeeRepository.findAll().stream()
                .map(this::toResponse)
                .toList();
    }

    public EmployeeResponse getById(Long id) {
        return toResponse(findEmployee(id));
    }

    public List<EmployeeResponse> getByDepartment(Long departmentId) {
        return employeeRepository.findByDepartmentId(departmentId).stream()
                .map(this::toResponse)
                .toList();
    }

    public Employee update(Long id, Long departmentId, Employee update) {
        Employee emp = findEmployee(id);

        if (departmentId != null) {
            Department dept = departmentRepository.findById(departmentId)
                    .orElseThrow(() -> new IllegalArgumentException("Department not found"));
            emp.setDepartment(dept);
        }
        emp.setName(update.getName());
        return employeeRepository.save(emp);
    }

    public void delete(Long id) {
        employeeRepository.deleteById(id);
    }

    private Employee findEmployee(Long id) {
        return employeeRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Employee not found"));
    }

    private EmployeeResponse toResponse(Employee employee) {
        Long departmentId = employee.getDepartment() != null ? employee.getDepartment().getId() : null;
        return EmployeeResponse.builder()
                .id(employee.getId())
                .name(employee.getName())
                .departmentId(departmentId)
                .build();
    }
}
