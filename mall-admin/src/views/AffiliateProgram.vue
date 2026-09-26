<template>
  <div class="page-container">
    <div class="page-header">
      <h1 class="page-title">{{ $t('admin.affiliateProgram.title') }}</h1>
    </div>
    <p class="hint" v-if="loaded">
      {{ $t('admin.affiliateProgram.hint', {
        level3: form.level3_name,
        days: form.after_sale_days,
        day: form.settlement_day,
      }) }}
    </p>

    <div v-if="loadError" class="card error-card">
      <h3>{{ $t('admin.affiliateProgram.loadFailTitle') }}</h3>
      <p class="error-text">{{ loadError }}</p>
      <p class="hint">{{ $t('admin.affiliateProgram.loadFailHint') }}</p>
      <button class="btn-primary" type="button" @click="load">{{ $t('admin.affiliateProgram.retry') }}</button>
    </div>

    <div class="card" v-else-if="loaded">
      <div class="section-head">
        <h3>{{ $t('admin.affiliateProgram.sectionLevels') }}</h3>
        <label class="currency-field">
          <span>{{ $t('admin.affiliateProgram.currencySuffix') }}</span>
          <input v-model="form.currency_suffix" class="input-sm" maxlength="8" />
        </label>
      </div>

      <div class="table-wrap">
        <table class="config-table">
          <thead>
            <tr>
              <th class="col-level">{{ $t('admin.affiliateProgram.colLevel') }}</th>
              <th class="col-name">{{ $t('admin.affiliateProgram.colName') }}</th>
              <th class="col-condition">{{ $t('admin.affiliateProgram.colCondition') }}</th>
              <th class="col-rate">{{ $t('admin.affiliateProgram.colRate') }}<br><small>{{ $t('admin.affiliateProgram.colRateHint') }}</small></th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td class="col-level"><span class="level-tag l1">{{ $t('admin.affiliateProgram.tier1') }}</span></td>
              <td>
                <div class="name-stack">
                  <label class="mini-label">{{ $t('admin.affiliateProgram.colNameZh') }}</label>
                  <input v-model="form.level1_name" class="cell-input" />
                  <label class="mini-label">{{ $t('admin.affiliateProgram.colNameEn') }}</label>
                  <input v-model="form.level1_name_en" class="cell-input" />
                </div>
              </td>
              <td class="condition-cell">
                <div class="condition-line">
                  <span>{{ $t('admin.affiliateProgram.spendReach') }}</span>
                  <input type="number" step="0.01" v-model.number="form.level1_spend_threshold" class="cell-input num" />
                  <span>{{ form.currency_suffix || 'P' }}</span>
                </div>
                <div class="condition-line">
                  <span>{{ $t('admin.affiliateProgram.anyOrder') }}</span>
                  <select v-model.number="form.level1_any_order" class="cell-select">
                    <option :value="1">{{ $t('admin.affiliateProgram.yes') }}</option>
                    <option :value="0">{{ $t('admin.affiliateProgram.no') }}</option>
                  </select>
                </div>
              </td>
              <td>
                <div class="rate-cell">
                  <input type="number" step="0.0001" min="0" max="1" v-model.number="form.commission_rate_1" class="cell-input num" />
                  <span class="rate-pct">{{ pct(form.commission_rate_1) }}</span>
                </div>
                <p class="rate-hint">改一级后，二、三级按 1/2、1/4 自动推算（仍可手动改）</p>
              </td>
            </tr>
            <tr>
              <td class="col-level"><span class="level-tag l2">{{ $t('admin.affiliateProgram.tier2') }}</span></td>
              <td>
                <div class="name-stack">
                  <label class="mini-label">{{ $t('admin.affiliateProgram.colNameZh') }}</label>
                  <input v-model="form.level2_name" class="cell-input" />
                  <label class="mini-label">{{ $t('admin.affiliateProgram.colNameEn') }}</label>
                  <input v-model="form.level2_name_en" class="cell-input" />
                </div>
              </td>
              <td class="condition-cell">
                <div class="condition-line">
                  <span>{{ $t('admin.affiliateProgram.directL1') }}</span>
                  <input type="number" min="0" v-model.number="form.level2_direct_l1_min" class="cell-input num" />
                  <span>{{ $t('admin.affiliateProgram.people') }}</span>
                </div>
                <div class="condition-line">
                  <span>{{ $t('admin.affiliateProgram.andTeamPv') }}</span>
                  <input type="number" step="0.01" min="0" v-model.number="form.level2_team_pv" class="cell-input num" />
                  <span>{{ form.currency_suffix || 'P' }}</span>
                </div>
              </td>
              <td>
                <div class="rate-cell">
                  <input type="number" step="0.0001" min="0" max="1" v-model.number="form.commission_rate_2" class="cell-input num" />
                  <span class="rate-pct">{{ pct(form.commission_rate_2) }}</span>
                </div>
              </td>
            </tr>
            <tr>
              <td class="col-level"><span class="level-tag l3">{{ $t('admin.affiliateProgram.tier3') }}</span></td>
              <td>
                <div class="name-stack">
                  <label class="mini-label">{{ $t('admin.affiliateProgram.colNameZh') }}</label>
                  <input v-model="form.level3_name" class="cell-input" />
                  <label class="mini-label">{{ $t('admin.affiliateProgram.colNameEn') }}</label>
                  <input v-model="form.level3_name_en" class="cell-input" />
                </div>
              </td>
              <td class="condition-cell">
                <div class="condition-line">
                  <span>{{ $t('admin.affiliateProgram.directL2') }}</span>
                  <input type="number" min="0" v-model.number="form.level3_direct_l2_min" class="cell-input num" />
                  <span>{{ $t('admin.affiliateProgram.people') }}</span>
                </div>
                <div class="condition-line">
                  <span>{{ $t('admin.affiliateProgram.andTeamTotalPv') }}</span>
                  <input type="number" step="0.01" min="0" v-model.number="form.level3_team_pv" class="cell-input num" />
                  <span>{{ form.currency_suffix || 'P' }}</span>
                </div>
              </td>
              <td>
                <div class="rate-cell">
                  <input type="number" step="0.0001" min="0" max="1" v-model.number="form.commission_rate_3" class="cell-input num" />
                  <span class="rate-pct">{{ pct(form.commission_rate_3) }}</span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <h3>{{ $t('admin.affiliateProgram.sectionSettlement') }}</h3>
      <table class="config-table config-table-compact">
        <thead>
          <tr>
            <th>{{ $t('admin.affiliateProgram.ruleItem') }}</th>
            <th>{{ $t('admin.affiliateProgram.ruleValue') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>{{ $t('admin.affiliateProgram.settlementDay') }}</td>
            <td><input type="number" min="1" max="28" v-model.number="form.settlement_day" class="cell-input num" /></td>
          </tr>
          <tr>
            <td>{{ $t('admin.affiliateProgram.afterSaleDays') }}</td>
            <td><input type="number" min="1" v-model.number="form.after_sale_days" class="cell-input num" /></td>
          </tr>
        </tbody>
      </table>
      <p class="settle-note">{{ $t('admin.affiliateProgram.settleNote') }}</p>

      <h3>{{ $t('admin.affiliateProgram.sectionCopy') }}</h3>
      <div class="copy-grid">
        <div class="field">
          <label>{{ $t('admin.affiliateProgram.complianceRulesZh') }}</label>
          <textarea v-model="form.compliance_rules_text" rows="5"></textarea>
        </div>
        <div class="field">
          <label>{{ $t('admin.affiliateProgram.complianceRulesEn') }}</label>
          <textarea v-model="form.compliance_rules_text_en" rows="5"></textarea>
        </div>
        <div class="field">
          <label>{{ $t('admin.affiliateProgram.rewardRulesZh') }}</label>
          <textarea v-model="form.reward_rules_text" rows="5"></textarea>
        </div>
        <div class="field">
          <label>{{ $t('admin.affiliateProgram.rewardRulesEn') }}</label>
          <textarea v-model="form.reward_rules_text_en" rows="5"></textarea>
        </div>
        <div class="field">
          <label>{{ $t('admin.affiliateProgram.publicSlogansZh') }}</label>
          <textarea v-model="form.public_slogans_text" rows="5"></textarea>
        </div>
        <div class="field">
          <label>{{ $t('admin.affiliateProgram.publicSlogansEn') }}</label>
          <textarea v-model="form.public_slogans_text_en" rows="5"></textarea>
        </div>
      </div>

      <div class="footer-actions">
        <button class="btn-primary" type="button" @click="save">{{ $t('admin.affiliateProgram.save') }}</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { api } from '../api'
import { toast } from '../components/Toast'

const { t } = useI18n()
const loaded = ref(false)
const loadError = ref('')
const form = ref({})
/** 加载完成后才根据一级比例自动推算二三级，避免覆盖已保存配置 */
const syncChildRates = ref(false)

const load = async () => {
  loadError.value = ''
  loaded.value = false
  syncChildRates.value = false
  try {
    const res = await api.getAffiliateAdminConfig()
    if (res.code === 0) {
      form.value = { ...res.data }
      loaded.value = true
      // 下一帧再开启联动，避免初始化赋值触发覆盖
      requestAnimationFrame(() => {
        syncChildRates.value = true
      })
    } else {
      loadError.value = res.msg || t('admin.affiliateProgram.loadFail')
      toast.error(loadError.value)
    }
  } catch (e) {
    loadError.value = e?.message || t('admin.affiliateProgram.loadFail')
    toast.error(t('admin.affiliateProgram.loadFail'))
  }
}

const save = async () => {
  const res = await api.saveAffiliateAdminConfig(form.value)
  if (res.code === 0) {
    toast.success(t('admin.affiliateProgram.saveOk'))
  } else {
    toast.error(res.msg || t('admin.affiliateProgram.saveFail'))
  }
}

const pct = (rate) => {
  const n = Number(rate)
  if (Number.isNaN(n)) return ''
  return `≈ ${(n * 100).toFixed(1)}%`
}

/** 一级比例变更时：二级 = 一半，三级 = 四分之一（可再手动改） */
const applyDerivedRates = (rate1) => {
  const n = Number(rate1)
  if (Number.isNaN(n) || n < 0) return
  const r2 = Math.round(n * 0.5 * 10000) / 10000
  const r3 = Math.round(n * 0.25 * 10000) / 10000
  form.value.commission_rate_2 = r2
  form.value.commission_rate_3 = r3
}

watch(
  () => form.value?.commission_rate_1,
  (val, oldVal) => {
    if (!syncChildRates.value) return
    if (val === oldVal) return
    applyDerivedRates(val)
  }
)

onMounted(load)
</script>

<style scoped>
.page-container { padding: 2rem; max-width: 1200px; margin: 0 auto; }
.page-header { margin-bottom: 0.5rem; }
.page-title { font-size: 1.5rem; margin: 0; color: var(--color-primary-dark); }
.hint { color: #6b7280; font-size: 0.9rem; margin-bottom: 1.5rem; line-height: 1.55; }
.settle-note { font-size: 0.82rem; color: #9ca3af; margin: 0.5rem 0 1.25rem; line-height: 1.5; }
.card { background: #fff; border-radius: var(--radius-lg); padding: 1.5rem; box-shadow: var(--shadow-sm); border: 1px solid var(--color-border); }
.card h3 { margin: 1.5rem 0 0.75rem; font-size: 1.05rem; color: var(--color-primary-dark); }
.section-head { display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 1rem; margin-bottom: 1rem; }
.section-head h3 { margin: 0; font-size: 1.05rem; }
.currency-field { display: flex; align-items: center; gap: 0.5rem; font-size: 0.85rem; color: var(--color-text-muted); }
.currency-field .input-sm { width: 4rem; padding: 0.4rem 0.55rem; border: 1px solid var(--color-border); border-radius: 6px; }
.table-wrap { overflow-x: auto; margin-bottom: 0.5rem; }
.config-table { width: 100%; border-collapse: collapse; font-size: 0.9rem; }
.config-table th {
  text-align: left; padding: 0.75rem 1rem; background: #fafafa;
  border-bottom: 2px solid var(--color-border); font-size: 0.8rem; color: var(--color-text-muted);
  font-weight: 600; white-space: nowrap;
}
.config-table th small { font-weight: 400; color: #9ca3af; }
.config-table td { padding: 1rem; border-bottom: 1px solid #f0f0f0; vertical-align: top; }
.config-table tbody tr:hover td { background: rgba(16, 185, 129, 0.03); }
.config-table-compact { max-width: 480px; margin-bottom: 0.5rem; }
.config-table-compact td:first-child { color: var(--color-text-muted); width: 55%; }
.col-level { width: 72px; }
.col-name { width: 220px; }
.col-rate { width: 140px; }
.level-tag {
  display: inline-block; padding: 0.25rem 0.55rem; border-radius: 6px;
  font-size: 0.78rem; font-weight: 700;
}
.level-tag.l1 { background: #ecfdf5; color: #047857; }
.level-tag.l2 { background: #eff6ff; color: #1d4ed8; }
.level-tag.l3 { background: #fef3c7; color: #b45309; }
.cell-input {
  width: 100%; padding: 0.45rem 0.6rem; border: 1px solid var(--color-border);
  border-radius: 6px; font-size: 0.9rem; box-sizing: border-box;
}
.cell-input.num { width: 5.5rem; min-width: 4rem; }
.cell-select { padding: 0.4rem 0.5rem; border: 1px solid var(--color-border); border-radius: 6px; font-size: 0.88rem; }
.condition-cell { min-width: 280px; }
.condition-line {
  display: flex; align-items: center; flex-wrap: wrap; gap: 0.35rem 0.5rem;
  margin-bottom: 0.45rem; color: #4b5563; font-size: 0.88rem;
}
.condition-line:last-child { margin-bottom: 0; }
.rate-cell { display: flex; align-items: center; gap: 0.5rem; }
.rate-pct { font-size: 0.8rem; color: var(--color-primary); font-weight: 600; white-space: nowrap; }
.rate-hint { margin: 0.4rem 0 0; font-size: 0.72rem; color: #9ca3af; line-height: 1.4; max-width: 11rem; }
.name-stack { display: flex; flex-direction: column; gap: 0.35rem; }
.mini-label { font-size: 0.72rem; color: #9ca3af; font-weight: 600; }
.copy-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 1rem; }
@media (max-width: 900px) { .copy-grid { grid-template-columns: 1fr; } }
.field label { display: block; font-size: 0.85rem; margin-bottom: 0.35rem; color: #374151; }
.field textarea { width: 100%; padding: 0.5rem 0.65rem; border: 1px solid #e5e7eb; border-radius: 8px; box-sizing: border-box; }
.footer-actions { margin-top: 1.5rem; padding-top: 1rem; border-top: 1px solid var(--color-border); }
.btn-primary { background: var(--color-primary); color: #fff; border: none; padding: 0.6rem 1.25rem; border-radius: 8px; cursor: pointer; font-weight: 600; }
.error-card { border: 1px solid #fecaca; background: #fff5f5; }
.error-text { color: #b91c1c; margin: 0.5rem 0 1rem; }
</style>
