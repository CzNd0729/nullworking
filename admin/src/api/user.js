import request from '@/utils/request'

export function login(data) {
  return request({
    url: '/api/auth/login',
    method: 'post',
    data
  })
}

export function getInfo(token) {
  return request({
    url: '/api/user/info',
    method: 'get',
    params: { token }
  })
}

export function logout() {
  return request({
    url: '/api/user/logout',
    method: 'post'
  })
}

// 用户管理相关API
export function listUsers() {
  return request({
    url: '/api/users',
    method: 'get'
  })
}

export function createUser(data) {
  return request({
    url: '/api/users',
    method: 'post',
    data
  })
}

export function updateUser(userId, data) {
  return request({
    url: `/api/users/${userId}`,
    method: 'put',
    data
  })
}

export function deleteUser(userId) {
  return request({
    url: `/api/users/${userId}`,
    method: 'delete'
  })
}