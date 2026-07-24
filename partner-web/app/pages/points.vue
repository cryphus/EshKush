<script setup lang="ts">
import type { Point } from '~/types/api'

definePageMeta({ title: 'Точки' })

const { request } = useApi()
const toast = useToast()
const { points, products, loading, error, refresh } = usePartnerData()

onMounted(refresh)

function productCount(pointId: number) {
  return products.value.filter(p => p.point_id === pointId).length
}

const isFormOpen = ref(false)
const editing = ref<Point | null>(null)
const saving = ref(false)
const form = reactive({
  name: '',
  address: '',
  openingHours: '',
  closingHours: ''
})

const timeRe = /^([01]?\d|2[0-3]):[0-5]\d$/

function openEdit(p: Point) {
  editing.value = p
  form.name = p.name
  form.address = p.address
  form.openingHours = p.opening_hours
  form.closingHours = p.closing_hours
  isFormOpen.value = true
}

async function submitForm() {
  if (!editing.value) return
  if (!form.name.trim() || !form.address.trim()) {
    toast.add({ title: 'Укажите название и адрес', color: 'warning' })
    return
  }
  for (const t of [form.openingHours, form.closingHours]) {
    if (t.trim() && !timeRe.test(t.trim())) {
      toast.add({ title: 'Часы работы должны быть в формате HH:mm', color: 'warning' })
      return
    }
  }
  saving.value = true
  try {
    await request(`/points/${editing.value.id}`, {
      method: 'PUT',
      body: {
        name: form.name.trim(),
        address: form.address.trim(),
        opening_hours: form.openingHours.trim(),
        closing_hours: form.closingHours.trim()
      }
    })
    isFormOpen.value = false
    await refresh()
    toast.add({ title: 'Точка обновлена', color: 'success' })
  } catch (e) {
    toast.add({ title: 'Не удалось сохранить', description: getErrorMessage(e), color: 'error' })
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="p-4 sm:p-6 flex flex-col gap-6">
    <UAlert
      v-if="error"
      color="error"
      variant="soft"
      :title="error"
    />

    <div
      v-if="loading"
      class="flex justify-center py-16"
    >
      <UIcon
        name="i-lucide-loader-2"
        class="animate-spin size-8 text-muted"
      />
    </div>

    <p
      v-else-if="points.length === 0"
      class="text-center text-muted py-16"
    >
      У вас пока нет торговых точек
    </p>

    <div
      v-else
      class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4"
    >
      <UCard
        v-for="p in points"
        :key="p.id"
      >
        <div class="flex items-start justify-between gap-2">
          <div class="flex items-center gap-3 min-w-0">
            <div class="flex size-10 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary">
              <UIcon
                name="i-lucide-store"
                class="size-5"
              />
            </div>
            <div class="min-w-0">
              <p class="font-semibold text-highlighted truncate">
                {{ p.name }}
              </p>
              <div
                v-if="p.rating > 0"
                class="flex items-center gap-1 text-xs text-muted"
              >
                <UIcon
                  name="i-lucide-star"
                  class="size-3.5 text-amber-500"
                />
                {{ p.rating.toFixed(1) }}
              </div>
            </div>
          </div>
          <UButton
            icon="i-lucide-pencil"
            color="neutral"
            variant="ghost"
            size="sm"
            @click="openEdit(p)"
          />
        </div>

        <div class="mt-4 flex flex-col gap-2 text-sm text-muted">
          <div class="flex items-center gap-2">
            <UIcon
              name="i-lucide-map-pin"
              class="size-4 shrink-0"
            />
            <span class="truncate">{{ p.address }}</span>
          </div>
          <div class="flex items-center gap-2">
            <UIcon
              name="i-lucide-clock"
              class="size-4 shrink-0"
            />
            <span>{{ p.opening_hours && p.closing_hours ? `${p.opening_hours}–${p.closing_hours}` : 'Часы работы не указаны' }}</span>
          </div>
          <div class="flex items-center gap-2">
            <UIcon
              name="i-lucide-package"
              class="size-4 shrink-0"
            />
            <span>Предложений: {{ productCount(p.id) }}</span>
          </div>
        </div>
      </UCard>
    </div>

    <UModal
      v-model:open="isFormOpen"
      title="Редактировать точку"
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
          <UFormField label="Адрес">
            <UInput
              v-model="form.address"
              class="w-full"
            />
          </UFormField>
          <div class="grid grid-cols-2 gap-3">
            <UFormField label="Открытие (HH:mm)">
              <UInput
                v-model="form.openingHours"
                class="w-full"
              />
            </UFormField>
            <UFormField label="Закрытие (HH:mm)">
              <UInput
                v-model="form.closingHours"
                class="w-full"
              />
            </UFormField>
          </div>
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
          Сохранить
        </UButton>
      </template>
    </UModal>
  </div>
</template>
