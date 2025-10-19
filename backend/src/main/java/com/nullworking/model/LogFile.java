package com.nullworking.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "log_file")
public class LogFile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "File_ID")
    private Integer fileId;

    @Column(name = "Log_ID", nullable = false)
    private Integer logId;

    @Column(name = "Original_Name", nullable = false)
    private String originalName;

    @Column(name = "Storage_Path", nullable = false)
    private String storagePath;

    @Column(name = "File_Type", nullable = false)
    private String fileType;

    @Column(name = "File_Size", nullable = false)
    private Long fileSize;

    @Column(name = "Upload_Time", nullable = false, updatable = false)
    private LocalDateTime uploadTime;

    // Getters and Setters
    public Integer getFileId() {
        return fileId;
    }

    public void setFileId(Integer fileId) {
        this.fileId = fileId;
    }

    public Integer getLogId() {
        return logId;
    }

    public void setLogId(Integer logId) {
        this.logId = logId;
    }

    public String getOriginalName() {
        return originalName;
    }

    public void setOriginalName(String originalName) {
        this.originalName = originalName;
    }

    public String getStoragePath() {
        return storagePath;
    }

    public void setStoragePath(String storagePath) {
        this.storagePath = storagePath;
    }

    public String getFileType() {
        return fileType;
    }

    public void setFileType(String fileType) {
        this.fileType = fileType;
    }

    public Long getFileSize() {
        return fileSize;
    }

    public void setFileSize(Long fileSize) {
        this.fileSize = fileSize;
    }

    public LocalDateTime getUploadTime() {
        return uploadTime;
    }

    public void setUploadTime(LocalDateTime uploadTime) {
        this.uploadTime = uploadTime;
    }
}
