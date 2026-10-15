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
      <section class="photo-credits">
        <h2>Фотографии</h2><p>
          Спасибо авторам фотографий блюд: <a
            href="https://commons.wikimedia.org/wiki/File:Торт_Наполеон_(домашние_кусочки).jpg"
            target="_blank"
            rel="noopener"
          >Otets — «Наполеон»</a> (<a
            href="https://creativecommons.org/licenses/by-sa/3.0/lu/"
            target="_blank"
            rel="noopener"
          >CC BY-SA 3.0 LU</a>); <a
            href="https://commons.wikimedia.org/wiki/File:Vatrushka_cropped.jpeg"
            target="_blank"
            rel="noopener"
          >Kagor и Off-shell — ватрушка</a> (<a
            href="https://creativecommons.org/licenses/by-sa/3.0/"
            target="_blank"
            rel="noopener"
          >CC BY-SA 3.0</a>); <a
            href="https://commons.wikimedia.org/wiki/File:Pelmeni_Russian.jpg"
            target="_blank"
            rel="noopener"
          >Eugene Kim и Off-shell — пельмени</a> (<a
            href="https://creativecommons.org/licenses/by/2.0/"
            target="_blank"
            rel="noopener"
          >CC BY 2.0</a>). Файлы авторов сохранены без изменений.
        </p>
      </section>
      <footer class="shop-footer">
        <BrandLogo /><span>Еда с разумным выбором</span><NuxtLink to="/login">Кабинет партнёра ↗</NuxtLink>
      </footer>
    </main>
  </div>
</template>

<style scoped>
@import '~/assets/css/showcase.css';
.about-mascot{justify-self:center;width:290px;max-width:100%;object-fit:contain}.shop-header{justify-content:space-between}@media(max-width:760px){.about-mascot{position:absolute;width:100px;right:18px;bottom:25px}.shop-header>.secondary-btn{font-size:9px;padding:10px}}
.photo-credits{padding:25px 0 40px;max-width:800px}.photo-credits h2{font-size:16px;margin-bottom:12px}.photo-credits p{font-size:10px;color:#929b84;line-height:1.9}.photo-credits a{color:#6d9c65;text-decoration:underline}
</style>
