<script setup>
import { computed, useId } from 'vue'

const props = defineProps({
  step1: { type: String, required: true },
  step2: { type: String, required: true },
  step3: { type: String, required: true },
  /** 读屏用；建议与当前语言一致 */
  diagramAria: { type: String, default: '' },
})

const aria = computed(() => props.diagramAria || `${props.step1}，${props.step2}，${props.step3}`)

const markerId = `empty-flow-arrow-${useId().replace(/[^a-zA-Z0-9_-]/g, '')}`
const markerUrl = computed(() => `url(#${markerId})`)
</script>

<template>
  <svg
    class="empty-flow-svg"
    viewBox="0 0 340 52"
    role="img"
    :aria-label="aria"
    xmlns="http://www.w3.org/2000/svg"
  >
    <defs>
      <marker
        :id="markerId"
        markerWidth="7"
        markerHeight="7"
        refX="6"
        refY="3.5"
        orient="auto"
      >
        <path d="M0,0 L7,3.5 L0,7 Z" fill="rgba(201, 168, 124, 0.9)" />
      </marker>
    </defs>

    <!-- 节点 1 -->
    <foreignObject x="0" y="4" width="100" height="44">
      <div xmlns="http://www.w3.org/1999/xhtml" class="flow-fo-inner">{{ step1 }}</div>
    </foreignObject>

    <path
      d="M 100 26 L 116 26"
      fill="none"
      stroke="rgba(201, 168, 124, 0.55)"
      stroke-width="1.5"
      stroke-linecap="round"
      :marker-end="markerUrl"
    />

    <!-- 节点 2 -->
    <foreignObject x="120" y="4" width="100" height="44">
      <div xmlns="http://www.w3.org/1999/xhtml" class="flow-fo-inner">{{ step2 }}</div>
    </foreignObject>

    <path
      d="M 220 26 L 236 26"
      fill="none"
      stroke="rgba(201, 168, 124, 0.55)"
      stroke-width="1.5"
      stroke-linecap="round"
      :marker-end="markerUrl"
    />

    <!-- 节点 3 -->
    <foreignObject x="240" y="4" width="100" height="44">
      <div xmlns="http://www.w3.org/1999/xhtml" class="flow-fo-inner">{{ step3 }}</div>
    </foreignObject>
  </svg>
</template>

<style scoped>
.empty-flow-svg {
  width: 100%;
  max-width: 340px;
  height: auto;
  display: block;
  margin: 0 auto 1.35rem;
  overflow: visible;
}

.flow-fo-inner {
  box-sizing: border-box;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  margin: 0;
  padding: 4px 6px;
  border-radius: 10px;
  border: 1px solid rgba(201, 149, 160, 0.35);
  background: linear-gradient(180deg, rgba(255, 253, 250, 0.98) 0%, rgba(252, 246, 248, 0.92) 100%);
  box-shadow: 0 1px 0 rgba(255, 255, 255, 0.8) inset, 0 6px 20px rgba(58, 42, 50, 0.06);
  font-family: var(--font-serif, 'Noto Serif SC', serif);
  font-size: 11px;
  font-weight: 500;
  letter-spacing: 0.06em;
  line-height: 1.25;
  text-align: center;
  color: var(--primary-color, #3a2a32);
  -webkit-font-smoothing: antialiased;
}
</style>
