package com.nullworking.repository;

import java.util.List;
import java.util.Set;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nullworking.model.User;

@Repository
public interface UserRepository extends JpaRepository<User, Integer> {
	User findByUserName(String userName);
    List<User> findByDepartmentDepartmentIdIn(Set<Integer> departmentIds);
    List<User> findAll();
    List<User> findByUserIdIn(List<Integer> userIds);

    User findByEmail(String email);

    /**
     * 根据用户名和状态查询用户（用于软删除过滤）
     */
    User findByUserNameAndStatus(String userName, Byte status);

    /**
     * 查询指定部门集合下，指定状态的用户
     */
    List<User> findByDepartmentDepartmentIdInAndStatus(Set<Integer> departmentIds, Byte status);

    /**
     * 查询所有指定状态的用户
     */
    List<User> findByStatus(Byte status);
}
