import request from '@/utils/request'

export function getSubDeptUsers(departmentId) {
  return request({
    url: `/api/departments/${departmentId}/sub-users`,
    method: 'get'
  })
}

export function listSubDepts(departmentId) {
  return request({
    url: `/api/departments/${departmentId}/sub-departments`,
    method: 'get'
  })
}

export function createDept(data) {
  return request({
    url: '/api/departments',
    method: 'post',
    data
  })
}

export function updateDept(departmentId, data) {
  return request({
    url: `/api/departments/${departmentId}`,
    method: 'put',
    data
  })
}

export function deleteDept(departmentId) {
  return request({
    url: `/api/departments/${departmentId}`,
    method: 'delete'
  })
}
