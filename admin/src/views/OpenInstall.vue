<template>
  <div class="open-install-container">
    <div class="card">
      <h2>你的同事向你分享了一份AI分析报告</h2>
      <p>点击下方按钮进入无隙工作查看</p>
      
      <button id="downloadButton" @click="handleDownload">
        立即打开/下载 App
      </button>
    </div>
  </div>
</template>

<script>
export default {
  name: 'OpenInstall',
  data() {
    return {
      openInstallInstance: null
    }
  },
  mounted() {
    this.initOpenInstall()
  },
  methods: {
    initOpenInstall() {
      // 动态加载 OpenInstall 脚本
      const script = document.createElement('script')
      script.type = 'text/javascript'
      script.src = 'https://res.openinstall.com/openinstall-w0h9pp.js'
      script.onload = () => {
        this.setupOpenInstall()
      }
      document.head.appendChild(script)
    },
    setupOpenInstall() {
      /* eslint-disable no-undef */
      // 解析当前 URL 里的参数
      // 针对用户要求的 /link/xxxx 格式，直接取路径最后一部分作为 code
      const code = this.$route.params.codeInfo
      
      const data = {}
      if (code) {
        data.code = code
        console.log("解析到 code 参数: " + data.code)
      }
      
      this.openInstallInstance = new OpenInstall({
        appKey: "w0h9pp",
        onready: function() {
          // 初始化成功后，尝试自动弹出 Scheme 拉起
          this.schemeWakeup()
        }
      }, data)
    },
    handleDownload() {
      if (this.openInstallInstance) {
        this.openInstallInstance.wakeupOrInstall()
      }
    }
  }
}
</script>

<style scoped>
.open-install-container {
  font-family: sans-serif;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100vh;
  margin: 0;
  background-color: #f4f4f9;
}

.card {
  background: white;
  padding: 2rem;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  text-align: center;
}

h2 {
  color: #333;
}

p {
  color: #666;
}

button {
  margin-top: 20px;
  padding: 12px 24px;
  font-size: 16px;
  background-color: #007AFF;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: background 0.3s;
}

button:hover {
  background-color: #0062cc;
}
</style>
