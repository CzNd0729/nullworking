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
  `User_ID` INT(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `Role_ID` INT(11) DEFAULT NULL COMMENT '外键，关联角色表，可为空',
  `Dept_ID` INT(11) DEFAULT NULL COMMENT '外键，关联部门表，可为空',
  `User_Name` VARCHAR(64) NOT NULL COMMENT '用户名（唯一）',
  `Real_Name` VARCHAR(64) NOT NULL COMMENT '真实姓名',
  `Password` VARCHAR(128) DEFAULT NULL COMMENT '密码（加密储存）',
  `Phone_Number` VARCHAR(16) NOT NULL COMMENT '手机号',
  `Email` VARCHAR(64) DEFAULT NULL COMMENT '邮箱（可选）',
  `Creation_Time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`User_ID`),
  UNIQUE KEY `idx_username` (`User_Name`),
  KEY `fk_user_role` (`Role_ID`),
  KEY `fk_user_dept` (`Dept_ID`),
  CONSTRAINT `fk_user_role` FOREIGN KEY (`Role_ID`) REFERENCES `role` (`Role_ID`),
  CONSTRAINT `fk_user_dept` FOREIGN KEY (`Dept_ID`) REFERENCES `department` (`Department_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

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
  KEY `idx_item_order` (`Display_Order`),
  CONSTRAINT `fk_item_user` FOREIGN KEY (`User_ID`) REFERENCES `user` (`User_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='重要事项表';

-- 8. AI分析结果表（依赖用户表）
CREATE TABLE `ai_analysis_result` (
  `Result_ID` INT(11) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `User_ID` INT(11) NOT NULL COMMENT '外键，关联用户表（分析结果所属用户）',
  `Keyword_Imformation` TEXT NOT NULL COMMENT '关键词信息（JSON格式存储）',
  `Trend_Analysis` TEXT NOT NULL COMMENT '趋势分析内容（JSON格式存储）',
  `Task_List` TEXT NOT NULL COMMENT '推荐任务清单（JSON格式存储）',
  `Constructive_Suggestions` TEXT NOT NULL COMMENT 'AI生成的建设性意见',
  `Analysis_Date` DATE NOT NULL COMMENT '分析结果生成日期',
  PRIMARY KEY (`Result_ID`),
  KEY `fk_analysis_user` (`User_ID`),
  KEY `idx_analysis_date` (`Analysis_Date`),
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