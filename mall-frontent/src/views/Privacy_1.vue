<template>
  <div class="page-container">
    <div class="page-header">
      <h1 class="page-title">隐私政策</h1>
      <p class="page-subtitle">信息收集 · 数据使用 · 安全保护</p>
    </div>
    
    <div class="content-wrapper">
      <div class="text-content">
        <h3>1. 信息收集</h3>
        <p>在您使用 CocoBrite 官方网站及相关服务时，我们可能会收集您的个人信息，包括但不限于姓名、联系方式、收货地址等。这些信息主要用于订单处理、物流配送及售后服务。</p>
        
        <h3>2. 信息使用</h3>
        <p>我们承诺严格遵守法律法规及本隐私政策的规定使用您的个人信息。未经您同意，我们不会向第三方出售、出租或以其他方式披露您的个人信息。</p>
        
        <h3>3. 信息安全</h3>
        <p>我们采取合理的技术手段和管理措施来保护您的个人信息安全，防止信息泄露、损毁或丢失。我们会定期审查信息安全策略，以确保您的数据安全。</p>
        
        <h3>4. Cookie的使用</h3>
        <p>为确保网站正常运行，我们会在您的计算机或移动设备上存储名为 Cookie 的小数据文件。Cookie 通常包含标识符、站点名称以及一些号码和字符。</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page-container {
  padding: 4rem 2rem;
  max-width: 1000px;
  margin: 0 auto;
}

.page-header {
  text-align: center;
  margin-bottom: 3rem;
}

.page-title {
  font-size: 2.5rem;
  margin-bottom: 0.5rem;
  letter-spacing: 0.1em;
}

.page-subtitle {
  color: var(--text-secondary);
  font-family: var(--font-display);
  letter-spacing: 0.2em;
  font-size: 0.9rem;
}

.content-wrapper {
  background-color: var(--surface-color);
  padding: 3rem;
  border: 1px solid var(--border-color);
}

.text-content h3 {
  font-family: var(--font-serif);
  font-size: 1.2rem;
  margin: 2rem 0 1rem 0;
  color: var(--text-primary);
}

.text-content h3:first-child {
  margin-top: 0;
}

.text-content p {
  color: var(--text-secondary);
  line-height: 1.8;
  margin-bottom: 1rem;
  text-align: justify;
}

@media (max-width: 768px) {
  .page-container {
    padding: 6rem 1.5rem 2rem 1.5rem;
  }
  
  .content-wrapper {
    padding: 1.5rem;
  }
  
  .page-title {
    font-size: 2rem;
  }
}
</style>
