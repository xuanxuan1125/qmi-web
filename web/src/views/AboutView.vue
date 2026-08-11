<script setup lang="ts">
import { onMounted } from 'vue'
import LoadingSkeleton from '../components/LoadingSkeleton.vue'
import { useVersionStore } from '../stores/version'

const version = useVersionStore()

onMounted(() => { void version.load() })
</script>

<template>
  <section class="page">
    <div class="page-title"><div><p class="eyebrow">BUILD</p><h1>关于</h1></div></div>
    <p v-if="version.error" class="error-banner">{{ version.error }}</p>
    <LoadingSkeleton v-else-if="!version.info" label="正在读取构建信息…" />
    <section v-else class="about-card">
      <div class="about-version"><span>QMI Web</span><strong>v{{ version.info.version }}</strong><p>SMS-only 安全模式</p></div>
      <dl class="field-list">
        <div><dt>提交</dt><dd><code>{{ version.info.commit }}</code></dd></div>
        <div><dt>构建时间（UTC）</dt><dd>{{ version.info.build_time }}</dd></div>
        <div><dt>Go</dt><dd>{{ version.info.go_version }}</dd></div>
        <div><dt>qmi-go</dt><dd>{{ version.info.qmi_go_version }}</dd></div>
        <div><dt>SMS decoder</dt><dd>{{ version.info.sms_decoder_version }}</dd></div>
        <div><dt>许可证</dt><dd>{{ version.info.license }}</dd></div>
      </dl>
    </section>
  </section>
</template>
