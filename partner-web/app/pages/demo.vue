<script setup lang="ts">
definePageMeta({ layout: false })
useHead({ title: 'ЕшьКуш — еда с разумным выбором' })
onMounted(() => navigateTo('/shop', { replace: true }))
</script>

<template>
  <div class="store-entry">
    <BrandLogo /><p>Находим вкусное рядом…</p>
  </div>
</template>

<style scoped>
.store-entry{min-height:100vh;display:flex;align-items:center;justify-content:center;flex-direction:column;gap:18px;background:#faf9f5;color:#6d9c65;font-family:Stolzl,sans-serif}
</style>
