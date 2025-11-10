<template>
  <div class="app-container">
    <div class="filter-container">
      <el-button 
        class="filter-item" 
        type="primary" 
        icon="el-icon-plus" 
        @click="handleCreate"
      >
        添加角色
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
      <el-table-column label="ID" prop="roleId" align="center" width="80">
        <template slot-scope="{row}">
          <span>{{ row.roleId }}</span>
        </template>
      </el-table-column>
      <el-table-column label="角色名称" prop="roleName" align="center">
        <template slot-scope="{row}">
          <span>{{ row.roleName }}</span>
        </template>
      </el-table-column>
      <el-table-column label="描述" prop="description" align="center">
        <template slot-scope="{row}">
          <span>{{ row.description || row.roleDescription }}</span>
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
      <el-form ref="dataForm" :rules="rules" :model="temp" label-position="left" label-width="100px">
        <el-form-item label="角色名称" prop="roleName">
          <el-input v-model="temp.roleName" placeholder="请输入角色名称" />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input v-model="temp.description" type="textarea" :rows="3" placeholder="请输入角色描述" />
        </el-form-item>
        <el-form-item label="权限" prop="permissions">
          <el-checkbox-group v-model="selectedPermissions">
            <el-checkbox v-for="permission in permissionsList" :key="permission.permissionId" :label="permission.permissionName">{{ permission.permissionDescription }}</el-checkbox>
          </el-checkbox-group>
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
import { listRoles, createRole, updateRole, deleteRole, listPermissions } from '@/api/role'

export default {
  name: 'RoleManagement',
  data() {
    return {
      tableKey: 0,
      list: null,
      listLoading: true,
      temp: {
        roleId: undefined,
        roleName: '',
        description: ''
      },
      permissionsList: [],
      selectedPermissions: [],
      dialogFormVisible: false,
      dialogStatus: '',
      textMap: {
        update: '编辑角色',
        create: '添加角色'
      },
      rules: {
        roleName: [{ required: true, message: '角色名称不能为空', trigger: 'blur' }]
      }
    }
  },
  created() {
    this.getList()
  },
  methods: {
    getList() {
      this.listLoading = true
      listRoles().then(response => {
        if (response.data && response.data.roles) {
          // Map roleDescription to description for consistency
          this.list = response.data.roles.map(role => ({
            ...role,
            description: role.description || role.roleDescription
          }))
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
        roleId: undefined,
        roleName: '',
        description: ''
      }
    },
    handleCreate() {
      this.resetTemp()
      this.dialogStatus = 'create'
      this.dialogFormVisible = true
      this.$nextTick(() => {
        this.$refs['dataForm'].clearValidate()
      })
      this.getPermissionsList()
    },
    createData() {
      this.$refs['dataForm'].validate((valid) => {
        if (valid) {
          const tempData = {
            roleName: this.temp.roleName,
            roleDescription: this.temp.description || '',
            permissionIds: this.selectedPermissions.map(name => {
              const permission = this.permissionsList.find(p => p.permissionName === name);
              return permission ? permission.permissionId : null;
            }).filter(id => id !== null) // Filter out any nulls if a permission name isn't found
          }
          createRole(tempData).then(() => {
            this.dialogFormVisible = false
            this.$message.success('添加角色成功')
            this.getList()
          }).catch(error => {
            console.error("Error creating role:", error)
            this.$message.error(error.response?.data?.message || '添加角色失败')
          })
        }
      })
    },
    handleUpdate(row) {
      const latestRole = this.list.find(r => r.roleId === row.roleId) || row;
      this.temp = Object.assign({}, latestRole);

      if (latestRole.roleDescription && !latestRole.description) {
        this.temp.description = latestRole.roleDescription;
      }

      const rolePermissionIds = latestRole.permissionIds || [];
      this.selectedPermissions = this.permissionsList
        .filter(permission => rolePermissionIds.includes(permission.permissionId))
        .map(permission => permission.permissionName);

      this.dialogStatus = 'update';
      this.dialogFormVisible = true;
      this.$nextTick(() => {
        this.$refs['dataForm'].clearValidate();
      });
      this.getPermissionsList();
    },
    updateData() {
      this.$refs['dataForm'].validate((valid) => {
        if (valid) {
          const tempData = {
            roleId: this.temp.roleId,
            roleName: this.temp.roleName,
            roleDescription: this.temp.description,
            permissionIds: this.selectedPermissions.map(name => {
              const permission = this.permissionsList.find(p => p.permissionName === name);
              return permission ? permission.permissionId : null;
            }).filter(id => id !== null) // Filter out any nulls if a permission name isn't found
          }
          updateRole(tempData.roleId, tempData).then(() => {
            this.dialogFormVisible = false
            this.$message.success('更新角色成功')
            // Find the updated role in the list and update its properties
            const index = this.list.findIndex(v => v.roleId === tempData.roleId)
            if (index !== -1) {
              this.list.splice(index, 1, { ...tempData, permissionIds: tempData.permissionIds })
            }
            // No need to call getList() as the list is updated directly
          }).catch(error => {
            console.error("Error updating role:", error)
            this.$message.error(error.response?.data?.message || '更新角色失败')
          })
        }
      })
    },
    handleDelete(row, index) {
      this.$confirm('确定删除该角色吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        deleteRole(row.roleId).then(() => {
          this.list.splice(index, 1)
          this.$message.success('删除成功')
        }).catch(error => {
          console.error("Error deleting role:", error)
          this.$message.error(error.response?.data?.message || '删除失败')
        })
      }).catch(() => {
        this.$message.info('已取消删除')
      })
    },
    getPermissionsList() {
      listPermissions().then(response => {
        if (response.data && response.data.permissions) {
          this.permissionsList = response.data.permissions
        } else {
          this.permissionsList = []
        }
      }).catch(error => {
        console.error("Error fetching permissions:", error)
        this.$message.error('获取权限列表失败')
      })
    }
  }
}
</script>

<style scoped>

</style>
