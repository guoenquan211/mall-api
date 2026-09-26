<template>
  <div class="page-container">
    <div class="not-found-content">
      <div class="icon-container">
        <i class="ri-compass-3-line"></i>
      </div>
      <h1 class="title">404</h1>
      <p class="subtitle">抱歉，您访问的页面走丢了</p>
      <router-link to="/" class="home-btn">返回首页</router-link>
    </div>
  </div>
</template>

<style scoped>
.page-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 60vh;
  text-align: center;
}

.not-found-content {
  padding: 3rem;
  background: var(--surface-color);
  border-radius: 12px;
  box-shadow: 0 10px 30px rgba(0,0,0,0.05);
}

.icon-container {
  font-size: 4rem;
  color: var(--primary-color);
  margin-bottom: 1rem;
  opacity: 0.5;
}

.title {
  font-size: 4rem;
  font-family: var(--font-serif);
  color: var(--text-primary);
  margin: 0;
  line-height: 1;
}

.subtitle {
  color: var(--text-secondary);
  margin: 1.5rem 0 2.5rem;
  font-size: 1.1rem;
}

.home-btn {
  display: inline-block;
  padding: 0.8rem 2rem;
  background-color: var(--primary-color);
  color: #fff;
  border-radius: 4px;
  text-decoration: none;
  transition: background-color 0.3s;
}

.home-btn:hover {
  background-color: var(--primary-dark);
}
</style>
