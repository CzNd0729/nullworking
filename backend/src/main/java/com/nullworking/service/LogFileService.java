package com.nullworking.service;

import com.nullworking.model.LogFile;
import com.nullworking.repository.LogFileRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class LogFileService {

    @Value("${file.upload-dir}")
    private String uploadDir;

    @Autowired
    private LogFileRepository logFileRepository;

    public LogFile storeFile(MultipartFile file, Integer logId) throws IOException {
        // Normalize file name
        String originalFilename = file.getOriginalFilename();
        String fileName = UUID.randomUUID().toString() + "_" + originalFilename;

        // Resolve upload directory
        Path uploadPath = Paths.get(uploadDir + "/log_files/").toAbsolutePath().normalize();
        Files.createDirectories(uploadPath); // Create directories if they don't exist

        Path targetLocation = uploadPath.resolve(fileName);
        Files.copy(file.getInputStream(), targetLocation);

        LogFile logFile = new LogFile();
        logFile.setLogId(logId);
        logFile.setOriginalName(originalFilename);
        logFile.setStoragePath("/log_files/" + fileName); // Store relative path
        logFile.setFileType(file.getContentType());
        logFile.setFileSize(file.getSize());
        logFile.setUploadTime(LocalDateTime.now());

        return logFileRepository.save(logFile);
    }
}
