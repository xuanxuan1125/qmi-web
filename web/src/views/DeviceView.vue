<script setup lang="ts">
import { onMounted, ref } from 'vue'
import EmptyDeviceState from '../components/EmptyDeviceState.vue'
import LoadingSkeleton from '../components/LoadingSkeleton.vue'
import { getDevices, scanDevices } from '../api/devices'
import type { DevicesResponse } from '../types/api'

const data = ref<DevicesResponse | null>(null)
const error = ref('')
const scanning = ref(false)

async function load() {
  try {
    data.value = await getDevices()
    error.value = ''
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '无法读取设备发现状态。'
  }
}

async function scan() {
  scanning.value = true
  error.value = ''
  try {
    data.value = await scanDevices()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '设备重新扫描失败。'
  } finally {
    scanning.value = false
  }
}

onMounted(() => { void load() })
</script>

<template>
  <section class="page">
    <div class="page-title">
      <div><p class="eyebrow">DISCOVERY</p><h1>设备</h1></div>
      <span v-if="data" class="badge">{{ data.backend }} · {{ data.devices.length }} 台</span>
    </div>
    <div class="action-row">
      <button :disabled="scanning" @click="scan">{{ scanning ? '正在扫描…' : '重新扫描' }}</button>
      <p>只读取现有设备节点与 sysfs 元数据；不会重置设备、发送 AT 命令或改变 USB 标识。</p>
    </div>
    <p v-if="error" class="error-banner">{{ error }}</p>
    <LoadingSkeleton v-else-if="!data" label="正在读取设备发现结果…" />
    <EmptyDeviceState v-else-if="data.devices.length === 0" />
    <section v-else class="device-grid">
      <article v-for="device in data.devices" :key="device.id" class="device-card">
        <div class="card-heading">
          <div><p class="eyebrow">{{ device.manufacturer || 'QMI DEVICE' }}</p><h2>{{ device.product || device.id }}</h2></div>
          <span :class="['badge', device.busy ? 'warning' : 'safe']">{{ device.busy ? '可能被占用' : device.status }}</span>
        </div>
        <dl class="field-list">
          <div><dt>控制节点</dt><dd><code>{{ device.control_path }}</code></dd></div>
          <div><dt>驱动</dt><dd>{{ device.driver || '未知' }}</dd></div>
          <div><dt>USB</dt><dd>{{ device.usb_vid || '—' }}:{{ device.usb_pid || '—' }}</dd></div>
          <div><dt>网络接口</dt><dd>{{ device.network_interface || '未发现' }}</dd></div>
          <div><dt>串口</dt><dd>{{ device.serial_ports.length ? device.serial_ports.join(' · ') : '未发现' }}</dd></div>
        </dl>
        <details>
          <summary>只读 sysfs 信息</summary>
          <code>{{ device.sysfs_path || '未提供' }}</code>
        </details>
      </article>
    </section>
  </section>
</template>
