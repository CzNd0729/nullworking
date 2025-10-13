package com.nullworking.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.nullworking.model.Task;
import com.nullworking.repository.LogRepository;
import com.nullworking.repository.TaskExecutorRelationRepository;
import com.nullworking.repository.TaskRepository;

import io.swagger.v3.oas.annotations.Operation;

import java.time.LocalDateTime;
import java.util.Optional;

@RestController
@RequestMapping("/api/task")
public class DeleteTaskController {

	@Autowired
	private TaskRepository taskRepository;

	@Autowired
	private LogRepository logRepository;

	@Autowired
	private TaskExecutorRelationRepository taskExecutorRelationRepository;

	@Operation(summary = "删除任务(软删除)", description = "根据任务ID将任务标记为已删除，返回code：200成功，208已删除，404不存在，500失败")
	@DeleteMapping("/deleteTask")
	@Transactional
	public Map<String, Object> deleteTask(@RequestParam("taskID") Integer taskId) {
		Map<String, Object> result = new HashMap<>();
		Optional<Task> taskOpt = taskRepository.findById(taskId);
		if (taskOpt.isEmpty()) {
			result.put("code", 404);
			return result;
		}
		try {
			Task task = taskOpt.get();
			if (Boolean.TRUE.equals(task.getIsDeleted())) {
				// 已经是删除状态，返回已删除标识码
				result.put("code", 208);
				return result;
			}
			task.setIsDeleted(true);
			task.setDeletedTime(LocalDateTime.now());
			taskRepository.save(task);

			// 同步镜像标记到日志与负责人关联表
			logRepository.markTaskDeleted(taskId);
			taskExecutorRelationRepository.markTaskDeleted(taskId);

			result.put("code", 200);
		} catch (Exception e) {
			result.put("code", 500);
		}
		return result;
	}
}
