package com.pmis.demo.service;

import com.pmis.demo.domain.entity.Role;
import com.pmis.demo.dto.RoleResponse;
import com.pmis.demo.repository.RoleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class RoleService {

    private final RoleRepository roleRepository;

    public Role create(Role role) {
        return roleRepository.save(role);
    }

    public List<RoleResponse> getAll() {
        return roleRepository.findAll().stream()
                .map(this::toResponse)
                .toList();
    }

    public RoleResponse getById(Long id) {
        return toResponse(findRole(id));
    }

    public Role update(Long id, Role update) {
        Role role = findRole(id);
        role.setName(update.getName());
        return roleRepository.save(role);
    }

    public void delete(Long id) {
        roleRepository.deleteById(id);
    }

    private Role findRole(Long id) {
        return roleRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Role not found"));
    }

    private RoleResponse toResponse(Role role) {
        return RoleResponse.builder()
                .id(role.getId())
                .name(role.getName())
                .build();
    }
}
