<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { getSMS, getSMSPage, setSMSRead } from '../api/sms'
import type { SMSMessage } from '../types/api'

const items = ref<SMSMessage[]>([])
const total = ref(0)
const query = ref('')
const page = ref(1)
const selected = ref<SMSMessage | null>(null)
const error = ref('')
const loading = ref(false)

async function load(reset = false) {
  if (reset) page.value = 1
  loading.value = true
  try {
    const reply = await getSMSPage(page.value, 50, query.value)
    items.value = reply.items
    total.value = reply.total
    error.value = ''
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '无法读取短信。'
  } finally {
    loading.value = false
  }
}

async function open(item: SMSMessage) {
  try {
    selected.value = await getSMS(item.id)
    if (selected.value.status !== 'read') {
      await setSMSRead(item.id, true)
      selected.value.status = 'read'
      await load()
    }
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '无法读取短信详情。'
  }
}

onMounted(() => { void load() })
</script>

<template>
  <section class="page">
    <div class="page-title"><div><p class="eyebrow">INBOX</p><h1>短信</h1></div><span class="badge">{{ total }} 条</span></div>
    <form class="toolbar" @submit.prevent="load(true)"><input v-model="query" placeholder="搜索发送人或正文" /><button :disabled="loading">{{ loading ? '搜索中…' : '搜索' }}</button></form>
    <p v-if="error" class="error-banner">{{ error }}</p>
    <div class="sms-layout">
      <div class="sms-list">
        <button v-for="item in items" :key="item.id" :class="['sms-row', { unread: item.status === 'unread' }]" @click="open(item)">
          <span>{{ item.sender || '未知发送人' }}</span><time>{{ new Date(item.received_at).toLocaleString() }}</time>
          <p>{{ item.body }}</p><small>{{ item.encoding }}{{ item.is_multipart ? ' · 长短信' : '' }}</small>
        </button>
        <p v-if="!loading && !items.length" class="empty">暂无短信。</p>
      </div>
      <article v-if="selected" class="sms-reader"><p class="eyebrow">MESSAGE</p><h2>{{ selected.sender || '未知发送人' }}</h2><time>{{ new Date(selected.received_at).toLocaleString() }}</time><p class="sms-body">{{ selected.body }}</p></article>
      <article v-else class="sms-reader empty">选择一条短信以阅读完整正文。</article>
    </div>
  </section>
</template>
