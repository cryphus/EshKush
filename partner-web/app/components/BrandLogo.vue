<template>
  <span
    class="eshkush-logo"
    aria-label="Ешь Куш"
  >
    <img
      src="/brand/mascot.png"
      alt=""
      width="64"
      height="64"
    >
    <span>Ешь<span class="logo-kush">Куш</span></span>
  </span>
</template>

<style scoped>
.eshkush-logo{display:inline-flex;align-items:center;gap:8px;white-space:nowrap;font-family:Stolzl,sans-serif;font-size:26px;font-weight:700;letter-spacing:-1.2px;color:#346447;line-height:1}
.eshkush-logo img{width:58px;height:58px;object-fit:contain}
.logo-kush{color:#6d9c65}
@media(max-width:760px){.eshkush-logo{font-size:22px;gap:5px}.eshkush-logo img{width:45px;height:45px}}
</style>
