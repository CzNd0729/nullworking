package com.nullworking.model.dto;

import org.springframework.core.io.Resource;

public class FileDownloadInfo {
    private Resource resource;
    private String originalFileName;
    private String contentType;

    public FileDownloadInfo(Resource resource, String originalFileName, String contentType) {
        this.resource = resource;
        this.originalFileName = originalFileName;
        this.contentType = contentType;
    }

    public Resource getResource() {
        return resource;
    }

    public void setResource(Resource resource) {
        this.resource = resource;
    }

    public String getOriginalFileName() {
        return originalFileName;
    }

    public void setOriginalFileName(String originalFileName) {
        this.originalFileName = originalFileName;
    }

    public String getContentType() {
        return contentType;
    }

    public void setContentType(String contentType) {
        this.contentType = contentType;
    }
}
