<template>
  <div class="dashboard-container">
    <div class="welcome-section">
      <h1 class="welcome-title">欢迎使用无隙工作管理系统</h1>
      <p class="welcome-message">您好，{{ name }}！祝您工作愉快！</p>
      <div class="current-time">
        <i class="el-icon-time"></i>
        <span>{{ currentTime }}</span>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'

export default {
  name: 'Dashboard',
  data() {
    return {
      currentTime: '',
      timeInterval: null
    }
  },
  computed: {
    ...mapGetters([
      'name'
    ])
  },
  mounted() {
    this.updateTime()
    this.timeInterval = setInterval(this.updateTime, 1000)
  },
  beforeDestroy() {
    if (this.timeInterval) {
      clearInterval(this.timeInterval)
    }
  },
  methods: {
    updateTime() {
      const now = new Date()
      const options = {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        weekday: 'long',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      }
      this.currentTime = now.toLocaleDateString('zh-CN', options)
    }
  }
}
</script>

<style lang="scss" scoped>
.dashboard-container {
  padding: 40px;
  background-color: #f5f5f5;
  min-height: calc(100vh - 84px);
  display: flex;
  justify-content: center;
  align-items: center;
}

.welcome-section {
  text-align: center;
  background: white;
  padding: 60px;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  max-width: 600px;
  width: 100%;

  .welcome-title {
    font-size: 32px;
    font-weight: 600;
    color: #333;
    margin: 0 0 20px 0;
    line-height: 1.2;
  }

  .welcome-message {
    font-size: 18px;
    color: #666;
    margin: 0 0 30px 0;
  }

  .current-time {
    display: inline-flex;
    align-items: center;
    font-size: 16px;
    color: #999;
    padding: 10px 20px;
    background: #f8f9fa;
    border-radius: 20px;

    i {
      margin-right: 8px;
      font-size: 16px;
    }
  }
}

// 响应式设计
@media (max-width: 768px) {
  .dashboard-container {
    padding: 20px;
  }

  .welcome-section {
    padding: 40px 30px;

    .welcome-title {
      font-size: 28px;
    }

    .welcome-message {
      font-size: 16px;
    }
  }
}
</style>
