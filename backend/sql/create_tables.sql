-- 1. 角色表（无外键依赖）
CREATE TABLE `role` (
  `Role_ID` INT(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `Role_Name` VARCHAR(64) NOT NULL COMMENT '角色名称',
  `Role_Description` VARCHAR(255) DEFAULT NULL COMMENT '角色描述（可选）',
  `Creation_Time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `Update_Time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`Role_ID`),
  UNIQUE KEY `idx_role_name` (`Role_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色表';

-- 2. 部门表（仅自引用外键，可早期创建）
CREATE TABLE `department` (
  `Department_ID` INT(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `Department_Name` VARCHAR(64) NOT NULL COMMENT '部门名称',
  `Parent_Department_ID` INT(11) DEFAULT NULL COMMENT '父部门ID，用于构建部门层级',
  `Department_Description` VARCHAR(255) DEFAULT NULL COMMENT '部门描述（可选）',
  `Creation_Time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `Update_Time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`Department_ID`),
  UNIQUE KEY `idx_dept_name` (`Department_Name`),
  KEY `fk_parent_dept` (`Parent_Department_ID`),
  CONSTRAINT `fk_parent_dept` FOREIGN KEY (`Parent_Department_ID`) REFERENCES `department` (`Department_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='部门表';

-- 3. 权限表（无外键依赖）
CREATE TABLE `permission` (
  `Permission_ID` INT(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `Permission_Name` VARCHAR(64) NOT NULL COMMENT '权限名称',
  `Permission_Description` VARCHAR(255) DEFAULT NULL COMMENT '权限描述（可选）',
  `Creation_Time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `Update_Time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`Permission_ID`),
  UNIQUE KEY `idx_permission_name` (`Permission_Name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='权限表';

-- 4. 用户表（依赖角色表和部门表）
CREATE TABLE `user` (
    `User_ID` int NOT NULL AUTO_INCREMENT COMMENT '自增主键',
    `Role_ID` int DEFAULT NULL COMMENT '外键，关联角色表',
    `Dept_ID` int DEFAULT NULL COMMENT '外键，关联部门表',
    `User_Name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '用户名（唯一）',
    `Password` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '密码（加密储存）',
    `Phone_Number` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '手机号',
    `Email` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '邮箱（可选）',
    `Creation_Time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `Real_Name` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
    `huawei_push_token` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `Status` tinyint NOT NULL DEFAULT '0' COMMENT '用于用户删除(软删除)，新增用户默认为0，被删除用户置为1',
    PRIMARY KEY (`User_ID`),
    UNIQUE KEY `idx_username` (`User_Name`),
    KEY `fk_user_role` (`Role_ID`),
    KEY `fk_user_dept` (`Dept_ID`),
    CONSTRAINT `fk_user_dept` FOREIGN KEY (`Dept_ID`) REFERENCES `department` (`Department_ID`),
    CONSTRAINT `fk_user_role` FOREIGN KEY (`Role_ID`) REFERENCES `role` (`Role_ID`)
) ENGINE = InnoDB AUTO_INCREMENT = 49 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '用户表'

-- 5. 角色-权限关联表（依赖角色表和权限表）
CREATE TABLE `role_permission_relation` (
  `Relation_ID` INT(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `Role_ID` INT(11) NOT NULL COMMENT '外键，关联角色表',
  `Permission_ID` INT(11) NOT NULL COMMENT '外键，关联权限表',
  PRIMARY KEY (`Relation_ID`),
  UNIQUE KEY `idx_role_permission` (`Role_ID`,`Permission_ID`),
  KEY `fk_rp_permission` (`Permission_ID`),
  CONSTRAINT `fk_rp_role` FOREIGN KEY (`Role_ID`) REFERENCES `role` (`Role_ID`),
  CONSTRAINT `fk_rp_permission` FOREIGN KEY (`Permission_ID`) REFERENCES `permission` (`Permission_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色-权限关联表';

-- 6. 任务表（依赖用户表，加入软删除与完成时间字段）
CREATE TABLE `task` (
  `Task_ID` INT(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `Creator_ID` INT(11) NOT NULL COMMENT '外键，关联用户表（任务创建人）',
  `Task_Title` VARCHAR(128) NOT NULL COMMENT '任务标题',
  `Task_Content` TEXT NOT NULL COMMENT '任务内容',
  `Priority` TINYINT NOT NULL COMMENT '优先级（p0-p3）',
  `Task_Status` TINYINT NOT NULL COMMENT '任务状态（0=进行中，1=已延期, 2=已完成, 3=已关闭）',
  `Creation_Time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `Deadline` DATETIME NOT NULL COMMENT '截止时间',
  `Completion_Time` DATETIME NULL COMMENT '任务完成时间（taskStatus=2 时填充）',
  PRIMARY KEY (`Task_ID`),
  KEY `fk_task_creator` (`Creator_ID`),
  KEY `idx_task_status` (`Task_Status`),
  KEY `idx_task_deadline` (`Deadline`),
  CONSTRAINT `fk_task_creator` FOREIGN KEY (`Creator_ID`) REFERENCES `user` (`User_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务表';

-- 7. 重要事项表（依赖用户表）
CREATE TABLE `important_item` (
  `Item_ID` INT(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `User_ID` INT(11) NOT NULL COMMENT '外键，关联用户表（事项所属用户）',
  `Item_Title` VARCHAR(128) NOT NULL COMMENT '事项标题',
  `Item_Content` TEXT NOT NULL COMMENT '事项内容',
  `Display_Order` TINYINT NOT NULL COMMENT '显示顺序（1-10）',
  `Creation_Time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `Update_Time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`Item_ID`),
  KEY `fk_item_user` (`User_ID`),
  UNIQUE KEY `idx_user_display_order` (`User_ID`, `Display_Order`),
  CONSTRAINT `fk_item_user` FOREIGN KEY (`User_ID`) REFERENCES `user` (`User_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='重要事项表';

-- 8. AI分析结果表（依赖用户表）
CREATE TABLE `ai_analysis_result` (
  `Result_ID` INT(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `User_ID` INT(11) NOT NULL COMMENT '外键，关联用户表（分析结果所属用户）',
  `Prompt` MEDIUMTEXT NOT NULL COMMENT 'AI分析的提示词（JSON格式存储）',
  `Content` MEDIUMTEXT NOT NULL COMMENT 'AI分析结果内容（JSON格式存储）',
  `Analysis_Time` DATETIME NOT NULL COMMENT '分析结果生成时间',
  PRIMARY KEY (`Result_ID`),
  KEY `fk_analysis_user` (`User_ID`),
  KEY `idx_analysis_time` (`Analysis_Time`),
  CONSTRAINT `fk_analysis_user` FOREIGN KEY (`User_ID`) REFERENCES `user` (`User_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI分析结果表';

-- 9. 任务-负责人关联表（依赖用户表和任务表，保留是否删除镜像字段）
CREATE TABLE `task_executor_relation` (
  `Relation_ID` INT(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `Executor_ID` INT(11) NOT NULL COMMENT '外键，关联用户表（任务负责人）',
  `Task_ID` INT(11) NOT NULL COMMENT '外键，关联任务表',
  PRIMARY KEY (`Relation_ID`),
  UNIQUE KEY `idx_executor_task` (`Executor_ID`,`Task_ID`),
  KEY `fk_te_task` (`Task_ID`),
  CONSTRAINT `fk_te_executor` FOREIGN KEY (`Executor_ID`) REFERENCES `user` (`User_ID`),
  CONSTRAINT `fk_te_task` FOREIGN KEY (`Task_ID`) REFERENCES `task` (`Task_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务-负责人关联表';

-- 10. 日志表（依赖用户表和任务表，保留是否删除镜像字段）
CREATE TABLE `log` (
  `Log_ID` INT(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键，日志唯一标识',
  `User_ID` INT(11) NOT NULL COMMENT '外键，关联用户表（日志拥有者）',
  `Task_ID` INT(11) NOT NULL COMMENT '外键，关联任务表（日志关联任务）',
  `Log_Title` VARCHAR(128) NOT NULL COMMENT '日志标题，简述日志核心内容',
  `Log_Content` TEXT NOT NULL COMMENT '日志详细内容',
  `Task_Progress` VARCHAR(64) NOT NULL COMMENT '任务进度描述（如：30）',
  `Log_Date` DATE NOT NULL COMMENT '日志对应的业务日期',
  `Log_Status` TINYINT NOT NULL COMMENT '日志状态(0-未完成,1-已完成)',
  `Start_Time` TIME NOT NULL COMMENT '开始时间（仅时间，不含日期，格式HH:MM:SS）',
  `End_Time` TIME NOT NULL COMMENT '结束时间（仅时间，不含日期，格式HH:MM:SS）',
  `Creation_Time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '日志创建时间（自动记录）',
  `Update_Time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '日志更新时间（自动更新）',
  PRIMARY KEY (`Log_ID`),
  KEY `fk_log_user` (`User_ID`),
  KEY `fk_log_task` (`Task_ID`),
  KEY `idx_log_date` (`Log_Date`),
  CONSTRAINT `fk_log_user` FOREIGN KEY (`User_ID`) REFERENCES `user` (`User_ID`),
  CONSTRAINT `fk_log_task` FOREIGN KEY (`Task_ID`) REFERENCES `task` (`Task_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='日志表，记录用户关联任务的进度、时间等信息';

-- 11. 日志文件附件表（依赖日志表，存储日志相关的图片等文件信息）
CREATE TABLE `log_file` (
  `File_ID` INT(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `Log_ID` INT(11) NULL COMMENT '外键，关联日志表（所属日志）',
  `Original_Name` VARCHAR(255) NOT NULL COMMENT '文件原始名称（如"风景.jpg"）',
  `Storage_Path` VARCHAR(512) NOT NULL COMMENT '本地存储相对路径（如"user_123/20251018/uuid.jpg"）',
  `File_Type` VARCHAR(50) NOT NULL COMMENT '文件类型（如"image/jpeg"）',
  `File_Size` BIGINT NOT NULL COMMENT '文件大小（单位：字节）',
  `Upload_Time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '文件上传时间',
  PRIMARY KEY (`File_ID`),
  KEY `fk_file_log` (`Log_ID`),
  KEY `idx_upload_time` (`Upload_Time`),
  CONSTRAINT `fk_file_log` FOREIGN KEY (`Log_ID`) REFERENCES `log` (`Log_ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='日志文件附件表（存储日志相关的图片等文件信息）';

12-- 创建评论表
CREATE TABLE `comment` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '评论ID（主键）',
  `log_id` int NOT NULL COMMENT '评论的日志ID（外键）',
  `user_id` int DEFAULT NULL COMMENT '评论者用户ID（外键）',
  `content` text NOT NULL COMMENT '评论内容',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '评论创建时间',
  `updated_at` datetime DEFAULT NULL COMMENT '评论更新时间（支持编辑）',
  PRIMARY KEY (`id`),
  -- 外键关联日志表（日志删除则评论同步删除）
  KEY `fk_comment_log` (`log_id`),
  CONSTRAINT `fk_comment_log` FOREIGN KEY (`log_id`) REFERENCES `log` (`Log_ID`) ON DELETE CASCADE,
  -- 外键关联用户表（用户删除则评论保留，用户ID设为NULL）
  KEY `fk_comment_user` (`user_id`),
  CONSTRAINT `fk_comment_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`User_ID`) ON DELETE SET NULL,
  -- 索引：查询某用户发布的所有评论
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='日志评论表';

13-- 创建通知表
CREATE TABLE `notification` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '通知ID（主键）',
  `receiver_id` int NOT NULL COMMENT '接收通知的用户ID（外键）',
  `content` varchar(500) NOT NULL COMMENT '通知文本内容',
  `related_type` varchar(20) NOT NULL COMMENT '关联对象类型（log=日志，task=任务，comment=评论等）',
  `related_id` int NOT NULL COMMENT '关联对象的ID（如日志ID、任务ID、评论ID等）',
  `is_read` tinyint NOT NULL DEFAULT 0 COMMENT '是否已读（0=未读，1=已读）',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '通知创建时间',
  PRIMARY KEY (`id`),
  -- 外键关联用户表（接收者删除则通知同步删除）
  KEY `fk_notification_receiver` (`receiver_id`),
  CONSTRAINT `fk_notification_receiver` FOREIGN KEY (`receiver_id`) REFERENCES `user` (`User_ID`) ON DELETE CASCADE,
  -- 联合索引：加速查询某用户的未读/已读通知
  KEY `idx_receiver_read` (`receiver_id`, `is_read`),
  -- 索引：按时间倒序展示最新通知
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统通知表';