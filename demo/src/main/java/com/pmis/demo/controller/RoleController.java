package com.pmis.demo.controller;

import com.pmis.demo.domain.entity.Role;
import com.pmis.demo.service.RoleService;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/roles")
@RequiredArgsConstructor
public class RoleController {

    private final RoleService roleService;

    @PostMapping
    public Role create(@RequestBody RoleRequest request) {
        Role role = Role.builder()
                .name(request.getName())
                .build();
        return roleService.create(role);
    }

    @GetMapping
    public List<Role> getAll() {
        return roleService.getAll();
    }

    @GetMapping("/{id}")
    public Role getOne(@PathVariable Long id) {
        return roleService.getById(id);
    }

    @PutMapping("/{id}")
    public Role update(@PathVariable Long id, @RequestBody RoleRequest request) {
        Role role = Role.builder()
                .name(request.getName())
                .build();
        return roleService.update(id, role);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        roleService.delete(id);
    }

    @Getter
    @Setter
    public static class RoleRequest {
        private String name;
    }
}
