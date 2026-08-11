<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'
import LoadingSkeleton from '../components/LoadingSkeleton.vue'
import { getLogs } from '../api/logs'
import type { LogEntry } from '../types/api'

const items = ref<LogEntry[]>([])
const loaded = ref(false)
const error = ref('')
let stream: EventSource | undefined

function formatFields(fields?: Record<string, unknown>): string {
  if (!fields || Object.keys(fields).length === 0) return ''
  return Object.entries(fields).map(([key, value]) => `${key}=${String(value)}`).join(' · ')
}

function connectStream() {
  stream = new EventSource('/api/v1/logs/stream')
  stream.addEventListener('Log', event => {
    try {
      const envelope = JSON.parse((event as MessageEvent<string>).data) as { data?: LogEntry }
      if (envelope.data) items.value = [...items.value, envelope.data].slice(-500)
    } catch {
      error.value = '日志流返回了无法识别的数据。'
    }
  })
  stream.onerror = () => { error.value = '日志实时连接已断开；页面中保留已读取的记录。' }
}

async function load() {
  try {
    items.value = (await getLogs()).items
    error.value = ''
    connectStream()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '无法读取日志。'
  } finally {
    loaded.value = true
  }
}

onMounted(() => { void load() })
onBeforeUnmount(() => { stream?.close() })
</script>

<template>
  <section class="page">
    <div class="page-title"><div><p class="eyebrow">OBSERVABILITY</p><h1>日志</h1></div><span class="badge">{{ items.length }} 条</span></div>
    <p v-if="error" class="error-banner">{{ error }}</p>
    <LoadingSkeleton v-else-if="!loaded" label="正在读取结构化日志…" />
    <section v-else class="logs-table">
      <article v-for="(item, index) in items" :key="`${item.time}-${index}`" class="log-row">
        <time>{{ item.time }}</time><span :class="['log-level', item.level]">{{ item.level }}</span>
        <div><strong>{{ item.message }}</strong><p v-if="formatFields(item.fields)">{{ formatFields(item.fields) }}</p></div>
      </article>
      <p v-if="!items.length" class="empty">当前缓冲区没有可显示的日志。</p>
    </section>
  </section>
</template>
