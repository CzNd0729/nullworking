<template>
  <div class="app-container">
    <div class="filter-container">
      <el-button 
        class="filter-item" 
        type="primary" 
        icon="el-icon-plus" 
        @click="handleCreate"
      >
        添加部门
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
      <el-table-column label="ID" prop="departmentId" align="center" width="80">
        <template slot-scope="{row}">
          <span>{{ row.departmentId }}</span>
        </template>
      </el-table-column>
      <el-table-column label="部门名称" prop="deptName" align="center">
        <template slot-scope="{row}">
          <span>{{ row.deptName || row.departmentName }}</span>
        </template>
      </el-table-column>
      <el-table-column label="描述" prop="deptDescription" align="center">
        <template slot-scope="{row}">
          <span>{{ row.deptDescription || row.description }}</span>
        </template>
      </el-table-column>
      <el-table-column label="父部门ID" prop="parentDept" align="center">
        <template slot-scope="{row}">
          <span>{{ row.parentDept !== null && row.parentDept !== undefined ? row.parentDept : (row.parentId || '') }}</span>
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
      <el-form ref="dataForm" :rules="rules" :model="temp" label-position="left" label-width="120px">
        <el-form-item label="部门名称" prop="deptName">
          <el-input v-model="temp.deptName" placeholder="请输入部门名称" />
        </el-form-item>
        <el-form-item label="描述" prop="deptDescription">
          <el-input v-model="temp.deptDescription" type="textarea" :rows="3" placeholder="请输入部门描述" />
        </el-form-item>
        <el-form-item label="父部门" prop="parentDept">
          <el-select v-model="temp.parentDept" placeholder="请选择父部门，留空为根部门" clearable style="width: 100%">
            <el-option
              v-for="dept in departmentsList"
              :key="dept.departmentId || dept.deptId"
              :label="dept.deptName || dept.departmentName"
              :value="dept.departmentId || dept.deptId"
              :disabled="dialogStatus === 'update' && dept.departmentId === temp.departmentId"
            />
          </el-select>
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
import { listSubDepts, createDept, updateDept, deleteDept } from '@/api/department'

export default {
  name: 'DepartmentManagement',
  data() {
    return {
      tableKey: 0,
      list: null,
      listLoading: true,
      temp: {
        departmentId: undefined,
        deptName: '',
        deptDescription: '',
        parentDept: null
      },
      departmentsList: [],
      dialogFormVisible: false,
      dialogStatus: '',
      textMap: {
        update: '编辑部门',
        create: '添加部门'
      },
      rules: {
        deptName: [{ required: true, message: '部门名称不能为空', trigger: 'blur' }]
      }
    }
  },
  async created() {
    // Load departments for dropdown first
    await this.loadAllDepartments()
    this.getList()
  },
  methods: {
    async getList() {
      this.listLoading = true
      try {
        let allDepts = []
        const visitedDeptIds = new Set()
        
        // Recursive function to fetch all departments starting from a root department
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
              
              // Recursively fetch sub-departments
              for (const subDept of subDepts) {
                const subDeptId = subDept.deptId || subDept.departmentId
                if (subDeptId && !visitedDeptIds.has(subDeptId)) {
                  await fetchDepartments(subDeptId)
                }
              }
            }
          } catch (error) {
            // Department doesn't exist, skip silently
          }
        }
        
        // Strategy 1: Try common root department IDs first (0-20)
        for (let rootId = 0; rootId <= 20; rootId++) {
          try {
            await fetchDepartments(rootId)
          } catch (error) {
            continue
          }
        }
        
        // Strategy 2: Also try fetching from all departments we've already found
        // This helps catch newly created sub-departments
        const newlyFoundIds = Array.from(visitedDeptIds)
        for (const knownId of newlyFoundIds) {
          try {
            await fetchDepartments(knownId)
          } catch (error) {
            // Skip if error
          }
        }
        
        // Strategy 3: Use the departmentsList (from loadAllDepartments) as starting points
        // This includes all departments we know about, including newly created ones in dropdown
        if (this.departmentsList && this.departmentsList.length > 0) {
          for (const knownDept of this.departmentsList) {
            const knownId = knownDept.departmentId || knownDept.deptId
            if (knownId && !visitedDeptIds.has(knownId)) {
              try {
                await fetchDepartments(knownId)
              } catch (error) {
                // Skip if error
              }
            }
            // Also try the parent department ID from known departments
            const parentId = knownDept.parentDept || knownDept.parentId
            if (parentId && !visitedDeptIds.has(parentId)) {
              try {
                await fetchDepartments(parentId)
              } catch (error) {
                // Skip if error
              }
            }
          }
        }
        
        // Strategy 3b: If we have existing departments in the list, also try their IDs
        // This helps find departments that might have been missed
        if (this.list && this.list.length > 0) {
          for (const existingDept of this.list) {
            const existingId = existingDept.departmentId || existingDept.deptId
            if (existingId && !visitedDeptIds.has(existingId)) {
              try {
                await fetchDepartments(existingId)
              } catch (error) {
                // Skip if error
              }
            }
            // Also try the parent department ID
            const parentId = existingDept.parentDept || existingDept.parentId
            if (parentId && !visitedDeptIds.has(parentId)) {
              try {
                await fetchDepartments(parentId)
              } catch (error) {
                // Skip if error
              }
            }
          }
        }
        
        // Strategy 4: Expand search range if we found departments with high IDs
        if (allDepts.length > 0) {
          const deptIds = allDepts.map(d => (d.deptId || d.departmentId || 0)).filter(id => id > 0)
          if (deptIds.length > 0) {
            const maxId = Math.max(...deptIds)
            // Try a few more IDs beyond the maximum we found (up to 50 more)
            for (let tryId = maxId + 1; tryId <= maxId + 50; tryId++) {
              if (!visitedDeptIds.has(tryId)) {
                try {
                  await fetchDepartments(tryId)
                } catch (error) {
                  // Skip if error
                }
              }
            }
          }
        }
        
        // Normalize field names for display
        this.list = allDepts.map(dept => ({
          departmentId: dept.deptId || dept.departmentId,
          deptName: dept.deptName || dept.departmentName,
          deptDescription: dept.deptDescription || dept.description,
          parentDept: dept.parentDept !== undefined ? dept.parentDept : (dept.parentId !== undefined ? dept.parentId : null)
        }))
        
        // Remove duplicates based on departmentId
        const uniqueMap = new Map()
        this.list.forEach(dept => {
          const id = dept.departmentId
          if (!uniqueMap.has(id)) {
            uniqueMap.set(id, dept)
          }
        })
        this.list = Array.from(uniqueMap.values())
        
        // Sort departments by departmentId in ascending order
        this.list.sort((a, b) => {
          const idA = a.departmentId || 0
          const idB = b.departmentId || 0
          return idA - idB
        })
        
        this.listLoading = false
      } catch (error) {
        console.error("Error loading departments:", error)
        this.list = []
        this.listLoading = false
      }
    },
    async loadAllDepartments() {
      try {
        // Load all departments for the dropdown
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
        console.error('Failed to load departments for dropdown:', error)
        this.departmentsList = []
      }
    },
    resetTemp() {
      this.temp = {
        departmentId: undefined,
        deptName: '',
        deptDescription: '',
        parentDept: null
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
          // Remove departmentId from temp before creating a new department
          const tempData = Object.assign({}, this.temp)
          delete tempData.departmentId
          createDept(tempData).then(async (response) => {
            this.dialogFormVisible = false
            this.$message.success('添加部门成功')
            // Force refresh by clearing the list first, then reloading
            this.list = []
            
            // Refresh the departments list for dropdown first
            await this.loadAllDepartments()
            
            // If we know the parent department ID, try fetching from it first to get the new department
            const parentId = tempData.parentDept
            if (parentId !== null && parentId !== undefined) {
              // Try to fetch sub-departments from parent to get the newly created one
              try {
                const response = await listSubDepts(parentId)
                if (response.data && response.data.depts) {
                  // Found new department, now get full list
                  this.getList()
                  return
                }
              } catch (error) {
                // Continue to full refresh
              }
            }
            
            // Full refresh of the list
            this.getList()
          }).catch(error => {
            console.error("Error creating department:", error)
            this.$message.error(error.response?.data?.message || '添加部门失败')
          })
        }
      })
    },
    handleUpdate(row) {
      this.temp = Object.assign({}, row) // copy obj
      // Map departmentId to deptId if needed, and ensure correct field names
      if (row.departmentId !== undefined) {
        this.temp.departmentId = row.departmentId
      }
      // Map old field names to new ones if they exist
      if (row.departmentName && !row.deptName) {
        this.temp.deptName = row.departmentName
      }
      if (row.description && !row.deptDescription) {
        this.temp.deptDescription = row.description
      }
      if (row.parentId !== undefined && row.parentDept === undefined) {
        this.temp.parentDept = row.parentId
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
          // Prepare update data with correct field names
          const tempData = {
            deptId: this.temp.departmentId,
            deptName: this.temp.deptName,
            deptDescription: this.temp.deptDescription,
            parentDept: this.temp.parentDept
          }
          updateDept(this.temp.departmentId, tempData).then(() => {
            this.dialogFormVisible = false
            this.$message.success('更新部门成功')
            this.getList() // Refresh the list
          }).catch(error => {
            console.error("Error updating department:", error)
            this.$message.error(error.response?.data?.message || '更新部门失败')
          })
        }
      })
    },
    handleDelete(row, index) {
      this.$confirm('确定删除该部门吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        deleteDept(row.departmentId).then(() => {
          this.$message.success('删除部门成功')
          this.getList() // Refresh the list
        }).catch(error => {
          this.$message.error(error.response?.data?.message || '删除部门失败')
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
