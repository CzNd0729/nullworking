import request from '@/utils/request'

// 获取Dashboard统计数据
export function getDashboardStats() {
  return request({
    url: '/api/dashboard/stats',
    method: 'get'
  })
}

// 获取用户统计信息
export function getUserStats() {
  return request({
    url: '/api/dashboard/stats/users',
    method: 'get'
  })
}

// 获取部门统计信息
export function getDepartmentStats() {
  return request({
    url: '/api/dashboard/stats/departments',
    method: 'get'
  })
}

// 获取角色统计信息
export function getRoleStats() {
  return request({
    url: '/api/dashboard/stats/roles',
    method: 'get'
  })
}

// 获取重要事项统计信息
export function getItemStats() {
  return request({
    url: '/api/dashboard/stats/items',
    method: 'get'
  })
}