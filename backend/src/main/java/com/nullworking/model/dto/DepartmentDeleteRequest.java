package com.nullworking.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public class DepartmentDeleteRequest {
    @JsonProperty("deptId")
    private Integer deptId;

    // Getters and Setters
    public Integer getDeptId() {
        return deptId;
    }

    public void setDeptId(Integer deptId) {
        this.deptId = deptId;
    }
}
