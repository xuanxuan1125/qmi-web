<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { getSMSPage, getSMS, setSMSRead } from '../api/sms'
import type { SMSMessage } from '../types/api'
import { 
  MessageSquare, Trash2, CheckCircle2, 
  Search, RefreshCw, AlertCircle, Phone, Info
} from 'lucide-vue-next'

const items = ref<SMSMessage[]>([])
const selectedId = ref<number | null>(null)
const selectedDetail = ref<SMSMessage | null>(null)
const busy = ref(false)
const error = ref('')

const page = ref(1)
const total = ref(0)
const hasMore = computed(() => items.value.length < total.value)

async function loadList(reset = false) {
  if (reset) {
    page.value = 1
    items.value = []
  }
  busy.value = true
  try {
    const res = await getSMSPage(page.value, 20, '')
    if (reset) {
      items.value = res.items || []
    } else {
      items.value.push(...(res.items || []))
    }
    total.value = res.total
  } catch (e) {
    error.value = e instanceof Error ? e.message : '加载短信列表失败'
  } finally {
    busy.value = false
  }
}

const isMobileDetailVisible = ref(false)

async function selectMsg(msg: SMSMessage) {
  selectedId.value = msg.id
  selectedDetail.value = null
  isMobileDetailVisible.value = true // show detail on mobile
  try {
    const detail = await getSMS(msg.id)
    selectedDetail.value = detail
    if (msg.status === 'unread') {
      await setSMSRead(msg.id, true)
      msg.status = 'read'
    }
  } catch (e) {
    error.value = e instanceof Error ? e.message : '加载短信详情失败'
  }
}

function closeMobileDetail() {
  isMobileDetailVisible.value = false
}

onMounted(() => {
  loadList(true)
})

function formatTime(iso: string) {
  if (!iso) return ''
  return new Date(iso).toLocaleString()
}
</script>

<template>
  <div class="sms-app" :class="{'mobile-detail-open': isMobileDetailVisible}">
    
    <div class="sms-sidebar card-base">
      <div class="sidebar-header">
        <h2>收件箱</h2>
        <button class="action-btn" @click="loadList(true)" title="刷新">
          <RefreshCw :size="18" :class="{'spin': busy}" />
        </button>
      </div>
      
      <div class="search-bar">
        <Search :size="16" class="search-icon text-muted" />
        <input type="text" placeholder="搜索短信..." class="search-input" />
      </div>

      <div class="msg-list" @scroll="(e) => {
        const t = e.target as HTMLElement
        if (t.scrollHeight - t.scrollTop - t.clientHeight < 50 && hasMore && !busy) {
          page++; loadList();
        }
      }">
        <div v-if="items.length === 0 && !busy" class="empty-state">
          <MessageSquare :size="32" class="text-muted" />
          <p>收件箱为空</p>
        </div>
        
        <div 
          v-for="msg in items" 
          :key="msg.id" 
          class="msg-item"
          :class="{ active: selectedId === msg.id }"
          @click="selectMsg(msg)"
        >
          <div class="msg-avatar" :class="{'bg-accent': msg.status === 'unread', 'bg-interactive': msg.status !== 'unread'}">
            {{ msg.sender.charAt(0) || '#' }}
          </div>
          <div class="msg-preview-info">
            <div class="msg-item-header">
              <span class="sender font-semibold" :class="{'text-primary': msg.status==='unread'}">{{ msg.sender }}</span>
              <span class="time text-muted">{{ formatTime(msg.received_at).split(' ')[0] }}</span>
            </div>
            <div class="preview-text text-secondary" :class="{'font-bold text-primary': msg.status === 'unread'}">
              {{ msg.body }}
            </div>
          </div>
          <div v-if="msg.status === 'unread'" class="unread-dot pulse-success"></div>
        </div>
        
        <div v-if="busy && items.length > 0" class="loading-more text-muted">加载中...</div>
      </div>
    </div>
    
    <div class="sms-detail-view card-base">
      <div class="mobile-detail-header" @click="closeMobileDetail">
        <button class="action-btn"><span class="back-arrow">←</span> 返回短信列表</button>
      </div>
      
      <div v-if="!selectedId" class="empty-detail">
        <div class="empty-icon-wrap">
          <MessageSquare :size="48" class="text-muted" />
        </div>
        <h3>选择一条短信</h3>
        <p class="text-muted">点击左侧列表查看短信详细内容</p>
      </div>
      
      <div v-else-if="!selectedDetail" class="loading-detail">
        <RefreshCw class="spin text-accent" :size="32" />
      </div>
      
      <div v-else class="detail-content">
        <div class="detail-header">
          <div class="sender-info">
            <div class="large-avatar bg-accent-light text-accent">
              <Phone :size="24" />
            </div>
            <div>
              <h2 class="sender-number">{{ selectedDetail.sender }}</h2>
              <span class="receive-time text-muted">{{ formatTime(selectedDetail.received_at) }}</span>
            </div>
          </div>
          
        </div>
        
        <div class="message-bubble-area">
          <div class="message-bubble">
            {{ selectedDetail.body }}
          </div>
        </div>
        
        <details class="technical-details">
          <summary class="text-muted">
            <Info :size="16" /> 查看技术详情
          </summary>
          <div class="tech-content text-mono">
            <p><strong>Message ID:</strong> {{ selectedDetail.id }}</p>
            <p><strong>编码:</strong> {{ selectedDetail.encoding || '未知' }}</p>
            <p><strong>设备 ID:</strong> {{ selectedDetail.device_id }}</p>
            <p><strong>状态:</strong> {{ selectedDetail.status }}</p>
          </div>
        </details>
      </div>
    </div>
    
  </div>
</template>

<style scoped>
.sms-app {
  display: grid;
  grid-template-columns: 350px 1fr;
  gap: 24px;
  height: calc(100vh - 128px);
  min-height: 500px;
}

/* Sidebar List */
.sms-sidebar {
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.sidebar-header {
  padding: 24px 24px 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid var(--border-subtle);
}

.sidebar-header h2 {
  font-size: 1.25rem;
  margin: 0;
}

.action-btn {
  background: transparent;
  border: none;
  color: var(--text-secondary);
  cursor: pointer;
  padding: 8px;
  border-radius: var(--radius-sm);
  transition: all 0.2s;
}
.action-btn:hover { background-color: var(--bg-interactive); color: var(--text-primary); }
.spin { animation: spin 1s linear infinite; }

.search-bar {
  padding: 16px 24px;
  position: relative;
  border-bottom: 1px solid var(--border-subtle);
}

.search-icon {
  position: absolute;
  left: 40px;
  top: 50%;
  transform: translateY(-50%);
}

.search-input {
  width: 100%;
  height: 40px;
  border: 1px solid var(--border-strong);
  border-radius: 99px;
  padding: 0 16px 0 40px;
  background-color: var(--bg-interactive);
  transition: all 0.2s;
}
.search-input:focus {
  outline: none;
  background-color: var(--bg-surface);
  border-color: var(--accent);
  box-shadow: 0 0 0 3px var(--accent-light);
}

.msg-list {
  flex: 1;
  overflow-y: auto;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.empty-state {
  text-align: center;
  padding: 40px 20px;
  color: var(--text-muted);
}

.msg-item {
  display: flex;
  gap: 16px;
  padding: 16px;
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
}

.msg-item:hover {
  background-color: var(--bg-interactive);
}

.msg-item.active {
  background-color: var(--accent-light);
}

.msg-avatar {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  color: var(--bg-surface);
  flex-shrink: 0;
}
.bg-accent { background-color: var(--accent); }
.bg-interactive { background-color: var(--text-muted); }

.msg-preview-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.msg-item-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 6px;
}

.sender { font-size: 0.95rem; }
.time { font-size: 0.8rem; }
.preview-text {
  font-size: 0.9rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.font-bold { font-weight: 600; }

.unread-dot {
  position: absolute;
  top: 16px;
  right: 16px;
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

.pulse-success {
  background-color: var(--accent);
  box-shadow: 0 0 0 0 rgba(0, 157, 245, 0.4);
  animation: pulse-accent 2s infinite;
}
@keyframes pulse-accent {
  0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(0, 157, 245, 0.4); }
  70% { transform: scale(1); box-shadow: 0 0 0 6px rgba(0, 157, 245, 0); }
  100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(0, 157, 245, 0); }
}

.loading-more {
  text-align: center;
  padding: 16px;
  font-size: 0.85rem;
}

/* Detail View */
.sms-detail-view {
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.empty-detail {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
}
.empty-icon-wrap {
  width: 96px;
  height: 96px;
  border-radius: 50%;
  background-color: var(--bg-interactive);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 24px;
}

.loading-detail {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
}

.detail-content {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.detail-header {
  padding: 32px 40px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid var(--border-subtle);
}

.sender-info {
  display: flex;
  align-items: center;
  gap: 20px;
}

.large-avatar {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.sender-number {
  font-size: 1.5rem;
  margin: 0 0 4px 0;
}

.receive-time {
  font-size: 0.9rem;
}

.message-bubble-area {
  flex: 1;
  padding: 40px;
  overflow-y: auto;
  background-color: var(--bg-interactive);
}

.message-bubble {
  background-color: var(--bg-surface);
  padding: 24px 32px;
  border-radius: var(--radius-xl);
  border-top-left-radius: 4px;
  font-size: 1.1rem;
  line-height: 1.8;
  color: var(--text-primary);
  box-shadow: var(--shadow-sm);
  max-width: 80%;
  white-space: pre-wrap;
}

.technical-details {
  padding: 24px 40px;
  background-color: var(--bg-surface);
  border-top: 1px solid var(--border-subtle);
}

.technical-details summary {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  font-size: 0.9rem;
  font-weight: 500;
  user-select: none;
}

.tech-content {
  margin-top: 16px;
  padding: 16px;
  background-color: var(--bg-interactive);
  border-radius: var(--radius-md);
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.tech-content p {
  margin: 0;
}

.mobile-detail-header {
  display: none;
  padding: 16px;
  border-bottom: 1px solid var(--border-subtle);
  background-color: var(--bg-surface);
}

@media (max-width: 1024px) {
  .sms-app {
    grid-template-columns: 300px 1fr;
  }
}

@media (max-width: 768px) {
  .sms-app {
    grid-template-columns: 1fr;
    height: auto;
  }
  .sms-detail-view {
    display: none;
  }
  .sms-app.mobile-detail-open .sms-sidebar {
    display: none;
  }
  .sms-app.mobile-detail-open .sms-detail-view {
    display: flex;
    height: calc(100vh - 128px);
  }
  .mobile-detail-header {
    display: flex;
  }
  .back-arrow {
    margin-right: 8px;
    font-size: 1.1em;
  }
}
</style>
