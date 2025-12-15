package com.nullworking.service;

import com.nullworking.config.CosConfig;
import com.nullworking.model.LogFile;
import com.nullworking.repository.LogFileRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import com.qcloud.cos.COSClient;
import com.qcloud.cos.model.ObjectMetadata;
import com.qcloud.cos.model.PutObjectRequest;
import com.qcloud.cos.model.COSObject;
import com.qcloud.cos.model.GetObjectRequest;
import com.qcloud.cos.model.GeneratePresignedUrlRequest;
import org.springframework.core.io.Resource;
import org.springframework.core.io.InputStreamResource;
import com.nullworking.model.dto.FileDownloadInfo;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Date;
import java.util.List;
import java.util.UUID;
import java.net.URL;

@Service
public class LogFileService {

    @Autowired
    private LogFileRepository logFileRepository;

    @Autowired
    private COSClient cosClient;

    @Autowired
    private CosConfig cosConfig; // 注入 CosConfig 以获取 bucketName

    public LogFile storeFile(MultipartFile file) throws IOException {
        String originalFilename = file.getOriginalFilename();
        String fileExtension = "";
        int dotIndex = originalFilename.lastIndexOf('.');
        if (dotIndex > 0 && dotIndex < originalFilename.length() - 1) {
            fileExtension = originalFilename.substring(dotIndex);
        }
        String fileName = UUID.randomUUID().toString() + fileExtension;

        // 构建 COS 存储路径 (log_files/2025/12/example.log)
        String datePath = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy/MM"));
        String cosKey = "log_files/" + datePath + "/" + fileName;

        // 上传到 COS
        ObjectMetadata objectMetadata = new ObjectMetadata();
        objectMetadata.setContentLength(file.getSize());
        objectMetadata.setContentType(file.getContentType());

        PutObjectRequest putObjectRequest = new PutObjectRequest(cosConfig.getBucketName(), cosKey, file.getInputStream(), objectMetadata);
        cosClient.putObject(putObjectRequest);

        LogFile logFile = new LogFile();
        logFile.setOriginalName(originalFilename);
        logFile.setStoragePath(cosKey); // 存储 COS Key
        logFile.setFileType(file.getContentType());
        logFile.setFileSize(file.getSize());
        logFile.setUploadTime(LocalDateTime.now());

        return logFileRepository.save(logFile);
    }

    public FileDownloadInfo loadFileAsResource(Integer fileId) throws IOException {
        LogFile logFile = logFileRepository.findById(fileId)
                .orElseThrow(() -> new IOException("文件未找到，ID：" + fileId));

        String cosKey = logFile.getStoragePath();
        String bucketName = cosConfig.getBucketName();

        // 方式一：生成预签名 URL (适合直接下载链接)
        // GeneratePresignedUrlRequest req = new GeneratePresignedUrlRequest(bucketName, cosKey);
        // Date expiration = new Date(System.currentTimeMillis() + 30 * 60 * 1000); // 30分钟有效期
        // req.setExpiration(expiration);
        // URL url = cosClient.generatePresignedUrl(req);
        // return new FileDownloadInfo(new UrlResource(url), logFile.getOriginalName(), logFile.getFileType());

        // 方式二：直接从 COS 读取为 InputStreamResource (适合流式传输)
        COSObject cosObject = cosClient.getObject(new GetObjectRequest(bucketName, cosKey));
        Resource resource = new InputStreamResource(cosObject.getObjectContent());

        return new FileDownloadInfo(resource, logFile.getOriginalName(), logFile.getFileType());
    }

    public void updateLogIdForFiles(List<Integer> fileIds, Integer logId) {
        // 先解除原先关联该logId的文件的关联
        removeLogIdForFiles(logId);
        if (fileIds != null && !fileIds.isEmpty()) {
            List<LogFile> logFiles = logFileRepository.findAllById(fileIds);
            for (LogFile logFile : logFiles) {
                logFile.setLogId(logId);
            }
            logFileRepository.saveAll(logFiles);
        }
    }

    public List<LogFile> getLogFilesByLogId(Integer logId) {
        return logFileRepository.findByLogId(logId);
    }

    public void removeLogIdForFiles(Integer logId) {
        List<LogFile> logFiles = logFileRepository.findByLogId(logId);
        for (LogFile logFile : logFiles) {
            logFile.setLogId(null);
        }
        logFileRepository.saveAll(logFiles);
    }

    // 可选：添加删除 COS 对象的方法
    public void deleteFileFromCos(String cosKey) {
        cosClient.deleteObject(cosConfig.getBucketName(), cosKey);
    }
}
