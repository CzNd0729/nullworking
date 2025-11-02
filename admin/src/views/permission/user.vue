<template>
  <div class="app-container">
    <div class="filter-container">
      <el-button 
        class="filter-item" 
        type="primary" 
        icon="el-icon-plus" 
        @click="handleCreate"
      >
        添加用户
      </el-button>
    </div>

    <el-table
      :key="tableKey"
      v-loading="listLoading"
      :data="list"
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
      <el-table-column label="用户名" prop="userName" align="center">
        <template slot-scope="{row}">
          <span>{{ row.userName }}</span>
        </template>
      </el-table-column>
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
          <el-button type="primary" size="mini" @click="handleUpdate(row)">
            编辑
          </el-button>
          <el-button size="mini" type="danger" @click="handleDelete(row,$index)">
            删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog :title="textMap[dialogStatus]" :visible.sync="dialogFormVisible" width="500px">
      <el-form 
        ref="dataForm" 
        :rules="rules" 
        :model="temp" 
        label-position="left" 
        label-width="100px"
      >
        <el-form-item label="用户名" prop="userName">
          <el-input v-model="temp.userName" />
        </el-form-item>
        <el-form-item label="密码" prop="password" v-if="dialogStatus === 'create'">
          <el-input v-model="temp.password" type="password" />
        </el-form-item>
        <el-form-item label="真实姓名" prop="realName">
          <el-input v-model="temp.realName" />
        </el-form-item>
        <el-form-item label="角色" prop="roleId">
          <el-select v-model="temp.roleId" placeholder="请选择角色" clearable style="width: 100%">
            <el-option
              v-for="role in rolesList"
              :key="role.roleId"
              :label="role.roleName"
              :value="role.roleId"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="部门" prop="deptId">
          <el-select v-model="temp.deptId" placeholder="请选择部门" clearable style="width: 100%">
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
import { listSubDepts } from '@/api/department'

export default {
  name: 'UserManagement',
  data() {
    return {
      tableKey: 0,
      list: null,
      listLoading: true,
      rolesList: [],
      departmentsList: [],
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
        phone: [{ required: true, message: '电话号码不能为空', trigger: 'blur' }]
      }
    }
  },
  async created() {
    // Load roles and departments first, then load users
    await Promise.all([
      this.loadRoles(),
      this.loadDepartments()
    ])
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
          this.list = response.data.users.map(user => {
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
        } else {
          this.list = []
        }
        this.listLoading = false
      }).catch(() => {
        this.listLoading = false
      })
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
        // Try to get all departments recursively
        let allDepts = []
        const visitedDeptIds = new Set()
        
        const fetchDepartments = async (deptId) => {
          if (visitedDeptIds.has(deptId)) {
            return
          }
          visitedDeptIds.add(deptId)
          
          try {
            const response = await listSubDepts(deptId)
            if (response.data && response.data.depts) {
              const subDepts = response.data.depts
              allDepts = allDepts.concat(subDepts)
              
              for (const subDept of subDepts) {
                const subDeptId = subDept.deptId || subDept.departmentId
                if (subDeptId && !visitedDeptIds.has(subDeptId)) {
                  await fetchDepartments(subDeptId)
                }
              }
            }
          } catch (error) {
            // Skip if department doesn't exist
          }
        }
        
        // Try common root department IDs
        for (let rootId = 0; rootId <= 10; rootId++) {
          try {
            await fetchDepartments(rootId)
          } catch (error) {
            continue
          }
        }
        
        this.departmentsList = allDepts.map(dept => ({
          departmentId: dept.deptId || dept.departmentId,
          deptName: dept.deptName || dept.departmentName,
          deptDescription: dept.deptDescription || dept.description,
          parentDept: dept.parentDept !== undefined ? dept.parentDept : (dept.parentId !== undefined ? dept.parentId : null)
        }))
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
    }
  }
}
</script>

<style scoped>

</style>

