<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import LoadingSkeleton from '../components/LoadingSkeleton.vue'
import { changePassword } from '../api/auth'
import { getSettings, updateSettings } from '../api/settings'
import { useSessionStore } from '../stores/session'
import type { SettingsResponse } from '../types/api'

const session = useSessionStore()
const router = useRouter()
const data = ref<SettingsResponse | null>(null)
const scanInterval = ref('30s')
const logLevel = ref<'debug' | 'info' | 'warn' | 'error'>('info')
const pushEnabled = ref(false)
const pushToken = ref('')
const pushTemplate = ref('')
const currentPassword = ref('')
const newPassword = ref('')
const confirmation = ref('')
const error = ref('')
const notice = ref('')
const saving = ref(false)
const changingPassword = ref(false)

function applySettings(settings: SettingsResponse) {
  data.value = settings
  scanInterval.value = settings.general.scan_interval
  logLevel.value = settings.logging.level
  pushEnabled.value = settings.pushplus.enabled
  pushTemplate.value = settings.pushplus.template
}

async function load() {
  try {
    applySettings(await getSettings())
    error.value = ''
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '无法读取设置。'
  }
}

async function save() {
  saving.value = true
  error.value = ''
  notice.value = ''
  try {
    applySettings(await updateSettings({
      general: { scan_interval: scanInterval.value },
      logging: { level: logLevel.value },
      pushplus: { enabled: pushEnabled.value, token: pushToken.value, template: pushTemplate.value }
    }))
    pushToken.value = ''
    notice.value = '设置已保存。PushPlus Token 不会通过 API 返回。'
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '保存设置失败。'
  } finally {
    saving.value = false
  }
}

async function savePassword() {
  if (newPassword.value !== confirmation.value) {
    error.value = '两次新密码输入不一致。'
    return
  }
  changingPassword.value = true
  error.value = ''
  try {
    await changePassword(currentPassword.value, newPassword.value, confirmation.value)
    session.markUnauthenticated()
    await router.replace('/login')
  } catch (cause) {
    error.value = cause instanceof Error ? cause.message : '修改密码失败。'
  } finally {
    changingPassword.value = false
  }
}

onMounted(() => { void load() })
</script>

<template>
  <section class="page">
    <div class="page-title"><div><p class="eyebrow">ADMINISTRATION</p><h1>设置</h1></div></div>
    <p v-if="error" class="error-banner">{{ error }}</p>
    <p v-if="notice" class="success-banner">{{ notice }}</p>
    <LoadingSkeleton v-else-if="!data" label="正在读取设置…" />
    <section v-else class="settings-layout">
      <form class="settings-card" @submit.prevent="save">
        <h2>常规</h2>
        <label>扫描间隔 <input v-model="scanInterval" inputmode="text" required /></label>
        <label>日志等级 <select v-model="logLevel"><option>debug</option><option>info</option><option>warn</option><option>error</option></select></label>
        <p class="muted">后端：{{ data.general.backend }}。扫描只读取现有节点；切换后端需修改部署配置并重启。</p>
        <h2>SMS-only 安全边界</h2>
        <p class="muted">{{ data.security.message }} 短信发送、PDU 原文保存和移动数据控制均保持关闭。</p>
        <h2>PushPlus</h2>
        <label class="switch"><input v-model="pushEnabled" type="checkbox" /> 启用通知</label>
        <label>Token <input v-model="pushToken" type="password" placeholder="留空以保留现有 Token" autocomplete="off" /></label>
        <label>模板 <input v-model="pushTemplate" placeholder="html" /></label>
        <p class="muted">当前 Token：{{ data.pushplus.token_configured ? '已安全配置' : '未配置' }}</p>
        <button :disabled="saving">{{ saving ? '正在保存…' : '保存设置' }}</button>
      </form>
      <form class="settings-card" @submit.prevent="savePassword">
        <h2>管理员</h2>
        <p class="muted">当前用户：{{ session.username || 'admin' }}</p>
        <label>当前密码 <input v-model="currentPassword" type="password" autocomplete="current-password" required /></label>
        <label>新密码 <input v-model="newPassword" type="password" autocomplete="new-password" minlength="6" required /></label>
        <label>确认新密码 <input v-model="confirmation" type="password" autocomplete="new-password" minlength="6" required /></label>
        <p class="muted">修改成功后，所有现有会话会失效并返回登录页。</p>
        <button class="secondary" :disabled="changingPassword">{{ changingPassword ? '正在修改…' : '修改密码' }}</button>
      </form>
    </section>
  </section>
</template>
