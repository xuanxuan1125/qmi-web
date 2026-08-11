<script setup lang="ts">
import { onMounted, ref } from 'vue'
import EmptyDeviceState from '../components/EmptyDeviceState.vue'
import LoadingSkeleton from '../components/LoadingSkeleton.vue'
import { getSIM } from '../api/sim'
import type { SIMInfo } from '../types/api'

const data = ref<SIMInfo | null>(null)
const error = ref('')

async function load() {
  try {
    data.value = await getSIM()
    error.value = ''
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '无法读取 SIM 状态。'
  }
}

onMounted(() => { void load() })
</script>

<template>
  <section class="page">
    <div class="page-title"><div><p class="eyebrow">UIM</p><h1>SIM</h1></div></div>
    <p v-if="error" class="error-banner">{{ error }}</p>
    <LoadingSkeleton v-else-if="!data" label="正在读取 SIM 状态…" />
    <EmptyDeviceState v-else-if="!data.available" detail="没有可读取的 QMI 设备，因此不会查询或修改 SIM。" />
    <section v-else class="info-grid">
      <article class="info-card"><span>卡状态</span><strong>{{ data.present ? (data.ready ? '已就绪' : '需要处理') : '未插卡' }}</strong><p>PIN：{{ data.pin_status || '未知' }}</p></article>
      <article class="info-card"><span>运营商</span><strong>{{ data.operator || '未注册' }}</strong><p>MCC/MNC：{{ data.mcc || '—' }}/{{ data.mnc || '—' }}</p></article>
      <article class="info-card"><span>网络注册</span><strong>{{ data.registered ? '已注册' : '未注册' }}</strong><p>{{ data.roaming ? '漫游中' : '非漫游' }}</p></article>
      <article class="info-card"><span>已保护标识</span><strong>{{ data.imsi || '未提供' }}</strong><p>ICCID：{{ data.iccid || '未提供' }}</p></article>
    </section>
  </section>
</template>
