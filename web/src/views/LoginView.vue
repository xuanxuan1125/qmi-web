<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useSessionStore } from '../stores/session'

const username = ref('admin')
const password = ref('')
const busy = ref(false)
const error = ref('')
const session = useSessionStore()
const router = useRouter()

async function submit() {
  error.value = ''
  busy.value = true
  try {
    await session.login(username.value, password.value)
    await router.replace('/')
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '登录失败。'
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <section class="auth-screen">
    <form class="auth-card" @submit.prevent="submit">
      <p class="eyebrow">LOCAL ADMINISTRATION</p>
      <h1>QMI Web 管理员登录</h1>
      <p>此版本仅接收短信，不会启动移动数据。</p>
      <label>用户名<input v-model="username" autocomplete="username" required /></label>
      <label>密码<input v-model="password" type="password" autocomplete="current-password" required /></label>
      <p v-if="error" class="error-banner">{{ error }}</p>
      <button :disabled="busy">{{ busy ? '正在登录…' : '登录' }}</button>
    </form>
  </section>
</template>
