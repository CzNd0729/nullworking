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
    `task_id` int NOT NULL AUTO_INCREMENT,
    `completion_time` datetime(6) DEFAULT NULL,
    `creation_time` datetime(6) NOT NULL,
    `deadline` datetime(6) NOT NULL,
    `is_deadline_notified` tinyint(1) NOT NULL DEFAULT '0',
    `priority` tinyint NOT NULL,
    `task_content` tinytext NOT NULL,
    `task_status` tinyint NOT NULL,
    `task_title` varchar(128) NOT NULL,
    `creator_id` int NOT NULL,
    PRIMARY KEY (`task_id`),
    KEY `FKqc1galw66ryn480v0lygu3n4c` (`creator_id`),
    CONSTRAINT `FKqc1galw66ryn480v0lygu3n4c` FOREIGN KEY (`creator_id`) REFERENCES `user` (`User_ID`)
) ENGINE = InnoDB AUTO_INCREMENT = 3047 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '任务表';

-- 7. 重要事项表（依赖用户表）
CREATE TABLE `important_item` (
    `item_id` int NOT NULL AUTO_INCREMENT,
    `creation_time` datetime(6) NOT NULL,
    `display_order` tinyint NOT NULL,
    `item_content` tinytext NOT NULL,
    `item_title` varchar(128) NOT NULL,
    `update_time` datetime(6) NOT NULL,
    `user_id` int NOT NULL,
    PRIMARY KEY (`item_id`),
    KEY `FKporc48oa8pgtlwwthe73152qb` (`user_id`),
    CONSTRAINT `FKporc48oa8pgtlwwthe73152qb` FOREIGN KEY (`user_id`) REFERENCES `user` (`User_ID`)
) ENGINE = InnoDB AUTO_INCREMENT = 226 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '重要事项表';

-- 8. AI分析结果表（依赖用户表）
CREATE TABLE `ai_analysis_result` (
    `result_id` int NOT NULL AUTO_INCREMENT,
    `analysis_time` datetime(6) NOT NULL,
    `content` mediumtext NOT NULL,
    `mode` int NOT NULL,
    `prompt` mediumtext NOT NULL,
    `status` int NOT NULL,
    `user_id` int NOT NULL,
    PRIMARY KEY (`result_id`),
    KEY `FKaxgrqxgngww5tqivo9k67rtg3` (`user_id`),
    CONSTRAINT `FKaxgrqxgngww5tqivo9k67rtg3` FOREIGN KEY (`user_id`) REFERENCES `user` (`User_ID`)
) ENGINE = InnoDB AUTO_INCREMENT = 19 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'AI分析结果表';

-- 9. 任务-负责人关联表（依赖用户表和任务表，保留是否删除镜像字段）
CREATE TABLE `task_executor_relation` (
    `relation_id` int NOT NULL AUTO_INCREMENT,
    `executor_id` int NOT NULL,
    `task_id` int NOT NULL,
    PRIMARY KEY (`relation_id`),
    KEY `FKo3hbkp3gsc059k81abgo7myay` (`executor_id`),
    KEY `FKs2fvemfxbqmgu0c3vojqwadsg` (`task_id`),
    CONSTRAINT `FKo3hbkp3gsc059k81abgo7myay` FOREIGN KEY (`executor_id`) REFERENCES `user` (`User_ID`) ON DELETE CASCADE ON UPDATE RESTRICT,
    CONSTRAINT `FKs2fvemfxbqmgu0c3vojqwadsg` FOREIGN KEY (`task_id`) REFERENCES `task` (`task_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 3026 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT='任务-负责人关联表';

-- 10. 日志表（依赖用户表和任务表，保留是否删除镜像字段）
CREATE TABLE `log` (
    `log_id` int NOT NULL AUTO_INCREMENT,
    `creation_time` datetime(6) NOT NULL,
    `end_time` time(6) DEFAULT NULL,
    `latitude` double DEFAULT NULL,
    `log_content` tinytext NOT NULL,
    `log_date` date NOT NULL,
    `log_status` int NOT NULL,
    `log_title` varchar(255) NOT NULL,
    `longitude` double DEFAULT NULL,
    `start_time` time(6) DEFAULT NULL,
    `task_progress` int NOT NULL,
    `update_time` datetime(6) NOT NULL,
    `task_id` int NOT NULL,
    `user_id` int NOT NULL,
    PRIMARY KEY (`log_id`),
    KEY `FK3wxdofviqe2smmvh1w1yf98o1` (`user_id`),
    KEY `FK4e8v3emcgfqulikhgmp5xfj9q` (`task_id`),
    CONSTRAINT `FK3wxdofviqe2smmvh1w1yf98o1` FOREIGN KEY (`user_id`) REFERENCES `user` (`User_ID`),
    CONSTRAINT `FK4e8v3emcgfqulikhgmp5xfj9q` FOREIGN KEY (`task_id`) REFERENCES `task` (`task_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 5527 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '日志表';

-- 11. 日志文件附件表（依赖日志表，存储日志相关的图片等文件信息）
CREATE TABLE `log_file` (
    `file_id` int NOT NULL AUTO_INCREMENT,
    `file_size` bigint NOT NULL,
    `file_type` varchar(255) NOT NULL,
    `log_id` int DEFAULT NULL,
    `original_name` varchar(255) NOT NULL,
    `storage_path` varchar(255) NOT NULL,
    `upload_time` datetime(6) NOT NULL,
    PRIMARY KEY (`file_id`)
) ENGINE = InnoDB AUTO_INCREMENT = 57 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '日志文件附件表';

--12-- 创建评论表
CREATE TABLE `comment` (
    `id` int NOT NULL AUTO_INCREMENT,
    `content` varchar(255) NOT NULL,
    `created_at` datetime(6) NOT NULL,
    `is_deleted` int NOT NULL,
    `log_id` int NOT NULL,
    `updated_at` datetime(6) DEFAULT NULL,
    `user_id` int DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE = InnoDB AUTO_INCREMENT = 24 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '评论表';

--13-- 创建通知表
CREATE TABLE `notification` (
    `id` int NOT NULL AUTO_INCREMENT,
    `content` varchar(500) NOT NULL,
    `creation_time` datetime(6) NOT NULL,
    `is_read` bit(1) NOT NULL,
    `receiver_id` int NOT NULL,
    `related_id` int NOT NULL,
    `related_type` varchar(20) NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE = InnoDB AUTO_INCREMENT = 2679 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '通知表';

--14-- 创建短链接映射表
CREATE TABLE `short_url` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `short_code` varchar(8) NOT NULL COMMENT '短码（6-8位唯一）',
  `result_id` bigint NOT NULL COMMENT '关联的AI分析结果ID',
  `user_id` bigint NOT NULL COMMENT '生成链接的用户ID（鉴权用）',
  `expire_time` datetime NOT NULL COMMENT '过期时间（默认2小时）',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `visit_count` int DEFAULT 0 COMMENT '访问次数',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_short_code` (`short_code`) COMMENT '短码唯一索引',
  KEY `idx_result_id` (`result_id`) COMMENT '分析结果ID索引',
  KEY `idx_expire_time` (`expire_time`) COMMENT '过期时间索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='短链接映射表';