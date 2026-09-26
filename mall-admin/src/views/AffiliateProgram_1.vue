<template>
  <div class="page-container">
    <div class="page-header">
      <h1 class="page-title">分销与邀请</h1>
      <div class="header-actions">
        <button class="btn-secondary" type="button" @click="runUnlock">解锁到期佣金</button>
        <button class="btn-secondary" type="button" @click="runSettle">结算 available 批次</button>
      </div>
    </div>
    <p class="hint">佣金基数以订单「商品实付」为准；确认收货后锁定 {{ form.after_sale_days }} 天无纠纷再解锁；每月 {{ form.settlement_day }} 号可执行上月结算（演示按钮不按月拆分）。</p>

    <div class="card" v-if="loaded">
      <h3>等级名称与升级条件</h3>
      <div class="grid-3">
        <div class="field"><label>货币后缀</label><input v-model="form.currency_suffix" /></div>
        <div class="field"><label>一级名称</label><input v-model="form.level1_name" /></div>
        <div class="field"><label>一级消费满 (P)</label><input type="number" step="0.01" v-model.number="form.level1_spend_threshold" /></div>
        <div class="field"><label>一级任意一单即达标</label>
          <select v-model.number="form.level1_any_order"><option :value="1">是</option><option :value="0">否</option></select>
        </div>
        <div class="field"><label>二级名称</label><input v-model="form.level2_name" /></div>
        <div class="field"><label>二级直推一级人数 ≥</label><input type="number" v-model.number="form.level2_direct_l1_min" /></div>
        <div class="field"><label>二级团队业绩 ≥ (P)</label><input type="number" step="0.01" v-model.number="form.level2_team_pv" /></div>
        <div class="field"><label>三级名称</label><input v-model="form.level3_name" /></div>
        <div class="field"><label>三级直推二级人数 ≥</label><input type="number" v-model.number="form.level3_direct_l2_min" /></div>
        <div class="field"><label>三级团队总业绩 ≥ (P)</label><input type="number" step="0.01" v-model.number="form.level3_team_pv" /></div>
      </div>

      <h3>佣金比例（相对商品实付）</h3>
      <div class="grid-3">
        <div class="field"><label>一级比例 (0–1)</label><input type="number" step="0.0001" v-model.number="form.commission_rate_1" /></div>
        <div class="field"><label>二级比例</label><input type="number" step="0.0001" v-model.number="form.commission_rate_2" /></div>
        <div class="field"><label>三级比例</label><input type="number" step="0.0001" v-model.number="form.commission_rate_3" /></div>
      </div>

      <h3>结算规则</h3>
      <div class="grid-3">
        <div class="field"><label>每月结算日（号）</label><input type="number" v-model.number="form.settlement_day" /></div>
        <div class="field"><label>确认收货后锁定天数</label><input type="number" v-model.number="form.after_sale_days" /></div>
      </div>

      <h3>文案（前台会员中心展示）</h3>
      <div class="field"><label>奖励逻辑说明</label><textarea v-model="form.reward_rules_text" rows="5"></textarea></div>
      <div class="field"><label>对外宣传</label><textarea v-model="form.public_slogans_text" rows="5"></textarea></div>

      <div class="footer-actions">
        <button class="btn-primary" type="button" @click="save">保存配置</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { api } from '../api'
import { toast } from '../components/Toast'

const loaded = ref(false)
const form = ref({})

const load = async () => {
  const res = await api.getAffiliateAdminConfig()
  if (res.code === 0) {
    form.value = { ...res.data }
    loaded.value = true
  } else {
    toast.error(res.msg || '加载失败')
  }
}

const save = async () => {
  const res = await api.saveAffiliateAdminConfig(form.value)
  if (res.code === 0) {
    toast.success('已保存')
  } else {
    toast.error(res.msg || '保存失败')
  }
}

const runUnlock = async () => {
  const res = await api.runAffiliateUnlock()
  if (res.code === 0) {
    toast.success(`已更新 ${res.data?.updated ?? 0} 条`)
  } else {
    toast.error(res.msg || '失败')
  }
}

const runSettle = async () => {
  const period = window.prompt('结算批次标签（如 2026-04）', new Date().toISOString().slice(0, 7))
  if (period === null) return
  const res = await api.runAffiliateSettle(period || undefined)
  if (res.code === 0) {
    toast.success(`已结算 ${res.data?.settled ?? 0} 条`)
  } else {
    toast.error(res.msg || '失败')
  }
}

onMounted(load)
</script>

<style scoped>
.page-container { padding: 2rem; max-width: 1100px; margin: 0 auto; }
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; flex-wrap: wrap; gap: 1rem; }
.page-title { font-size: 1.5rem; margin: 0; }
.header-actions { display: flex; gap: 0.5rem; flex-wrap: wrap; }
.hint { color: #6b7280; font-size: 0.9rem; margin-bottom: 1.5rem; }
.card { background: #fff; border-radius: 12px; padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }
.card h3 { margin: 1.25rem 0 0.75rem; font-size: 1.05rem; }
.card h3:first-child { margin-top: 0; }
.grid-3 { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 1rem; }
.field label { display: block; font-size: 0.85rem; margin-bottom: 0.35rem; color: #374151; }
.field input, .field select, .field textarea { width: 100%; padding: 0.5rem 0.65rem; border: 1px solid #e5e7eb; border-radius: 8px; box-sizing: border-box; }
.footer-actions { margin-top: 1.5rem; }
.btn-primary { background: var(--color-primary); color: #fff; border: none; padding: 0.6rem 1.25rem; border-radius: 8px; cursor: pointer; }
.btn-secondary { background: #f3f4f6; border: 1px solid #e5e7eb; padding: 0.5rem 1rem; border-radius: 8px; cursor: pointer; }
</style>
