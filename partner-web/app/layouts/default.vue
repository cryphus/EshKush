<script setup lang="ts">
const route = useRoute()
const auth = useAuthStore()

const links = [
  { label: 'Аналитика', icon: 'i-lucide-layout-dashboard', to: '/' },
  { label: 'Точки', icon: 'i-lucide-store', to: '/points' },
  { label: 'Предложения', icon: 'i-lucide-package', to: '/products' },
  { label: 'Заказы', icon: 'i-lucide-receipt', to: '/orders' },
  { label: 'Демонстрация', icon: 'i-lucide-play', to: '/demo' }
]

const pageTitle = computed(() => (route.meta.title as string) || 'EshKush Partner')

function handleLogout() {
  auth.logout()
  navigateTo('/login')
}
</script>

<template>
  <UDashboardGroup unit="rem">
    <UDashboardSidebar
      collapsible
      resizable
      :min-size="14"
      :default-size="16"
      :max-size="22"
    >
      <template #header="{ collapsed }">
        <div class="flex items-center gap-2 px-1 py-1">
          <div class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-primary text-inverted font-bold">
            E
          </div>
          <span
            v-if="!collapsed"
            class="font-semibold text-highlighted"
          >EshKush Partner</span>
        </div>
      </template>

      <template #default="{ collapsed }">
        <UNavigationMenu
          :items="links"
          :collapsed="collapsed"
          orientation="vertical"
        />
      </template>

      <template #footer="{ collapsed }">
        <div
          class="flex items-center gap-2 px-1 py-2"
          :class="collapsed ? 'flex-col' : ''"
        >
          <UAvatar
            :text="auth.user?.username?.slice(0, 2)?.toUpperCase()"
            size="sm"
          />
          <div
            v-if="!collapsed"
            class="min-w-0 flex-1"
          >
            <p class="truncate text-sm font-medium text-highlighted">
              {{ auth.user?.username }}
            </p>
            <p class="truncate text-xs text-muted capitalize">
              {{ auth.user?.role }}
            </p>
          </div>
          <UButton
            icon="i-lucide-log-out"
            color="neutral"
            variant="ghost"
            size="sm"
            aria-label="Выйти"
            @click="handleLogout"
          />
        </div>
      </template>
    </UDashboardSidebar>

    <UDashboardPanel>
      <template #header>
        <UDashboardNavbar :title="pageTitle">
          <template #leading>
            <UDashboardSidebarToggle />
          </template>
        </UDashboardNavbar>
      </template>

      <template #body>
        <slot />
      </template>
    </UDashboardPanel>
  </UDashboardGroup>
</template>
