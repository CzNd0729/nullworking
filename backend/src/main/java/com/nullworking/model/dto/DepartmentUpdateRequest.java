package com.nullworking.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public class DepartmentUpdateRequest {

    @JsonProperty("deptName")
    private String deptName;

    @JsonProperty("parentDept")
    private Integer parentDept;

    @JsonProperty("deptDescription")
    private String deptDescription;

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
