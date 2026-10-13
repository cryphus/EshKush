<script setup lang="ts">
definePageMeta({ layout: false })
useHead({ title: 'О ЕшьКуш — вкусно вам, хорошо планете' })
useColorMode().preference = 'light'
</script>

<template>
  <div class="shop-shell">
    <header class="shop-header">
      <NuxtLink to="/shop"><BrandLogo /></NuxtLink><NuxtLink
        to="/shop"
        class="secondary-btn"
      >К предложениям <UIcon name="i-lucide-arrow-right" /></NuxtLink>
    </header>
    <main class="shop-main">
      <section class="hero">
        <div class="hero-copy">
          <span class="eyebrow">ЕДА С РАЗУМНЫМ ВЫБОРОМ</span><h1>Вкусно вам.<br>Хорошо планете.</h1><p>ЕшьКуш объединяет тех, кто любит вкусную еду, и заведения, которые хотят, чтобы каждое блюдо нашло своего гостя.</p><NuxtLink
            to="/shop"
            class="primary-btn"
          >Найти свой бокс <UIcon name="i-lucide-arrow-right" /></NuxtLink>
        </div><img
          src="/brand/mascot.png"
          alt="Маскоты ЕшьКуш: планета и пакет с едой"
          width="290"
          height="290"
          class="about-mascot"
        >
      </section>
      <div class="how-it-works">
        <div><span>01 / ВЫБИРАЙТЕ</span><h3>Любимые места рядом</h3><p>Пекарни, кофейни и рестораны Тюмени на одной карте. Найдите интересное предложение по пути домой.</p></div><div><span>02 / СОХРАНЯЙТЕ</span><h3>Больше вкуса, меньше трат</h3><p>Выберите бокс, оформите заказ и сохраните код получения. Время выдачи указано в каждой карточке.</p></div><div><span>03 / ЗАБИРАЙТЕ</span><h3>Маленькое доброе дело</h3><p>Загляните в заведение, покажите код и заберите еду. Следите за своей экономией в профиле.</p></div>
      </div>
      <footer class="shop-footer">
        <BrandLogo /><span>Еда с разумным выбором</span><NuxtLink to="/login">Кабинет партнёра ↗</NuxtLink>
      </footer>
    </main>
  </div>
</template>

<style scoped>
@import '~/assets/css/showcase.css';
.about-mascot{justify-self:center;width:290px;max-width:100%;object-fit:contain}.shop-header{justify-content:space-between}@media(max-width:760px){.about-mascot{position:absolute;width:100px;right:18px;bottom:25px}.shop-header>.secondary-btn{font-size:9px;padding:10px}}
</style>
