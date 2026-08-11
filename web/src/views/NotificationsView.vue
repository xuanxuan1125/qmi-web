<script setup lang="ts">
import { onMounted, ref } from 'vue'
import LoadingSkeleton from '../components/LoadingSkeleton.vue'
import { getNotifications, sendPushPlusTest } from '../api/notifications'
import type { NotificationsResponse } from '../types/api'

const data = ref<NotificationsResponse | null>(null)
const error = ref('')
const result = ref('')
const testing = ref(false)

async function load() {
  try {
    data.value = await getNotifications()
    error.value = ''
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '无法读取通知状态。'
  }
}

async function testPush() {
  testing.value = true
  result.value = ''
  error.value = ''
  try {
    await sendPushPlusTest()
    result.value = 'PushPlus 测试通知已提交到本地队列。'
    await load()
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : 'PushPlus 测试失败。'
  } finally {
    testing.value = false
  }
}

onMounted(() => { void load() })
</script>

<template>
  <section class="page">
    <div class="page-title"><div><p class="eyebrow">DELIVERY</p><h1>通知</h1></div></div>
    <p v-if="error" class="error-banner">{{ error }}</p>
    <LoadingSkeleton v-else-if="!data" label="正在读取通知队列…" />
    <template v-else>
      <section class="notification-summary">
        <div><p class="eyebrow">PUSHPLUS</p><h2>{{ data.pushplus.enabled ? '已启用' : '未启用' }}</h2><p>Token {{ data.pushplus.token_configured ? '已安全配置' : '未配置' }}；模板：{{ data.pushplus.template || '默认' }}</p></div>
        <button class="secondary" :disabled="testing || !data.pushplus.enabled" @click="testPush">{{ testing ? '正在提交…' : '发送测试通知' }}</button>
      </section>
      <p v-if="result" class="success-banner">{{ result }}</p>
      <section class="notification-list">
        <article v-for="item in data.items" :key="item.id" class="notification-row">
          <div><strong>{{ item.title }}</strong><p>{{ item.kind }} · 尝试 {{ item.attempts }} 次 · {{ item.updated_at }}</p></div>
          <span :class="['badge', item.status === 'success' ? 'safe' : 'warning']">{{ item.status }}</span>
        </article>
        <p v-if="!data.items.length" class="empty">暂无通知队列记录。</p>
      </section>
    </template>
  </section>
</template>
