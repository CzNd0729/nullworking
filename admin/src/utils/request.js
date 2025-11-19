import axios from 'axios'
import { Message } from 'element-ui'
import store from '@/store'
import { getToken } from '@/utils/auth'

// 创建axios实例
const service = axios.create({
  baseURL:'http://58.87.76.10:8080', // api的base_url
  timeout: 5000 // 请求超时时间
})

// request拦截器 - 添加token到请求头
service.interceptors.request.use(
  config => {
    // 确保token被正确添加到请求头
    const token = getToken() || store.getters.token
    if (token) {
      // 让每个请求携带token
      config.headers['Authorization'] = 'Bearer ' + token
    } else {
      console.warn('No token found for request:', config.url)
    }
    return config
  },
  error => {
    // Do something with request error
    console.error('Request interceptor error:', error)
    return Promise.reject(error)
  }
)

// response拦截器
service.interceptors.response.use(
  response => {
    const res = response.data
    // Backend returns ApiResponse with code field (200 = success, others = error)
    // But HTTP status code is always 200, so we check the code field
    if (res && res.code !== undefined && res.code !== 200) {
      // Create error object with response data for components to handle
      const error = new Error(res.message || '操作失败')
      error.response = {
        status: res.code, // Use backend code as HTTP-like status
        data: res // Include full response data
      }
      return Promise.reject(error)
    } else {
      return res
    }
  },
  error => {
    console.log('err' + error)
    // Extract error message from response
    let errorMessage = error.message
    if (error.response) {
      if (error.response.data) {
        if (error.response.data.message) {
          errorMessage = error.response.data.message
        } else if (typeof error.response.data === 'string') {
          errorMessage = error.response.data
        }
      }
      // Handle HTTP status codes
      if (error.response.status === 401) {
        errorMessage = '未授权，请重新登录'
      } else if (error.response.status === 403) {
        errorMessage = error.response.data?.message || '无权限访问此资源'
      } else if (error.response.status === 404) {
        errorMessage = error.response.data?.message || '资源不存在'
      }
    }
    // Only show message for network errors, not for business logic errors (let components handle those)
    if (!error.response || error.response.status >= 500) {
      Message({
        message: errorMessage,
        type: 'error',
        duration: 5 * 1000
      })
    }
    return Promise.reject(error)
  }
)

export default service