<script setup lang="ts">
import { onMounted, ref } from 'vue'
import LoadingSkeleton from '../components/LoadingSkeleton.vue'
import { getDiagnostics } from '../api/diagnostics'
import type { DiagnosticsResponse } from '../types/api'

const data = ref<DiagnosticsResponse | null>(null)
const error = ref('')

async function load() {
  try {
    data.value = await getDiagnostics()
    error.value = ''
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '无法读取诊断信息。'
  }
}

onMounted(() => { void load() })
</script>

<template>
  <section class="page">
    <div class="page-title"><div><p class="eyebrow">READ-ONLY</p><h1>诊断</h1></div></div>
    <p v-if="error" class="error-banner">{{ error }}</p>
    <LoadingSkeleton v-else-if="!data" label="正在生成只读诊断快照…" />
    <template v-else>
      <section class="info-grid">
        <article class="info-card"><span>数据库</span><strong>{{ data.database_ready ? '就绪' : '不可用' }}</strong><p>SQLite 健康检查</p></article>
        <article class="info-card"><span>后端</span><strong>{{ data.backend }}</strong><p>{{ data.detected_devices.length }} 个发现结果</p></article>
        <article class="info-card"><span>运行平台</span><strong>{{ data.os }}/{{ data.architecture }}</strong><p>运行 {{ data.uptime_seconds }} 秒</p></article>
        <article class="info-card"><span>安全模式</span><strong>{{ data.sms_only ? 'SMS-only' : '未知' }}</strong><p>Data Guard：{{ data.guard.state }}</p></article>
      </section>
      <section :class="['guard-card', data.guard.state]">
        <strong>移动数据保护：{{ data.guard.state }}</strong>
        <p>WDS 状态：{{ data.guard.wds_status || '未查询' }}</p>
        <ul v-if="data.guard.findings.length"><li v-for="finding in data.guard.findings" :key="finding.code">{{ finding.detail }}</li></ul>
        <p v-else>未发现蜂窝默认路由、全局地址或拨号进程。此检查只读，不会修改网络。</p>
      </section>
      <section class="diagnostic-details">
        <h2>活动设备</h2>
        <p v-if="data.active_device"><strong>{{ data.active_device.product || data.active_device.id }}</strong> · {{ data.active_device.control_path }}</p>
        <p v-else class="muted">没有活动设备；no-device 部署不会打开 QMI 控制节点。</p>
      </section>
      <section class="diagnostic-details">
        <h2>QMI SMS-only validation</h2>
        <p>Owner: {{ data.qmi_validation.device_ownership }} · WMS: {{ data.qmi_validation.wms_subscribe }} · SetEventReport: {{ data.qmi_validation.wms_set_event_report }} · IndicationRegister: {{ data.qmi_validation.wms_indication_register }}</p>
        <p>Storage reconciliation: {{ data.qmi_validation.last_storage_reconciliation || 'pending' }} · Last indication: {{ data.qmi_validation.last_wms_indication || 'not observed' }} · Reconnects: {{ data.qmi_validation.reconnect_count }}</p>
        <p>ReadMessage: {{ data.qmi_validation.read_message }} · Decoder: {{ data.qmi_validation.decoder }} · SQLite: {{ data.qmi_validation.sqlite }} · Dedup: {{ data.qmi_validation.dedup }}</p>
      </section>
    </template>
  </section>
</template>
