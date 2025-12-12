package com.pmis.demo.service;

import com.pmis.demo.domain.enums.RoleType;
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
        role.setName(normalizeRoleName(role.getName()));
        applyDefaultPermissions(role);
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
        role.setName(normalizeRoleName(update.getName()));
        // Update permissions only if provided (nullable -> keep existing)
        if (update.getCanRead() != null) role.setCanRead(update.getCanRead());
        if (update.getCanWrite() != null) role.setCanWrite(update.getCanWrite());
        if (update.getCanDelete() != null) role.setCanDelete(update.getCanDelete());
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
                .canRead(role.getCanRead())
                .canWrite(role.getCanWrite())
                .canDelete(role.getCanDelete())
                .build();
    }

    private String normalizeRoleName(String name) {
        if (name == null) {
            throw new IllegalArgumentException("Role name is required");
        }
        try {
            return RoleType.fromName(name).name();
        } catch (IllegalArgumentException ex) {
            throw new IllegalArgumentException("Invalid role name. Allowed: ADMIN, MANAGER, MEMBER, VIEWER");
        }
    }

    private void applyDefaultPermissions(Role role) {
        if (role.getCanRead() == null) role.setCanRead(true);
        if (role.getCanWrite() == null) role.setCanWrite(false);
        if (role.getCanDelete() == null) role.setCanDelete(false);
        // default matrix based on role name
        switch (RoleType.valueOf(role.getName())) {
            case ADMIN -> { role.setCanRead(true); role.setCanWrite(true); role.setCanDelete(true); }
            case MANAGER -> { role.setCanRead(true); role.setCanWrite(true); role.setCanDelete(false); }
            case MEMBER -> { role.setCanRead(true); role.setCanWrite(true); role.setCanDelete(false); }
            case VIEWER -> { role.setCanRead(true); role.setCanWrite(false); role.setCanDelete(false); }
        }
    }
}
