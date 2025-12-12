package com.pmis.demo.domain.enums;

public enum RoleType {
    ADMIN,
    MANAGER,
    MEMBER,
    VIEWER;

    public static RoleType fromName(String name) {
        return RoleType.valueOf(name.toUpperCase());
    }
}
