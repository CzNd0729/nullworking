package com.nullworking.controller;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.nullworking.model.Task;
import com.nullworking.model.TaskExecutorRelation;
import com.nullworking.model.User;
import com.nullworking.repository.TaskExecutorRelationRepository;
import com.nullworking.repository.TaskRepository;
import com.nullworking.repository.UserRepository;

import io.swagger.v3.oas.annotations.Operation;

import java.util.Optional;
import java.util.List;

@RestController
@RequestMapping("/api/task")
public class PublishTaskController {

	@Autowired
	private TaskRepository taskRepository;

	@Autowired
	private UserRepository userRepository;

	@Autowired
	private TaskExecutorRelationRepository taskExecutorRelationRepository;

	@Operation(summary = "发布任务", description = "创建新任务并分配多个执行者，优先级0-3，返回code：200成功，400参数错误，404创建者不存在，500失败")
	@PostMapping("/publishTask")
	public Map<String, Object> publishTask(
			@RequestParam("creatorID") Integer creatorID,
			@RequestParam("title") String title,
			@RequestParam("content") String content,
			@RequestParam("priority") Integer priority,
			@RequestParam("executorIDs") List<Integer> executorIDs,
			@RequestParam("deadline") LocalDateTime deadline) {
		
		Map<String, Object> result = new HashMap<>();
		
		try {
			// 验证优先级范围 (0-3)
			if (priority < 0 || priority > 3) {
				result.put("code", 400);
				result.put("message", "优先级必须在0-3之间");
				return result;
			}
			
			// 验证创建者是否存在
			Optional<User> creatorOpt = userRepository.findById(creatorID);
			if (creatorOpt.isEmpty()) {
				result.put("code", 404);
				result.put("message", "创建者不存在");
				return result;
			}
			
			// 验证执行者是否都存在
			for (Integer executorID : executorIDs) {
				Optional<User> executorOpt = userRepository.findById(executorID);
				if (executorOpt.isEmpty()) {
					result.put("code", 404);
					result.put("message", "执行者ID " + executorID + " 不存在");
					return result;
				}
			}
			
			// 创建任务
			Task task = new Task();
			task.setCreator(creatorOpt.get());
			task.setTaskTitle(title);
			task.setTaskContent(content);
			task.setPriority(priority.byteValue());
			task.setTaskStatus((byte) 0); // 0-待开始
			task.setCreationTime(LocalDateTime.now());
			task.setDeadline(deadline);
			task.setIsDeleted(false);
			
			// 保存任务
			Task savedTask = taskRepository.save(task);
			
			// 创建执行者关联关系
			for (Integer executorID : executorIDs) {
				User executor = userRepository.findById(executorID).get();
				TaskExecutorRelation relation = new TaskExecutorRelation();
				relation.setTask(savedTask);
				relation.setExecutor(executor);
				relation.setTaskIsDeleted(false);
				taskExecutorRelationRepository.save(relation);
			}
			
			result.put("code", 200);
			result.put("message", "任务发布成功");
			result.put("taskID", savedTask.getTaskId());
			
		} catch (Exception e) {
			result.put("code", 500);
			result.put("message", "任务发布失败: " + e.getMessage());
		}
		
		return result;
	}
}
