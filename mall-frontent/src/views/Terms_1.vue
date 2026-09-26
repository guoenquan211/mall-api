<template>
  <div class="page-container">
    <div class="page-header">
      <h1 class="page-title">服务条款</h1>
      <p class="page-subtitle">用户协议 · 交易规则 · 售后保障</p>
    </div>
    
    <div class="content-wrapper">
      <div class="text-content">
        <h3>1. 服务内容</h3>
        <p>欢迎使用 CocoBrite（以下简称「本平台」）。本平台为用户提供身体护理、香氛沐浴等商品及相关信息服务。用户在使用本平台服务时，即表示同意遵守本条款的所有规定。化妆品功效宣称以产品销售地的标签、注册或备案要求为准；「美白」等特殊宣称在部分司法辖区受额外监管，请以当地法规与包装说明为准。</p>
        
        <h3>2. 用户义务</h3>
        <p>用户注册时应提供真实、准确的个人资料。用户应妥善保管账号及密码，并对该账号下的所有活动承担责任。用户不得利用本平台从事任何违法或违规活动。</p>
        
        <h3>3. 交易规则</h3>
        <p>商品价格、数量等信息随时可能发生变动，本平台不作特别通知。我们将尽最大努力保证您所浏览商品信息的准确性，但由于互联网技术因素等客观原因存在，网页显示的信息可能会有一定的滞后性或差错。</p>
        
        <h3>4. 知识产权</h3>
        <p>本平台包含的所有文本、图片、音频、视频、软件等内容均受版权法及其他相关法律的保护。未经本平台书面许可，任何单位或个人不得以任何方式使用。</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page-container {
  padding: 4rem 2rem;
  max-width: 1280px;
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
