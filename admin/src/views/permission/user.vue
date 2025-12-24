<template>
  <div class="app-container">
    <div class="filter-container">
      <el-input
        v-model="searchKeyword"
        placeholder="搜索用户（真实姓名、手机号、邮箱）"
        class="filter-item"
        style="width: 300px; margin-right: 10px;"
        clearable
        prefix-icon="el-icon-search"
        @input="handleSearch"
      />
      <el-button 
        class="filter-item" 
        type="primary" 
        icon="el-icon-plus" 
        @click="handleCreate"
      >
        添加用户
      </el-button>
    </div>

    <div class="user-management-layout">
      <!-- 左侧部门树 -->
      <div class="dept-tree-container">
        <div class="dept-tree-header">
          <span>选择部门</span>
          <el-button 
            type="text" 
            size="mini" 
            @click="toggleAllExpand"
          >
            {{ treeAllExpanded ? '全部折叠' : '全部展开' }}
          </el-button>
        </div>
        <el-tree
          ref="deptTree"
          :data="deptTreeData"
          :props="deptTreeProps"
          node-key="deptId"
          :default-expand-all="false"
          :expand-on-click-node="false"
          :highlight-current="true"
          @node-expand="onNodeExpand"
          @node-collapse="onNodeCollapse"
          @node-click="handleDeptNodeClick"
          class="dept-tree"
        >
          <span class="custom-tree-node" slot-scope="{ node, data }">
            <el-button 
              v-if="data && data.children && data.children.length > 0"
              type="text" 
              size="mini" 
              class="node-toggle-btn"
              @click.stop="toggleNodeExpand(node)"
            >
              <i :class="node.expanded ? 'el-icon-arrow-down' : 'el-icon-arrow-right'"></i>
            </el-button>
            <span 
              v-else
              class="node-toggle-placeholder"
            ></span>
            <span class="node-label" @click.stop="handleDeptNodeClick(data)">{{ node.label }}</span>
          </span>
        </el-tree>
      </div>

      <!-- 右侧用户列表 -->
      <div class="user-table-container">
        <el-table
          :key="tableKey"
          v-loading="listLoading"
          :data="filteredList"
          border
          fit
          highlight-current-row
          style="width: 100%;"
        >
      <el-table-column label="用户ID" prop="userId" align="center" width="80">
        <template slot-scope="{row}">
          <span>{{ row.userId }}</span>
        </template>
      </el-table-column>
      <!-- 移除用户名列 -->
      <el-table-column label="真实姓名" prop="realName" align="center">
        <template slot-scope="{row}">
          <span>{{ row.realName }}</span>
        </template>
      </el-table-column>
      <el-table-column label="角色" prop="roleName" align="center">
        <template slot-scope="{row}">
          <span>{{ row.roleName || '未分配' }}</span>
        </template>
      </el-table-column>
      <el-table-column label="部门" prop="deptName" align="center">
        <template slot-scope="{row}">
          <span>{{ row.deptName || '未分配' }}</span>
        </template>
      </el-table-column>
      <el-table-column label="电话号码" prop="phoneNumber" align="center">
        <template slot-scope="{row}">
          <span>{{ row.phoneNumber || row.phone || '-' }}</span>
        </template>
      </el-table-column>
      <el-table-column label="邮箱" prop="email" align="center">
        <template slot-scope="{row}">
          <span>{{ row.email ? row.email : '-' }}</span>
        </template>
      </el-table-column>
      <el-table-column label="操作" align="center" width="230" class-name="small-padding fixed-width">
        <template slot-scope="{row,$index}">
          <span v-if="row.userId === 0" style="color: #909399; font-size: 12px;">
            系统默认角色，不可编辑
          </span>
          <template v-else>
            <el-button type="primary" size="mini" @click="handleUpdate(row)">
              编辑
            </el-button>
            <el-button size="mini" type="danger" @click="handleDelete(row,$index)">
              删除
            </el-button>
          </template>
        </template>
      </el-table-column>
        </el-table>
      </div>
    </div>

    <el-dialog :title="textMap[dialogStatus]" :visible.sync="dialogFormVisible" width="500px">
      <el-form 
        ref="dataForm" 
        :rules="rules" 
        :model="temp" 
        label-position="left" 
        label-width="100px"
      >
        <el-form-item label="用户名" prop="userName">
          <el-input v-model="temp.userName" :disabled="dialogStatus === 'update'" />
        </el-form-item>
        <el-form-item label="密码" prop="password" v-if="dialogStatus === 'create'">
          <el-input v-model="temp.password" type="password" />
        </el-form-item>
        <el-form-item label="真实姓名" prop="realName">
          <el-input v-model="temp.realName" />
        </el-form-item>
        <el-form-item label="角色" prop="roleId">
          <el-select v-model="temp.roleId" placeholder="请选择角色" :clearable="false" style="width: 100%">
            <el-option
              v-for="role in rolesList"
              :key="role.roleId"
              :label="role.roleName"
              :value="role.roleId"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="部门" prop="deptId">
          <el-select v-model="temp.deptId" placeholder="请选择部门" :clearable="false" style="width: 100%">
            <el-option
              v-for="dept in departmentsList"
              :key="dept.departmentId || dept.deptId"
              :label="dept.deptName || dept.departmentName"
              :value="dept.departmentId || dept.deptId"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="电话号码" prop="phone">
          <el-input v-model="temp.phone" />
        </el-form-item>
        <el-form-item label="邮箱" prop="email">
          <el-input v-model="temp.email" type="email" />
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="dialogFormVisible = false">
          取消
        </el-button>
        <el-button type="primary" @click="dialogStatus==='create'?createData():updateData()">
          确认
        </el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { listUsers, createUser, updateUser, deleteUser } from '@/api/user'
import { listRoles } from '@/api/role'
import { listSubDepts, getDeptTree, getSubDeptUsers } from '@/api/department'

export default {
  name: 'UserManagement',
  data() {
    return {
      tableKey: 0,
      list: null,
      allUsersList: [], // 存储所有用户，用于过滤
      listLoading: true,
      rolesList: [],
      departmentsList: [],
      deptTreeData: [], // 部门树数据
      deptTreeProps: {
        children: 'children',
        label: 'deptName'
      },
      treeAllExpanded: false, // 部门树是否全部展开
      selectedDeptId: null, // 当前选中的部门ID
      selectedDeptUserIds: [], // 当前选中部门及其子部门的用户ID列表
      searchKeyword: '', // 搜索关键词
      temp: {
        userId: undefined,
        userName: '',
        password: '',
        realName: '',
        roleId: null,
        deptId: null,
        phone: '',
        email: ''
      },
      dialogFormVisible: false,
      dialogStatus: '',
      textMap: {
        update: '编辑用户',
        create: '添加用户'
      },
      rules: {
        userName: [{ required: true, message: '用户名不能为空', trigger: 'blur' }],
        password: [{ required: true, message: '密码不能为空', trigger: 'blur' }],
        realName: [{ required: true, message: '真实姓名不能为空', trigger: 'blur' }],
        phone: [{ required: true, message: '电话号码不能为空', trigger: 'blur' }],
        email: [
          { required: true, message: '邮箱不能为空', trigger: 'blur' },
          { type: 'email', message: '请输入正确的邮箱格式', trigger: ['blur', 'change'] }
        ],
        roleId: [{ required: true, message: '角色为必选项', trigger: 'change' }],
        deptId: [{ required: true, message: '部门为必选项', trigger: 'change' }]
      }
    }
  },
  computed: {
    // 根据选中的部门和搜索关键词过滤用户列表
    filteredList() {
      let filtered = this.allUsersList
      
      // 先按部门过滤
      if (this.selectedDeptId) {
        // 如果选中了部门，即使该部门没有用户，也返回空列表（而不是显示所有用户）
        if (this.selectedDeptUserIds.length === 0) {
          filtered = []
        } else {
          // 只显示选中部门及其子部门的用户
          filtered = filtered.filter(user => 
            this.selectedDeptUserIds.includes(user.userId)
          )
        }
      }
      
      // 再按搜索关键词过滤
      if (this.searchKeyword && this.searchKeyword.trim()) {
        const keyword = this.searchKeyword.trim().toLowerCase()
        filtered = filtered.filter(user => {
          // 搜索真实姓名
          const realNameMatch = user.realName && 
            user.realName.toLowerCase().includes(keyword)
          // 搜索手机号
          const phoneMatch = (user.phoneNumber || user.phone) && 
            (user.phoneNumber || user.phone).toLowerCase().includes(keyword)
          // 搜索邮箱
          const emailMatch = user.email && 
            user.email.toLowerCase().includes(keyword)
          
          return realNameMatch || phoneMatch || emailMatch
        })
      }
      
      return filtered
    }
  },
  async created() {
    // Load roles and department tree first, then load departments (which depends on tree), then load users
    await Promise.all([
      this.loadRoles(),
      this.loadDeptTree()
    ])
    // 部门列表依赖于部门树，所以要在树加载完成后加载
    await this.loadDepartments()
    this.getList()
  },
  methods: {
    getList() {
      this.listLoading = true
      listUsers().then(response => {
        if (response.data && response.data.users) {
          // Map backend data to frontend format
          // Backend may return userId, realName, roleName, deptName
          // Try to also get userName, phoneNumber, email if available
          // Also try to match roleId and deptId by name
          const mappedUsers = response.data.users.map(user => {
            // Try to find roleId and deptId by matching names
            let roleId = user.roleId
            let deptId = user.deptId
            
            if (!roleId && user.roleName && this.rolesList.length > 0) {
              const role = this.rolesList.find(r => r.roleName === user.roleName)
              if (role) {
                roleId = role.roleId
              }
            }
            
            if (!deptId && user.deptName && this.departmentsList.length > 0) {
              const dept = this.departmentsList.find(d => (d.deptName || d.departmentName) === user.deptName)
              if (dept) {
                deptId = dept.departmentId || dept.deptId
              }
            }
            
            return {
              userId: user.userId,
              userName: user.userName || '',
              realName: user.realName,
              roleName: user.roleName,
              deptName: user.deptName,
              roleId: roleId,
              deptId: deptId,
              phoneNumber: user.phoneNumber || user.phone || '',
              phone: user.phoneNumber || user.phone || '',
              email: user.email || ''
            }
          })
          // 保存所有用户到 allUsersList
          this.allUsersList = mappedUsers
          this.list = mappedUsers
        } else {
          this.allUsersList = []
          this.list = []
        }
        this.listLoading = false
      }).catch(() => {
        this.listLoading = false
      })
    },
    async loadDeptTree() {
      try {
        const response = await getDeptTree()
        if (response.data && response.data.tree) {
          this.deptTreeData = response.data.tree
        } else {
          this.deptTreeData = []
        }
        // 加载后根据实际展开状态更新按钮，并设置节点缩进
        this.$nextTick(() => {
          this.updateTreeAllExpanded()
          this.updateTreeIndent()
        })
      } catch (error) {
        console.error('Failed to load department tree:', error)
        this.deptTreeData = []
      }
    },
    updateTreeIndent() {
      // 遍历所有树节点，根据实际层级设置padding-left
      const tree = this.$refs.deptTree
      if (!tree || !tree.store || !tree.store.nodesMap) return
      
      const nodesMap = tree.store.nodesMap
      Object.keys(nodesMap).forEach(key => {
        const node = nodesMap[key]
        if (node && node.$el) {
          const contentEl = node.$el.querySelector('.el-tree-node__content')
          if (contentEl && node.level !== undefined) {
            // 根据节点层级设置缩进：
            // 根节点(level=0): 0px（让文字从左边开始）
            // 第一层子节点(level=1): 30px（确保文字在父节点文字右侧）
            // 第二层子节点(level=2): 50px
            // 第三层子节点(level=3): 70px
            // 每层增加20px缩进，第一层基础缩进为30px
            const paddingLeft = node.level === 0 ? 0 : 30 + (node.level - 1) * 20
            contentEl.style.paddingLeft = paddingLeft + 'px'
          }
        }
      })
    },
    toggleNodeExpand(node) {
      // 切换单个节点展开/折叠
      if (!node) return
      node.expanded = !node.expanded
      this.$nextTick(() => {
        this.updateTreeAllExpanded()
        this.updateTreeIndent()
      })
    },
    toggleAllExpand() {
      // 全部展开或折叠
      const tree = this.$refs.deptTree
      if (!tree || !tree.store || !tree.store.nodesMap) return
      const expandTo = !this.treeAllExpanded
      const nodesMap = tree.store.nodesMap
      Object.keys(nodesMap).forEach(key => {
        const n = nodesMap[key]
        if (n) n.expanded = expandTo
      })
      this.treeAllExpanded = expandTo
      this.$nextTick(() => {
        this.updateTreeAllExpanded()
        this.updateTreeIndent()
      })
    },
    onNodeExpand() {
      this.updateTreeAllExpanded()
      this.$nextTick(() => this.updateTreeIndent())
    },
    onNodeCollapse() {
      this.updateTreeAllExpanded()
      this.$nextTick(() => this.updateTreeIndent())
    },
    updateTreeAllExpanded() {
      const tree = this.$refs.deptTree
      if (!tree || !tree.store || !tree.store.nodesMap) {
        this.treeAllExpanded = false
        return
      }
      const nodesMap = tree.store.nodesMap
      const expandableNodes = Object.keys(nodesMap)
        .map(k => nodesMap[k])
        .filter(n => Array.isArray(n.childNodes) && n.childNodes.length > 0)
      if (expandableNodes.length === 0) {
        this.treeAllExpanded = false
        return
      }
      const allExpanded = expandableNodes.every(n => n.expanded)
      this.treeAllExpanded = allExpanded
    },
    async handleDeptNodeClick(data) {
      // 当点击部门树节点时，获取该部门及其子部门的用户
      this.selectedDeptId = data.deptId
      this.listLoading = true
      try {
        const response = await getSubDeptUsers(data.deptId)
        if (response.data && response.data.users) {
          // 提取用户ID列表
          this.selectedDeptUserIds = response.data.users.map(user => user.userId)
        } else {
          this.selectedDeptUserIds = []
        }
      } catch (error) {
        console.error('Failed to load department users:', error)
        this.selectedDeptUserIds = []
        this.$message.error('获取部门用户失败')
      } finally {
        this.listLoading = false
      }
    },
    clearDeptFilter() {
      this.selectedDeptId = null
      this.selectedDeptUserIds = []
      // 取消树节点的选中状态
      if (this.$refs.deptTree) {
        this.$refs.deptTree.setCurrentKey(null)
      }
    },
    async loadRoles() {
      try {
        const response = await listRoles()
        if (response.data && response.data.roles) {
          this.rolesList = response.data.roles.map(role => ({
            roleId: role.roleId,
            roleName: role.roleName || role.description || `角色${role.roleId}`
          }))
        }
      } catch (error) {
        console.error('Failed to load roles:', error)
        this.rolesList = []
      }
    },
    async loadDepartments() {
      try {
        // 使用部门树数据来构建扁平的部门列表，避免重复
        // 如果部门树已经加载，直接使用；否则先加载部门树
        if (this.deptTreeData.length === 0) {
          await this.loadDeptTree()
        }
        
        // 从部门树中提取所有部门（递归遍历）
        const allDepts = []
        const visitedDeptIds = new Set()
        
        const extractDepartments = (deptNode) => {
          const deptId = deptNode.deptId
          // 避免重复添加
          if (visitedDeptIds.has(deptId)) {
            return
          }
          visitedDeptIds.add(deptId)
          
          allDepts.push({
            departmentId: deptId,
            deptName: deptNode.deptName,
            deptDescription: deptNode.deptDescription,
            parentDept: deptNode.parentDept
          })
          
          // 递归处理子部门
          if (deptNode.children && deptNode.children.length > 0) {
            deptNode.children.forEach(child => {
              extractDepartments(child)
            })
          }
        }
        
        // 遍历所有根部门
        this.deptTreeData.forEach(rootDept => {
          extractDepartments(rootDept)
        })
        
        // 去重：按部门ID去重，确保没有重复
        const uniqueDeptsMap = new Map()
        allDepts.forEach(dept => {
          if (!uniqueDeptsMap.has(dept.departmentId)) {
            uniqueDeptsMap.set(dept.departmentId, dept)
          }
        })
        
        this.departmentsList = Array.from(uniqueDeptsMap.values())
      } catch (error) {
        console.error('Failed to load departments:', error)
        this.departmentsList = []
      }
    },
    resetTemp() {
      this.temp = {
        userId: undefined,
        userName: '',
        password: '',
        realName: '',
        roleId: null,
        deptId: null,
        phone: '',
        email: ''
      }
    },
    handleCreate() {
      this.resetTemp()
      this.dialogStatus = 'create'
      this.dialogFormVisible = true
      this.$nextTick(() => {
        this.$refs['dataForm'].clearValidate()
      })
    },
    createData() {
      this.$refs['dataForm'].validate((valid) => {
        if (valid) {
          const tempData = {
            userName: this.temp.userName,
            password: this.temp.password,
            realName: this.temp.realName,
            roleId: this.temp.roleId,
            deptId: this.temp.deptId,
            phone: this.temp.phone,
            email: this.temp.email
          }
          createUser(tempData).then(() => {
            this.dialogFormVisible = false
            this.$message.success('添加用户成功')
            this.getList()
          }).catch(error => {
            console.error("Error creating user:", error)
            this.$message.error(error.response?.data?.message || '添加用户失败')
          })
        }
      })
    },
    handleUpdate(row) {
      this.temp = Object.assign({}, row)
      // Map phoneNumber to phone for form
      this.temp.phone = row.phoneNumber || row.phone || ''
      // If roleId or deptId is missing, try to find them by name
      if (!this.temp.roleId && row.roleName) {
        const role = this.rolesList.find(r => r.roleName === row.roleName)
        if (role) {
          this.temp.roleId = role.roleId
        }
      }
      if (!this.temp.deptId && row.deptName) {
        const dept = this.departmentsList.find(d => (d.deptName || d.departmentName) === row.deptName)
        if (dept) {
          this.temp.deptId = dept.departmentId || dept.deptId
        }
      }
      this.dialogStatus = 'update'
      this.dialogFormVisible = true
      this.$nextTick(() => {
        this.$refs['dataForm'].clearValidate()
      })
    },
    updateData() {
      this.$refs['dataForm'].validate((valid) => {
        if (valid) {
          const tempData = {
            userName: this.temp.userName,
            realName: this.temp.realName,
            roleId: this.temp.roleId,
            deptId: this.temp.deptId,
            phoneNumber: this.temp.phone,
            email: this.temp.email
          }
          updateUser(this.temp.userId, tempData).then(() => {
            this.dialogFormVisible = false
            this.$message.success('更新用户成功')
            this.getList()
          }).catch(error => {
            console.error("Error updating user:", error)
            this.$message.error(error.response?.data?.message || '更新用户失败')
          })
        }
      })
    },
    handleDelete(row, index) {
      this.$confirm('确定删除该用户吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        deleteUser(row.userId).then(() => {
          this.$message.success('删除用户成功')
          this.getList()
        }).catch(error => {
          console.error("Error deleting user:", error)
          this.$message.error(error.response?.data?.message || '删除用户失败')
        })
      }).catch(() => {
        this.$message.info('已取消删除')
      })
    },
    handleSearch() {
      // 搜索功能通过computed属性filteredList自动处理
      // 这里可以添加其他搜索相关的逻辑，比如清空搜索时重置等
    }
  }
}
</script>

<style scoped>
.user-management-layout {
  display: flex;
  gap: 20px;
  margin-top: 20px;
}

.dept-tree-container {
  width: 250px;
  min-width: 250px;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  padding: 15px;
  background-color: #fff;
}

.dept-tree-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
  font-weight: 600;
  color: #303133;
}

.dept-tree {
  max-height: calc(100vh - 250px);
  overflow-y: auto;
}

.user-table-container {
  flex: 1;
  min-width: 0;
}

.custom-tree-node {
  flex: 1;
  display: flex;
  align-items: center;
  font-size: 14px;
  padding-right: 8px;
  gap: 6px;
}

.custom-tree-node .node-label {
  flex: 1;
  cursor: pointer;
}

.custom-tree-node .node-toggle-btn {
  padding: 0 4px;
  width: 20px;
  min-width: 20px;
  display: inline-flex;
  justify-content: center;
  align-items: center;
}

.custom-tree-node .node-toggle-placeholder {
  width: 20px;
  min-width: 20px;
  display: inline-block;
}

/* 隐藏 Element UI 树的默认展开箭头，仅保留自定义的箭头 */
.dept-tree ::v-deep .el-tree-node__expand-icon {
  display: none !important;
}
/* 兼容旧版深度选择器写法 */
.dept-tree /deep/ .el-tree-node__expand-icon {
  display: none !important;
}

/* 增加子部门的缩进通过JavaScript动态设置，见updateTreeIndent方法 */
/* 这样可以确保所有节点（包括叶子节点）都能正确应用缩进 */
</style>

