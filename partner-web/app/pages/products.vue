<script setup lang="ts">
import type { Product } from '~/types/api'

definePageMeta({ title: 'Предложения' })

const { request } = useApi()
const toast = useToast()
const { points, products, loading, error, refresh, pointName } = usePartnerData()

onMounted(refresh)

const pointFilter = ref<number | null>(null)
const filteredProducts = computed(() =>
  pointFilter.value === null
    ? products.value
    : products.value.filter(p => p.point_id === pointFilter.value)
)

const pointFilterOptions = computed(() => [
  { label: 'Все точки', value: null },
  ...points.value.map(p => ({ label: p.name, value: p.id }))
])

const money = new Intl.NumberFormat('ru-RU', { style: 'currency', currency: 'RUB', maximumFractionDigits: 0 })

// ── Форма создания/редактирования ────────────────────────────────────────────

const isFormOpen = ref(false)
const editing = ref<Product | null>(null)
const saving = ref(false)
const form = reactive({
  name: '',
  description: '',
  price: '',
  weight: '',
  pointId: undefined as number | undefined,
  available: true
})

function openCreate() {
  editing.value = null
  form.name = ''
  form.description = ''
  form.price = ''
  form.weight = ''
  form.pointId = points.value[0]?.id
  form.available = true
  isFormOpen.value = true
}

function openEdit(p: Product) {
  editing.value = p
  form.name = p.name
  form.description = p.description
  form.price = String(Math.round(p.price))
  form.weight = p.weight > 0 ? String(Math.round(p.weight)) : ''
  form.pointId = p.point_id
  form.available = p.is_available
  isFormOpen.value = true
}

const netForPrice = computed(() => {
  const price = Number(form.price)
  if (!price || price <= 0) return null
  return price * (1 - PLATFORM_COMMISSION)
})

async function submitForm() {
  const price = Number(form.price)
  if (!form.name.trim() || !form.description.trim() || !price || price <= 0 || !form.pointId) {
    toast.add({ title: 'Заполните название, описание, цену и точку', color: 'warning' })
    return
  }
  saving.value = true
  try {
    const point = points.value.find(p => p.id === form.pointId)!
    const payload = {
      name: form.name.trim(),
      description: form.description.trim(),
      price,
      weight: Number(form.weight) || 0,
      point_id: form.pointId,
      partner_id: point.partner_id,
      is_available: form.available
    }
    if (editing.value) {
      await request(`/products/${editing.value.id}`, { method: 'PUT', body: payload })
    } else {
      await request('/products/', { method: 'POST', body: { ...payload, is_active: true } })
    }
    isFormOpen.value = false
    await refresh()
    toast.add({ title: editing.value ? 'Предложение обновлено' : 'Предложение создано', color: 'success' })
  } catch (e) {
    toast.add({ title: 'Не удалось сохранить', description: getErrorMessage(e), color: 'error' })
  } finally {
    saving.value = false
  }
}

async function toggleAvailable(p: Product) {
  try {
    await request(`/products/${p.id}`, { method: 'PUT', body: { is_available: !p.is_available } })
    await refresh()
  } catch (e) {
    toast.add({ title: 'Не удалось изменить', description: getErrorMessage(e), color: 'error' })
  }
}

async function deleteProduct(p: Product) {
  try {
    await request(`/products/${p.id}`, { method: 'DELETE' })
    await refresh()
    toast.add({ title: `«${p.name}» удалено`, color: 'success' })
  } catch {
    toast.add({ title: 'Удаление доступно только администратору', color: 'warning' })
  }
}

const columns = [
  { accessorKey: 'name', header: 'Название' },
  { accessorKey: 'point', header: 'Точка' },
  { accessorKey: 'price', header: 'Цена' },
  { accessorKey: 'available', header: 'Доступен' },
  { accessorKey: 'actions', header: '' }
]
</script>

<template>
  <div class="p-4 sm:p-6 flex flex-col gap-6">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <USelect
        v-model="pointFilter"
        :items="pointFilterOptions"
        value-key="value"
        class="w-56"
      />
      <UButton
        icon="i-lucide-plus"
        :disabled="points.length === 0"
        @click="openCreate"
      >
        Новое предложение
      </UButton>
    </div>

    <UAlert
      v-if="error"
      color="error"
      variant="soft"
      :title="error"
    />

    <UCard :ui="{ body: 'p-0 sm:p-0' }">
      <UTable
        :data="filteredProducts"
        :columns="columns"
        :loading="loading"
      >
        <template #name-cell="{ row }">
          <div class="flex flex-col">
            <span class="font-medium text-highlighted">{{ row.original.name }}</span>
            <span
              v-if="row.original.description"
              class="text-xs text-muted truncate max-w-xs"
            >{{ row.original.description }}</span>
          </div>
        </template>
        <template #point-cell="{ row }">
          {{ pointName(row.original.point_id) }}
        </template>
        <template #price-cell="{ row }">
          <span class="font-semibold text-primary">{{ money.format(row.original.price) }}</span>
        </template>
        <template #available-cell="{ row }">
          <USwitch
            :model-value="row.original.is_available"
            @update:model-value="() => toggleAvailable(row.original)"
          />
        </template>
        <template #actions-cell="{ row }">
          <div class="flex justify-end gap-1">
            <UButton
              icon="i-lucide-pencil"
              color="neutral"
              variant="ghost"
              size="sm"
              @click="openEdit(row.original)"
            />
            <UButton
              icon="i-lucide-trash-2"
              color="error"
              variant="ghost"
              size="sm"
              @click="deleteProduct(row.original)"
            />
          </div>
        </template>
      </UTable>
      <p
        v-if="!loading && filteredProducts.length === 0"
        class="text-center text-muted text-sm py-10"
      >
        Нет предложений. Добавьте первое.
      </p>
    </UCard>

    <UModal
      v-model:open="isFormOpen"
      :title="editing ? 'Редактировать предложение' : 'Новое предложение'"
    >
      <template #body>
        <form
          class="flex flex-col gap-4"
          @submit.prevent="submitForm"
        >
          <UFormField label="Название">
            <UInput
              v-model="form.name"
              class="w-full"
            />
          </UFormField>
          <UFormField
            label="Описание"
            required
          >
            <UTextarea
              v-model="form.description"
              class="w-full"
              :rows="3"
            />
          </UFormField>
          <div class="grid grid-cols-2 gap-3">
            <UFormField label="Цена, ₽">
              <UInput
                v-model="form.price"
                type="number"
                class="w-full"
              />
            </UFormField>
            <UFormField label="Вес, г">
              <UInput
                v-model="form.weight"
                type="number"
                class="w-full"
              />
            </UFormField>
          </div>
          <UFormField label="Точка">
            <USelect
              v-model="form.pointId"
              :items="points.map(p => ({ label: p.name, value: p.id }))"
              value-key="value"
              class="w-full"
            />
          </UFormField>
          <div class="flex items-center justify-between">
            <span class="text-sm">Доступен для заказа</span>
            <USwitch v-model="form.available" />
          </div>
          <UAlert
            v-if="netForPrice"
            color="success"
            variant="soft"
            icon="i-lucide-info"
            :title="`Вы получите ${money.format(netForPrice)} за бокс (комиссия платформы 14%)`"
          />
        </form>
      </template>
      <template #footer="{ close }">
        <UButton
          color="neutral"
          variant="ghost"
          @click="close"
        >
          Отмена
        </UButton>
        <UButton
          :loading="saving"
          @click="submitForm"
        >
          {{ editing ? 'Сохранить' : 'Создать' }}
        </UButton>
      </template>
    </UModal>
  </div>
</template>
