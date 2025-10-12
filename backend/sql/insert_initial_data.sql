-- 插入角色表数据
INSERT INTO `role` (`Role_Name`, `Role_Description`) VALUES
('管理员', '系统管理员，拥有所有权限'),
('部门主管', '负责部门管理和任务分配'),
('普通员工', '执行分配的任务和提交工作日志');

-- 插入部门表数据
INSERT INTO `department` (`Department_Name`, `Parent_Department_ID`, `Department_Description`) VALUES
('总公司', NULL, '公司总部'),
('技术部', 1, '负责系统开发和维护'),
('市场部', 1, '负责市场推广和销售'),
('人力资源部', 1, '负责人事管理和招聘');

-- 插入权限表数据
INSERT INTO `permission` (`Permission_Name`, `Permission_Description`) VALUES
('user:create', '创建用户'),
('user:delete', '删除用户'),
('user:update', '更新用户信息'),
('user:query', '查询用户信息'),
('task:create', '创建任务'),
('task:delete', '删除任务'),
('task:update', '更新任务'),
('task:query', '查询任务'),
('log:create', '创建日志'),
('log:query', '查询日志');

-- 插入用户表数据（密码均为123456加密后的结果）
INSERT INTO `user` (`Role_ID`, `Dept_ID`, `User_Name`, `Password`, `Phone_Number`, `Email`) VALUES
(1, 1, 'admin', '$2a$10$e9X8QJQ8l7U4l5D3Y6zH6eJQZ9rD8e7w6e5r4t3y2u1i', '13800138000', 'admin@example.com'),
(2, 2, 'tech_lead', '$2a$10$e9X8QJQ8l7U4l5D3Y6zH6eJQZ9rD8e7w6e5r4t3y2u1i', '13800138001', 'tech_lead@example.com'),
(3, 2, 'dev1', '$2a$10$e9X8QJQ8l7U4l5D3Y6zH6eJQZ9rD8e7w6e5r4t3y2u1i', '13800138002', 'dev1@example.com'),
(3, 2, 'dev2', '$2a$10$e9X8QJQ8l7U4l5D3Y6zH6eJQZ9rD8e7w6e5r4t3y2u1i', '13800138003', 'dev2@example.com'),
(2, 3, 'market_lead', '$2a$10$e9X8QJQ8l7U4l5D3Y6zH6eJQZ9rD8e7w6e5r4t3y2u1i', '13800138004', 'market_lead@example.com'),
(3, 3, 'market1', '$2a$10$e9X8QJQ8l7U4l5D3Y6zH6eJQZ9rD8e7w6e5r4t3y2u1i', '13800138005', 'market1@example.com'),
(2, 4, 'hr_lead', '$2a$10$e9X8QJQ8l7U4l5D3Y6zH6eJQZ9rD8e7w6e5r4t3y2u1i', '13800138006', 'hr_lead@example.com');

-- 插入角色-权限关联表数据
INSERT INTO `role_permission_relation` (`Role_ID`, `Permission_ID`) VALUES
-- 管理员拥有所有权限
(1, 1), (1, 2), (1, 3), (1, 4),
(1, 5), (1, 6), (1, 7), (1, 8),
(1, 9), (1, 10),
-- 部门主管权限
(2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2, 10),
-- 普通员工权限
(3, 4), (3, 8), (3, 9), (3, 10);

-- 插入任务表数据
INSERT INTO `task` (`Creator_ID`, `Task_Title`, `Task_Content`, `Priority`, `Task_Status`, `Deadline`) VALUES
(2, '完成用户管理模块开发', '开发用户CRUD功能及权限控制', 1, 1, '2023-12-15 18:00:00'),
(2, '设计数据库表结构', '根据需求设计系统所有表结构', 0, 2, '2023-11-30 18:00:00'),
(5, '制定Q4市场推广计划', '策划第四季度产品推广活动', 1, 0, '2023-12-10 18:00:00'),
(7, '完成12月招聘计划', '招聘3名开发人员和2名市场专员', 2, 1, '2023-12-20 18:00:00'),
(2, '系统测试与bug修复', '对已开发模块进行测试并修复发现的bug', 1, 0, '2023-12-25 18:00:00');

-- 插入任务-负责人关联表数据
INSERT INTO `task_executor_relation` (`Executor_ID`, `Task_ID`) VALUES
(3, 1),  -- dev1负责用户管理模块开发
(2, 2),  -- tech_lead负责数据库设计
(6, 3),  -- market1负责Q4市场推广计划
(7, 4),  -- hr_lead负责12月招聘计划
(3, 5),  -- dev1参与系统测试
(4, 5);  -- dev2参与系统测试

-- 插入重要事项表数据
INSERT INTO `important_item` (`User_ID`, `Item_Title`, `Item_Content`, `Display_Order`) VALUES
(1, '周一会议', '上午10点召开部门主管会议', 1),
(2, '代码评审', '周五下午进行本周代码评审', 1),
(3, '学习新框架', '本周需要学习React新特性', 2),
(5, '客户拜访', '周三下午拜访重要客户', 1);

-- 插入日志表数据
INSERT INTO `log` (`User_ID`, `Task_ID`, `Log_Content`, `Task_Progress`, `Log_Date`) VALUES
(3, 1, '完成用户列表和详情页开发', '40%', '2023-11-28'),
(3, 1, '实现用户新增和编辑功能', '70%', '2023-11-29'),
(2, 2, '完成所有核心表结构设计', '100%', '2023-11-25'),
(2, 2, '编写数据库文档', '100%', '2023-11-26'),
(6, 3, '收集市场数据，开始制定计划', '30%', '2023-11-29');

-- 插入AI分析结果表数据
INSERT INTO `ai_analysis_result` (`User_ID`, `Keyword_Imformation`, `Trend_Analysis`, `Task_List`, `Constructive_Suggestions`, `Analysis_Date`) VALUES
(1, '{"keywords": ["用户管理", "权限控制", "任务分配"]}', '{"趋势": "任务完成率呈上升趋势，上周完成率80%"}', '[{"task": "优化权限管理模块", "priority": "高"}, {"task": "完善任务统计功能", "priority": "中"}]', '建议增加任务提醒功能，提高任务按时完成率', '2023-11-29'),
(2, '{"keywords": ["数据库设计", "性能优化", "bug修复"]}', '{"趋势": "开发进度符合预期，测试阶段发现的bug数量在可接受范围"}', '[{"task": "优化数据库查询性能", "priority": "中"}, {"task": "编写性能测试脚本", "priority": "中"}]', '建议对高频访问表添加适当索引，提升系统响应速度', '2023-11-29');
