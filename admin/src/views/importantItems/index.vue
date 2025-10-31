<template>
  <div class="app-container">
    <div class="filter-container">
      <el-button 
        class="filter-item" 
        style="margin-left: 10px;" 
        type="primary" 
        icon="el-icon-plus" 
        @click="handleCreate"
      >
        添加公司十大事项
      </el-button>
    </div>

    <el-card class="box-card">
      <div slot="header" class="clearfix">
        <span>公司十大事项列表</span>
        <el-button 
          v-if="list.length > 0"
          style="float: right; padding: 3px 0" 
          type="text" 
          @click="saveOrder"
          :loading="orderLoading"
        >
          保存排序
        </el-button>
      </div>
      
      <draggable 
        v-model="list" 
        v-bind="dragOptions" 
        @start="drag = true" 
        @end="drag = false"
      >
        <transition-group type="transition" :name="!drag ? 'flip-list' : null">
          <div 
            v-for="(item, index) in list" 
            :key="item.itemId" 
            class="list-item"
          >
            <div class="item-content">
              <div class="item-order">{{ index + 1 }}</div>
              <div class="item-info">
                <div class="item-title">{{ item.title }}</div>
                <div class="item-content-text">{{ item.content }}</div>
              </div>
              <div class="item-actions">
                <el-button type="primary" size="mini" @click="handleUpdate(item)">
                  编辑
                </el-button>
                <el-button type="danger" size="mini" @click="handleDelete(item)">
                  删除
                </el-button>
              </div>
            </div>
          </div>
        </transition-group>
      </draggable>
      
      <div v-if="list.length === 0" class="empty-text">
        暂无公司十大事项
      </div>
    </el-card>

    <!-- 添加/编辑对话框 -->
    <el-dialog 
      :title="textMap[dialogStatus]" 
      :visible.sync="dialogFormVisible"
      width="500px"
    >
      <el-form 
        ref="dataForm" 
        :rules="rules" 
        :model="temp" 
        label-position="left" 
        label-width="80px"
      >
        <el-form-item label="标题" prop="title">
          <el-input v-model="temp.title" placeholder="请输入公司十大事项标题" />
        </el-form-item>
        <el-form-item label="内容" prop="content">
          <el-input 
            type="textarea" 
            :rows="3" 
            v-model="temp.content" 
            placeholder="请输入公司十大事项内容"
          />
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="dialogFormVisible = false">取消</el-button>
        <el-button 
          type="primary" 
          @click="dialogStatus === 'create' ? createData() : updateData()"
        >
          确认
        </el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import draggable from 'vuedraggable'
import { 
  getImportantItems, 
  adjustItemOrder, 
  addItem, 
  updateItem, 
  deleteItem 
} from '@/api/importantItems'

export default {
  name: 'CompanyTopTenItems',
  components: { draggable },
  data() {
    return {
      list: [],
      listQuery: {
        isCompany: 0
      },
      drag: false,
      orderLoading: false,
      dialogFormVisible: false,
      dialogStatus: '',
      textMap: {
        update: '编辑公司十大事项',
        create: '添加公司十大事项'
      },
      temp: {
        itemId: undefined,
        title: '',
        content: ''
      },
      rules: {
        title: [{ required: true, message: '标题不能为空', trigger: 'blur' }],
        content: [{ required: true, message: '内容不能为空', trigger: 'blur' }]
      }
    }
  },
  computed: {
    dragOptions() {
      return {
        animation: 200,
        group: "description",
        disabled: false,
        ghostClass: "ghost"
      }
    }
  },
  created() {
    this.getList()
  },
  methods: {
    async getList() {
      try {
        const response = await getImportantItems(this.listQuery.isCompany)
        if (response.code === 200) {
          this.list = response.data.items || []
        }
      } catch (error) {
        console.error('获取公司十大事项列表失败:', error)
      }
    },
    handleFilter() {
      this.getList()
    },
    handleCreate() {
      this.resetTemp()
      this.dialogStatus = 'create'
      this.dialogFormVisible = true
      this.$nextTick(() => {
        this.$refs['dataForm'].clearValidate()
      })
    },
    handleUpdate(item) {
      this.temp = Object.assign({}, item)
      this.dialogStatus = 'update'
      this.dialogFormVisible = true
      this.$nextTick(() => {
        this.$refs['dataForm'].clearValidate()
      })
    },
    async saveOrder() {
      this.orderLoading = true
      try {
        const displayOrders = this.list.map(item => item.itemId)
        const response = await adjustItemOrder(displayOrders)
        if (response.code === 200) {
          this.$message.success('顺序调整成功')
        } else {
          this.$message.error(response.message || '顺序调整失败')
        }
      } catch (error) {
        console.error('调整公司十大事项顺序失败:', error)
        this.$message.error('顺序调整失败')
      }
      this.orderLoading = false
    },
    async createData() {
      this.$refs['dataForm'].validate(async (valid) => {
        if (valid) {
          try {
            const response = await addItem({
              title: this.temp.title,
              content: this.temp.content
            })
            if (response.code === 200) {
              this.dialogFormVisible = false
              this.$message.success('添加公司十大事项成功')
              this.getList()
            } else {
              this.$message.error(response.message || '添加公司十大事项失败')
            }
          } catch (error) {
            console.error('添加公司十大事项失败:', error)
            this.$message.error('添加失败')
          }
        }
      })
    },
    async updateData() {
      this.$refs['dataForm'].validate(async (valid) => {
        if (valid) {
          try {
            const response = await updateItem(this.temp.itemId, {
              title: this.temp.title,
              content: this.temp.content
            })
            if (response.code === 200) {
              this.dialogFormVisible = false
              this.$message.success('更新公司十大事项成功')
              this.getList()
            } else {
              this.$message.error(response.message || '更新公司十大事项失败')
            }
          } catch (error) {
            console.error('更新公司十大事项失败:', error)
            this.$message.error('更新失败')
          }
        }
      })
    },
    handleDelete(item) {
      this.$confirm('确定删除该公司十大事项吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(async () => {
        try {
          const response = await deleteItem(item.itemId)
          if (response.code === 200) {
            this.$message.success('删除公司十大事项成功')
            this.getList()
          } else {
            this.$message.error(response.message || '删除公司十大事项失败')
          }
        } catch (error) {
          console.error('删除公司十大事项失败:', error)
          this.$message.error('删除失败')
        }
      })
    },
    resetTemp() {
      this.temp = {
        itemId: undefined,
        title: '',
        content: ''
      }
    }
  }
}
</script>

<style scoped>
.list-item {
  cursor: move;
  margin-bottom: 10px;
  padding: 15px;
  border: 1px solid #e6e6e6;
  border-radius: 4px;
  background: #f8f9fa;
  transition: all 0.3s;
}

.list-item:hover {
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.item-content {
  display: flex;
  align-items: center;
}

.item-order {
  width: 40px;
  height: 40px;
  line-height: 40px;
  text-align: center;
  background: #409EFF;
  color: white;
  border-radius: 50%;
  font-weight: bold;
  margin-right: 15px;
}

.item-info {
  flex: 1;
}

.item-title {
  font-size: 16px;
  font-weight: bold;
  margin-bottom: 5px;
}

.item-content-text {
  color: #666;
  font-size: 14px;
}

.item-actions {
  min-width: 120px;
}

.empty-text {
  text-align: center;
  color: #999;
  padding: 40px 0;
}

.flip-list-move {
  transition: transform 0.5s;
}

.ghost {
  opacity: 0.5;
  background: #c8ebfb;
}
</style>