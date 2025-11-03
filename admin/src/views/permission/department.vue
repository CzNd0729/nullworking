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
      <el-table-column label="" align="center" width="40">
        <template slot-scope="{row}">
          <span v-if="hasChildren[row.departmentId]" class="expand-toggle" @click="toggleRow(row)">
            <i :class="expanded[row.departmentId] ? 'el-icon-arrow-down' : 'el-icon-arrow-right'"></i>
          </span>
          <span v-else style="display:inline-block;width:14px;"></span>
        </template>
      </el-table-column>
      <el-table-column label="ID" prop="departmentId" align="center" width="80">
        <template slot-scope="{row}">
          <span>{{ row.departmentId }}</span>
        </template>
      </el-table-column>
      <el-table-column label="部门名称" prop="deptName" align="left">
        <template slot-scope="{row}">
          <span :style="{ paddingLeft: (row.level ? row.level * 16 : 0) + 'px' }">{{ row.deptName || row.departmentName }}</span>
        </template>
      </el-table-column>
      <el-table-column label="描述" prop="deptDescription" align="center">
        <template slot-scope="{row}">
          <span>{{ row.deptDescription || row.description }}</span>
        </template>
      </el-table-column>
      <!-- 父部门ID可隐藏；若需要显示，可取消注释 -->
      <!--
      <el-table-column label="父部门ID" prop="parentDept" align="center">
        <template slot-scope="{row}">
          <span>{{ row.parentDept !== null && row.parentDept !== undefined ? row.parentDept : (row.parentId || '') }}</span>
        </template>
      </el-table-column>
      -->
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
import { listSubDepts, createDept, updateDept, deleteDept, getDeptTree } from '@/api/department'

export default {
  name: 'DepartmentManagement',
  data() {
    return {
      tableKey: 0,
      list: null, // 可见行
      allRows: [], // 全量扁平（深度优先）
      expanded: {}, // { [id]: boolean }
      hasChildren: {}, // { [id]: boolean }
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
        // 使用后端树接口，然后拍平成深度优先顺序的列表，并记录父子关系
        const resp = await getDeptTree()
        const trees = (resp && resp.data && resp.data.tree) ? resp.data.tree : []

        const flat = []
        const childrenMap = {}
        const dfs = (node, level, parentId) => {
          const row = {
            departmentId: node.deptId,
            deptName: node.deptName,
            deptDescription: node.deptDescription,
            parentDept: parentId || null,
            level: level
          }
          flat.push(row)
          if (parentId) {
            if (!childrenMap[parentId]) childrenMap[parentId] = []
            childrenMap[parentId].push(row.departmentId)
          }
          const children = node.children || []
          for (const child of children) {
            dfs(child, level + 1, row.departmentId)
          }
        }
        for (const root of trees) {
          dfs(root, 0, null)
        }

        // 计算 hasChildren
        const hasChildren = {}
        Object.keys(childrenMap).forEach(pid => {
          hasChildren[pid] = childrenMap[pid] && childrenMap[pid].length > 0
        })

        this.allRows = flat
        this.hasChildren = hasChildren

        // 默认全部折叠（只显示根节点）
        this.expanded = {}
        this.rebuildVisibleList()
        this.listLoading = false
      } catch (error) {
        console.error("Error loading departments:", error)
        this.list = []
        this.listLoading = false
      }
    },
    toggleRow(row) {
      const id = row.departmentId
      this.$set(this.expanded, id, !this.expanded[id])
      this.rebuildVisibleList()
    },
    rebuildVisibleList() {
      // 按 allRows 的顺序筛选：根节点总是可见；其子节点仅当所有祖先都 expanded 才可见
      const visible = []
      const expanded = this.expanded
      const parentMap = {}
      this.allRows.forEach(r => { parentMap[r.departmentId] = r.parentDept || null })

      const isVisible = (row) => {
        let pid = row.parentDept
        while (pid) {
          if (!expanded[pid]) return false
          pid = parentMap[pid]
        }
        return true
      }

      for (const row of this.allRows) {
        if (isVisible(row)) {
          visible.push(row)
        }
      }
      this.list = visible
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
