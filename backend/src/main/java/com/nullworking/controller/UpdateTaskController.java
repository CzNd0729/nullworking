package com.nullworking.controller;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.nullworking.model.Task;
import com.nullworking.repository.TaskRepository;

import io.swagger.v3.oas.annotations.Operation;

import java.util.Optional;

@RestController
@RequestMapping("/api/task")
public class UpdateTaskController {

	@Autowired
	private TaskRepository taskRepository;

	@Operation(summary = "更新任务", description = "更新任务信息，优先级0-3，返回code：200成功，400参数错误，404任务不存在，500失败")
	@PutMapping("/updateTask")
	public Map<String, Object> updateTask(
			@RequestParam("taskID") Integer taskID,
			@RequestParam("title") String title,
			@RequestParam("content") String content,
			@RequestParam("priority") Integer priority,
			@RequestParam("deadline") LocalDateTime deadline) {
		
		Map<String, Object> result = new HashMap<>();
		
		try {
			// 验证优先级范围 (0-3)
			if (priority < 0 || priority > 3) {
				result.put("code", 400);
				result.put("message", "优先级必须在0-3之间");
				return result;
			}
			
			// 查找任务
			Optional<Task> taskOpt = taskRepository.findById(taskID);
			if (taskOpt.isEmpty()) {
				result.put("code", 404);
				result.put("message", "任务不存在");
				return result;
			}
			
			Task task = taskOpt.get();
			
			// 检查任务是否已被删除
			if (Boolean.TRUE.equals(task.getIsDeleted())) {
				result.put("code", 404);
				result.put("message", "任务已被删除");
				return result;
			}
			
			// 更新任务信息
			task.setTaskTitle(title);
			task.setTaskContent(content);
			task.setPriority(priority.byteValue());
			task.setDeadline(deadline);
			
			// 保存更新后的任务
			taskRepository.save(task);
			
			result.put("code", 200);
			result.put("message", "任务更新成功");
			result.put("taskID", task.getTaskId());
			
		} catch (Exception e) {
			result.put("code", 500);
			result.put("message", "任务更新失败: " + e.getMessage());
		}
		
		return result;
	}
}
