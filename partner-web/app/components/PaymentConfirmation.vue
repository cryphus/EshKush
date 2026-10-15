<script setup lang="ts">
import QRCode from 'qrcode'

const props = defineProps<{ amount: number, method: string }>()
const emit = defineEmits<{ confirm: [], back: [] }>()
const bank = ref('Т-Банк')
const qr = ref('')
const qrError = ref(false)
const money = computed(() =>
  new Intl.NumberFormat('ru-RU', {
    style: 'currency',
    currency: 'RUB',
    maximumFractionDigits: 0
  }).format(props.amount)
)
watch(
  () => [props.amount, props.method],
  async () => {
    qrError.value = false
    try {
      qr.value = await QRCode.toDataURL(
        JSON.stringify({
          checkout: crypto.randomUUID(),
          merchant: 'ЕшьКуш',
          amount: props.amount,
          currency: 'RUB'
        }),
        { width: 210, margin: 2, color: { dark: '#346447', light: '#fffdf8' } }
      )
    } catch {
      qrError.value = true
    }
  },
  { immediate: true }
)
</script>

<template>
  <section class="payment-confirmation">
    <button
      class="flow-back"
      @click="emit('back')"
    >
      ← Способы оплаты
    </button>
    <div class="payment-merchant">
      <img
        src="/brand/mascot.png"
        alt=""
        width="44"
        height="44"
      >
      <div><strong>ЕшьКуш</strong><span>Оплата заказа</span></div>
      <UIcon name="i-lucide-shield-check" />
    </div>
    <div class="payment-amount">
      <span>К подтверждению</span><strong>{{ money }}</strong>
    </div>
    <template v-if="props.method === 'mobilePayment'">
      <div class="payment-qr">
        <img
          v-if="qr && !qrError"
          :src="qr"
          alt="QR-код оплаты СБП"
          width="210"
          height="210"
        >
        <p v-else-if="qrError">
          Выберите банк и подтвердите оплату ниже.
        </p>
        <span>Система быстрых платежей</span>
      </div>
      <fieldset class="bank-choices">
        <legend>Выберите банк</legend>
        <label
          v-for="name in ['Т-Банк', 'Сбер', 'Альфа-Банк']"
          :key="name"
          :class="{ selected: bank === name }"
        ><input
          v-model="bank"
          type="radio"
          name="bank"
          :value="name"
        ><span>{{ name }}</span><UIcon
          v-if="bank === name"
          name="i-lucide-check"
        /></label>
      </fieldset>
      <p class="payment-help">
        Проверьте получателя и сумму перед подтверждением.
      </p>
    </template>
    <template v-else>
      <div class="saved-card">
        <div>
          <UIcon name="i-lucide-credit-card" /><strong>Карта для покупок</strong><span>МИР</span>
        </div>
        <p>•••• &nbsp;•••• &nbsp;•••• &nbsp;4242</p>
        <small>Сохранённая карта</small>
      </div>
      <div class="payment-recap">
        <span>Получатель</span><strong>ЕшьКуш</strong><span>Способ оплаты</span><strong>Карта •••• 4242</strong>
      </div>
    </template>
    <button
      class="flow-primary"
      @click="emit('confirm')"
    >
      Подтвердить {{ money }}<UIcon name="i-lucide-lock-keyhole" />
    </button>
    <p class="payment-help">
      <UIcon name="i-lucide-package-check" />Код получения появится сразу после
      оплаты.
    </p>
  </section>
</template>

<style>
.payment-merchant {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 18px 0;
  border-bottom: 1px solid #e1e6d8;
}
.payment-merchant img {
  object-fit: contain;
}
.payment-merchant > div {
  display: grid;
  gap: 6px;
}
.payment-merchant strong {
  font-size: 14px;
  font-weight: 500;
}
.payment-merchant span {
  font-size: 10px;
  color: #929c85;
}
.payment-merchant > .iconify {
  margin-left: auto;
  font-size: 24px;
  color: #7da264;
}
.payment-amount {
  display: grid;
  gap: 12px;
  padding: 26px 0;
  text-align: center;
}
.payment-amount span {
  font-size: 10px;
  color: #8b997b;
}
.payment-amount strong {
  font-size: 36px;
  font-weight: 500;
  letter-spacing: -0.05em;
}
.saved-card {
  background: linear-gradient(120deg, #416a43, #76986a);
  color: #fff;
  border-radius: 20px;
  padding: 23px;
  margin: 4px 0 25px;
  box-shadow: 0 10px 25px #34553720;
}
.saved-card > div {
  display: flex;
  align-items: center;
  gap: 9px;
}
.saved-card strong {
  font-size: 10px;
  font-weight: 400;
}
.saved-card > div > span {
  margin-left: auto;
  font-size: 15px;
}
.saved-card p {
  margin: 28px 0 20px;
  font-size: 21px;
  letter-spacing: 0.04em;
}
.saved-card small {
  font-size: 9px;
  opacity: 0.7;
}
.payment-recap {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  font-size: 10px;
  margin-bottom: 25px;
}
.payment-recap > span {
  color: #8e9c7d;
}
.payment-recap strong {
  text-align: right;
  font-weight: 400;
}
.payment-help {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  font-size: 9px;
  color: #98a48b;
  line-height: 1.8;
  text-align: center;
  margin: 16px 0;
}
.payment-qr {
  display: flex;
  align-items: center;
  flex-direction: column;
  gap: 8px;
}
.payment-qr img {
  border-radius: 14px;
  max-width: 70%;
  height: auto;
}
.payment-qr > span {
  font-size: 10px;
  color: #8e9d7d;
}
.bank-choices {
  border: 0;
  padding: 0;
  margin: 24px 0;
}
.bank-choices legend {
  font-size: 11px;
  margin-bottom: 13px;
}
.bank-choices label {
  display: flex;
  align-items: center;
  gap: 9px;
  border: 1px solid #e0e6d7;
  border-radius: 12px;
  padding: 12px;
  margin-top: 8px;
  color: #728762;
  font-size: 11px;
}
.bank-choices input {
  accent-color: #6d9c65;
}
.bank-choices .selected {
  border-color: #6d9c65;
  background: #edf3e4;
}
.bank-choices .iconify {
  margin-left: auto;
}
.payment-steps {
  display: grid;
  gap: 15px;
  margin: 28px auto;
  max-width: 270px;
  text-align: left;
}
.payment-steps > div {
  display: flex;
  align-items: center;
  gap: 12px;
  color: #b3bba9;
  font-size: 11px;
}
.payment-steps > div.current {
  color: #6d9c65;
}
.payment-steps > div.done {
  color: #346447;
}
.payment-steps .iconify {
  font-size: 19px;
}
</style>
