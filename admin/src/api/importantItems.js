import request from '@/utils/request'

// 获取重要事项列表 - 修改后始终返回公司重要事项
export function getImportantItems() {
  return request({
    url: '/api/items',
    method: 'get',
    params: { isCompany: 1 }  // 固定为1，表示只获取公司重要事项
  })
}

// 调整事项顺序
export function adjustItemOrder(displayOrders) {
  return request({
    url: '/api/items',
    method: 'patch',
    data: { displayOrders }
  })
}

// 添加重要事项
export function addItem(itemData) {
  return request({
    url: '/api/items',
    method: 'post',
    data: itemData
  })
}

// 更新重要事项
export function updateItem(itemId, itemData) {
  return request({
    url: `/api/items/${itemId}`,
    method: 'put',
    data: itemData
  })
}

// 删除重要事项
export function deleteItem(itemId) {
  return request({
    url: `/api/items/${itemId}`,
    method: 'delete'
  })
}