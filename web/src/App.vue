<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useSessionStore } from './stores/session'
import { useVersionStore } from './stores/version'

const session = useSessionStore()
const version = useVersionStore()
const router = useRouter()
const route = useRoute()
const drawer = ref(false)
const links = [
  ['/', '概览'], ['/devices', '设备'], ['/sim', 'SIM'], ['/signal', '信号'], ['/sms', '短信'],
  ['/notifications', '通知'], ['/logs', '日志'], ['/diagnostics', '诊断'],
  ['/settings', '设置'], ['/about', '关于']
]

function redirectForSession(path = route.path) {
  if (!session.checked) return
  if (!session.authenticated && path !== '/login') return router.replace('/login')
  if (session.authenticated && path === '/login') return router.replace('/')
}

function handleUnauthorized() {
  session.markUnauthenticated()
  void redirectForSession()
}

onMounted(async () => {
  window.addEventListener('qmi-web:unauthorized', handleUnauthorized)
  void version.load()
  await session.bootstrap()
  await redirectForSession()
})

onBeforeUnmount(() => window.removeEventListener('qmi-web:unauthorized', handleUnauthorized))
watch(() => route.path, path => { void redirectForSession(path) })

async function leave() {
  await session.logout()
  await router.replace('/login')
}
</script>

<template>
  <main v-if="!session.checked" class="splash">正在连接 QMI Web…</main>
  <router-view v-else-if="route.path === '/login'" />
  <main v-else class="shell">
    <button class="menu-button" aria-label="打开导航" @click="drawer = !drawer">☰</button>
    <aside :class="{ open: drawer }">
      <div class="brand"><span class="brand-mark">Q</span><div>QMI Web<small>{{ version.headerLabel }} · SMS-only</small></div></div>
      <nav>
        <RouterLink v-for="[path, label] in links" :key="path" :to="path" @click="drawer = false">{{ label }}</RouterLink>
      </nav>
      <button class="quiet-button" @click="leave">退出登录</button>
    </aside>
    <section class="main-panel">
      <header>
        <div><strong>QMI Web</strong><span class="muted"> SMS-only 安全模式：已启用</span></div>
        <div class="header-actions">
          <div class="status-dot"><i></i> 只读蜂窝控制</div>
          <RouterLink class="account-link" to="/settings">{{ session.username || 'admin' }}</RouterLink>
          <button class="quiet-button header-logout" @click="leave">退出</button>
        </div>
      </header>
      <p v-if="session.error" class="error-banner">{{ session.error }}</p>
      <router-view />
    </section>
  </main>
</template>
