import request from '@/utils/request'

export function listRoles() {
  return request({
    url: '/api/roles',
    method: 'get'
  })
}

export function createRole(data) {
  return request({
    url: '/api/roles',
    method: 'post',
    data
  })
}

export function updateRole(roleId, data) {
  return request({
    url: `/api/roles/${roleId}`,
    method: 'put',
    data
  })
}

export function deleteRole(roleId) {
  return request({
    url: `/api/roles/${roleId}`,
    method: 'delete'
  })
}

export function listPermissions() {
  return request({
    url: '/api/roles/permissions',
    method: 'get'
  })
}