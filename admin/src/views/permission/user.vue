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
      <el-table-column label="电话号码" prop="phone" align="center">
        <template slot-scope="{row}">
          <span>{{ row.phone || row.phoneNumber || '-' }}</span>
        </template>
      </el-table-column>
      <el-table-column label="邮箱" prop="email" align="center">
        <template slot-scope="{row}">
          <span>{{ row.email || '-' }}</span>
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
        <el-form-item label="角色ID" prop="roleId">
          <el-input-number v-model="temp.roleId" :min="0" />
        </el-form-item>
        <el-form-item label="部门ID" prop="deptId">
          <el-input-number v-model="temp.deptId" :min="0" />
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

export default {
  name: 'UserManagement',
  data() {
    return {
      tableKey: 0,
      list: null,
      listLoading: true,
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
  created() {
    this.getList()
  },
  methods: {
    getList() {
      this.listLoading = true
      listUsers().then(response => {
        if (response.data && response.data.users) {
          this.list = response.data.users
        } else {
          this.list = []
        }
        this.listLoading = false
      }).catch(() => {
        this.listLoading = false
      })
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
      this.temp.phone = row.phone || row.phoneNumber
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

