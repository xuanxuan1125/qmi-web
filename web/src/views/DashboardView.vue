<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'
import LoadingSkeleton from '../components/LoadingSkeleton.vue'
import { getDashboard } from '../api/dashboard'
import type { Dashboard } from '../types/api'

const data = ref<Dashboard | null>(null)
const error = ref('')
let timer: number | undefined

async function load() {
  try {
    data.value = await getDashboard()
    error.value = ''
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '后端暂时不可用。'
  }
}

onMounted(() => {
  void load()
  timer = window.setInterval(() => { void load() }, 5000)
})

onBeforeUnmount(() => { if (timer) window.clearInterval(timer) })
</script>

<template>
  <section class="page">
    <div class="page-title"><div><p class="eyebrow">SYSTEM OVERVIEW</p><h1>运行概览</h1></div><span class="badge safe">SMS-only</span></div>
    <p v-if="error" class="error-banner">{{ error }}</p>
    <LoadingSkeleton v-else-if="!data" label="正在读取系统概览…" />
    <template v-else>
      <section class="hero-card">
        <div><span class="muted">设备状态</span><h2>{{ data.device_status === 'connected' ? 'QMI 设备已连接' : '当前未检测到兼容 QMI 设备' }}</h2><p>Backend：{{ data.backend }} · QMI：{{ data.qmi_status }}</p></div>
        <div class="metric"><strong>{{ data.sms.unread }}</strong><span>未读短信</span><small>{{ data.sms.last ? new Date(data.sms.last).toLocaleString() : '暂无短信' }}</small></div>
      </section>
      <section class="cards">
        <article><span>SIM</span><strong>{{ data.sim.available && data.sim.ready ? 'Ready' : 'N/A' }}</strong><p>{{ data.sim.operator || '未检测到设备' }} · {{ data.sim.imsi || '—' }}</p></article>
        <article><span>网络注册</span><strong>{{ data.signal.available && data.signal.registered ? 'Registered' : 'N/A' }}</strong><p>{{ data.signal.technology || '—' }} · {{ data.signal.plmn || '—' }}</p></article>
        <article><span>信号</span><strong>{{ data.signal.rsrp || 'N/A' }}</strong><p>RSSI {{ data.signal.rssi || '—' }} · SINR {{ data.signal.sinr || '—' }}</p></article>
        <article><span>PushPlus</span><strong>{{ data.notifications.pushplus.enabled ? 'Enabled' : 'Disabled' }}</strong><p>{{ data.notifications.pushplus.token_configured ? 'Token 已安全配置' : '未配置 Token' }}</p></article>
      </section>
      <section :class="['guard-card', data.data_guard.state]">
        <strong>移动数据保护：{{ data.data_guard.state }}</strong>
        <p v-if="data.data_guard.state === 'safe'">WDS：{{ data.data_guard.wds_status || '未查询' }}；未发现蜂窝默认路由、蜂窝 global IP 或拨号进程。</p>
        <p v-else>检测到蜂窝数据连接，SMS-only 安全状态异常。{{ data.data_guard.findings.map(finding => finding.detail).join('；') }}</p>
      </section>
      <section class="guard-card">
        <strong>QMI 只读验证：{{ data.qmi_validation.stage }}</strong>
        <p>DMS {{ data.qmi_validation.dms }} · UIM {{ data.qmi_validation.uim }} · NAS {{ data.qmi_validation.nas }} · WDS {{ data.qmi_validation.wds }} · WMS {{ data.qmi_validation.wms_subscribe }}</p>
        <p>短信：{{ data.qmi_validation.sms }}；已扫描 {{ data.qmi_validation.stored_messages }}，已导入 {{ data.qmi_validation.imported_messages }}。{{ data.qmi_validation.detail || '未记录阻塞原因。' }}</p>
      </section>
      <section class="guard-card">
        <strong>QMI SMS-only validation details</strong>
        <p>WMS SetEventReport {{ data.qmi_validation.wms_set_event_report }} · IndicationRegister {{ data.qmi_validation.wms_indication_register }} · storage reconciliation {{ data.qmi_validation.last_storage_reconciliation ? 'active' : 'pending' }}</p>
        <p>ReadMessage {{ data.qmi_validation.read_message }} · Decoder {{ data.qmi_validation.decoder }} · SQLite {{ data.qmi_validation.sqlite }} · Dedup {{ data.qmi_validation.dedup }} · reconnects {{ data.qmi_validation.reconnect_count }}</p>
      </section>
    </template>
  </section>
</template>
