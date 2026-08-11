<script setup lang="ts">
import { onMounted, ref } from 'vue'
import EmptyDeviceState from '../components/EmptyDeviceState.vue'
import LoadingSkeleton from '../components/LoadingSkeleton.vue'
import { getSignal } from '../api/signal'
import type { SignalInfo } from '../types/api'

const data = ref<SignalInfo | null>(null)
const error = ref('')

async function load() {
  try {
    data.value = await getSignal()
    error.value = ''
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '无法读取信号状态。'
  }
}

onMounted(() => { void load() })
</script>

<template>
  <section class="page">
    <div class="page-title"><div><p class="eyebrow">NAS</p><h1>信号</h1></div></div>
    <p v-if="error" class="error-banner">{{ error }}</p>
    <LoadingSkeleton v-else-if="!data" label="正在读取信号状态…" />
    <EmptyDeviceState v-else-if="!data.available" detail="没有可读取的 QMI 设备，因此没有信号数据可显示。" />
    <section v-else class="info-grid signal-grid">
      <article class="info-card"><span>RSRP</span><strong>{{ data.rsrp || '未提供' }}</strong><p>参考信号接收功率</p></article>
      <article class="info-card"><span>RSSI</span><strong>{{ data.rssi || '未提供' }}</strong><p>接收信号强度</p></article>
      <article class="info-card"><span>RSRQ</span><strong>{{ data.rsrq || '未提供' }}</strong><p>参考信号质量</p></article>
      <article class="info-card"><span>SINR</span><strong>{{ data.sinr || '未提供' }}</strong><p>信干噪比</p></article>
      <article class="info-card"><span>网络制式</span><strong>{{ data.technology || '未提供' }}</strong><p>PLMN：{{ data.plmn || '未提供' }}</p></article>
      <article class="info-card"><span>注册状态</span><strong>{{ data.registered ? '已注册' : '未注册' }}</strong><p>{{ data.roaming ? '漫游中' : '非漫游' }}</p></article>
    </section>
  </section>
</template>
