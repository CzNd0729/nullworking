import Vue from 'vue'
import Router from 'vue-router'

Vue.use(Router)

export const constantRoutes = [
  {
    path: '/login',
    component: () => import('@/views/login/index'),
    hidden: true
  },
  {
    path: '/link/:codeInfo',
    component: () => import('@/views/OpenInstall'),
    hidden: true
  },
  {
    path: '/',
    redirect: '/dashboard'
  },
  {
    path: '/404',
    component: () => import('@/views/404'),
    hidden: true
  },
  {
    path: '/dashboard',
    component: () => import('@/layout'),
    children: [
      {
        path: '',
        component: () => import('@/views/dashboard/index.vue'),
        name: 'Dashboard',
        meta: { title: '首页', icon: 'dashboard' }
      }
    ]
  },
  {
    path: '/important-items',
    component: () => import('@/layout'),
    children: [
      {
        path: '',
        component: () => import('@/views/importantItems/index.vue'),
        name: 'ImportantItems',
        meta: { title: '重要事项', icon: 'todo' }
      }
    ]
  },
  {
    path: '/permission',
    component: () => import('@/layout'),
    redirect: '/permission/user',
    name: 'Permission',
    meta: { title: '权限管理', icon: 'key' },
    children: [
      {
        path: 'user',
        component: () => import('@/views/permission/user.vue'),
        name: 'UserManagement',
        meta: { title: '用户管理', icon: 'user' }
      },
      {
        path: 'department',
        component: () => import('@/views/permission/department.vue'),
        name: 'DepartmentManagement',
        meta: { title: '部门管理', icon: 'tree' }
      },
      {
        path: 'role',
        component: () => import('@/views/permission/role.vue'),
        name: 'RoleManagement',
        meta: { title: '角色管理', icon: 'role' }
      }
    ]
  },
  // 404 page must be placed at the end !!!
  { path: '*', redirect: '/404', hidden: true }
]

const createRouter = () => new Router({
  mode: 'history', // 开启 history 模式
  scrollBehavior: () => ({ y: 0 }),
  routes: constantRoutes
})

const router = createRouter()

export default router
