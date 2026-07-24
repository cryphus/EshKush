<script setup lang="ts">
useHead({
  titleTemplate: title => title ? `${title} · EshKush Partner` : 'EshKush Partner',
  meta: [
    { name: 'viewport', content: 'width=device-width, initial-scale=1' }
  ],
  htmlAttrs: {
    lang: 'ru'
  }
})
</script>

<template>
  <UApp>
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </UApp>
</template>
