package com.nullworking.controller;

import java.util.*;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.nullworking.model.Task;
import com.nullworking.repository.TaskExecutorRelationRepository;
import com.nullworking.repository.TaskRepository;

import io.swagger.v3.oas.annotations.Operation;

@RestController
@RequestMapping("/api/task")
public class ListTaskController {

	@Autowired
	private TaskRepository taskRepository;

	@Autowired
	private TaskExecutorRelationRepository relationRepository;

	@Operation(summary = "查看任务", description = "按用户ID返回其创建与参与的未删除任务列表，完成任务包含finishTime")
	@GetMapping("/ListUserTasks")
	public Map<String, Object> listUserTasks(@RequestParam("userID") Integer userId) {
		Map<String, Object> result = new HashMap<>();

		List<Task> createdTasks = taskRepository.findByCreator_UserIdAndIsDeletedFalse(userId);
		List<Integer> executingTaskIds = relationRepository.findActiveTaskIdsByExecutor(userId);
		Set<Integer> executingIdSet = new HashSet<>(executingTaskIds);
		List<Task> executingTasks = executingIdSet.isEmpty() ? Collections.emptyList()
				: taskRepository.findAllById(executingIdSet).stream()
					.filter(t -> Boolean.FALSE.equals(t.getIsDeleted()))
					.collect(Collectors.toList());

		Map<String, Object> data = new HashMap<>();
		data.put("created", createdTasks.stream().map(this::toDtoWithExecutors).collect(Collectors.toList()));
		data.put("participated", executingTasks.stream().map(this::toDtoWithExecutors).collect(Collectors.toList()));

		result.put("code", 200);
		result.put("data", data);
		return result;
	}

	private Map<String, Object> toDto(Task t) {
		Map<String, Object> m = new LinkedHashMap<>();
		m.put("taskID", String.valueOf(t.getTaskId()));
		m.put("creatorID", t.getCreator() != null ? String.valueOf(t.getCreator().getUserId()) : null);
		m.put("taskTitle", t.getTaskTitle());
		m.put("taskContent", t.getTaskContent());
		m.put("taskPriority", String.valueOf(t.getPriority()));
		m.put("taskStatus", String.valueOf(t.getTaskStatus()));
		m.put("creationTime", t.getCreationTime() != null ? t.getCreationTime().toString() : null);
		m.put("deadline", t.getDeadline() != null ? t.getDeadline().toString() : null);
		if (Byte.valueOf((byte)2).equals(t.getTaskStatus())) {
			m.put("finishTime", t.getFinishTime() != null ? t.getFinishTime().toString() : null);
		}
		return m;
	}

	private Map<String, Object> toDtoWithExecutors(Task t) {
		Map<String, Object> m = toDto(t);
		List<String> executorIds = relationRepository
				.findActiveExecutorIdsByTaskId(t.getTaskId())
				.stream()
				.map(String::valueOf)
				.collect(Collectors.toList());
		m.put("executorIDs", executorIds);
		return m;
	}
}
