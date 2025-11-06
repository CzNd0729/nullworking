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
    path: '/404',
    component: () => import('@/views/404'),
    hidden: true
  },
  {
    path: '/',
    component: () => import('@/layout'),
    redirect: '/important-items',
    children: [
      {
        path: 'important-items',
        component: () => import('@/views/importantItems/index.vue'),
        name: 'ImportantItems',
        meta: { title: '重要事项管理', icon: 'todo' }
      }
    ]
  },
  {
    path: '/permission',
    component: () => import('@/layout'),
    redirect: 'noRedirect',
    name: 'Permission',
    meta: { title: '权限管理', icon: 'key' },
    alwaysShow: true,
    children: [
      {
        path: 'role',
        component: () => import('@/views/permission/role.vue'),
        name: 'RoleManagement',
        meta: { title: '角色管理', icon: 'role' }
      },
      {
        path: 'department',
        component: () => import('@/views/permission/department.vue'),
        name: 'DepartmentManagement',
        meta: { title: '部门管理', icon: 'house' }
      },
      {
        path: 'user',
        component: () => import('@/views/permission/user.vue'),
        name: 'UserManagement',
        meta: { title: '用户管理', icon: 'user' }
      }
    ]
  },
  // 404 page must be placed at the end !!!
  { path: '*', redirect: '/404', hidden: true }
]

const createRouter = () => new Router({
  scrollBehavior: () => ({ y: 0 }),
  routes: constantRoutes
})

const router = createRouter()

export default router