package com.nullworking.model;

import jakarta.persistence.*;
import java.io.Serializable;

@Entity
@Table(name = "Role_Permission_Relation")
public class RolePermissionRelation implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "Relation_ID")
    private Integer relationId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "Role_ID", nullable = false)
    private Role role;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "Permission_ID", nullable = false)
    private Permission permission;

    // Getters and Setters
    public Integer getRelationId() {
        return relationId;
    }

    public void setRelationId(Integer relationId) {
        this.relationId = relationId;
    }

    public Role getRole() {
        return role;
    }

    public void setRole(Role role) {
        this.role = role;
    }

    public Permission getPermission() {
        return permission;
    }

    public void setPermission(Permission permission) {
        this.permission = permission;
    }
}
