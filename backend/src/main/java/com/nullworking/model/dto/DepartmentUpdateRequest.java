package com.nullworking.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public class DepartmentUpdateRequest {
    @JsonProperty("deptId")
    private Integer deptId;

    @JsonProperty("deptName")
    private String deptName;

    @JsonProperty("parentDept")
    private Integer parentDept;

    @JsonProperty("deptDescription")
    private String deptDescription;

    // Getters and Setters
    public Integer getDeptId() {
        return deptId;
    }

    public void setDeptId(Integer deptId) {
        this.deptId = deptId;
    }

    public String getDeptName() {
        return deptName;
    }

    public void setDeptName(String deptName) {
        this.deptName = deptName;
    }

    public Integer getParentDept() {
        return parentDept;
    }

    public void setParentDept(Integer parentDept) {
        this.parentDept = parentDept;
    }

    public String getDeptDescription() {
        return deptDescription;
    }

    public void setDeptDescription(String deptDescription) {
        this.deptDescription = deptDescription;
    }
}
