import axios from 'axios'
import { Message } from 'element-ui'
import store from '@/store'
import { getToken } from '@/utils/auth'

// 创建axios实例
const service = axios.create({
  baseURL: process.env.VUE_APP_BASE_API, // api的base_url
  timeout: 5000 // 请求超时时间
})

// request拦截器 - 添加token到请求头
// 我将添加这个请求拦截器
if (service.interceptors.request) {
  service.interceptors.request.use(
    config => {
      if (store.getters.token) {
        // 让每个请求携带token-- ['X-Token']为自定义key 请根据实际情况自行修改
        config.headers['Authorization'] = 'Bearer ' + getToken()
      }
      return config
    },
    error => {
      // Do something with request error
      console.log(error)
      Promise.reject(error)
    }
  )
}

// response拦截器
service.interceptors.response.use(
  response => {
    const res = response.data
    if (res.code !== 200) {
      Message({
        message: res.message || 'Error',
        type: 'error',
        duration: 5 * 1000
      })
      return Promise.reject(new Error(res.message || 'Error'))
    } else {
      return res
    }
  },
  error => {
    console.log('err' + error)
    Message({
      message: error.message,
      type: 'error',
      duration: 5 * 1000
    })
    return Promise.reject(error)
  }
)

export default service