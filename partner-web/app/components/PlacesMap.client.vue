<script setup lang="ts">
import type * as Leaflet from 'leaflet'
import type { Point, Product } from '~/types/api'
import 'leaflet/dist/leaflet.css'

interface MapPlace extends Point { image_url: string | null }
interface MapOffer extends Product { quantity: number }
const props = defineProps<{ points: MapPlace[], offers: MapOffer[] }>()
const emit = defineEmits<{ offers: [id: number] }>()
const config = useRuntimeConfig()
const container = ref<HTMLElement>()
const selectedId = ref<number | null>(null)
const search = ref('')
const category = ref('Все')
const tileError = ref(false)
const locating = ref(false)
const locationError = ref('')
let L: typeof Leaflet | undefined
let map: Leaflet.Map | undefined
let markers: Leaflet.LayerGroup | undefined
let position: Leaflet.CircleMarker | undefined
let disposed = false
const kind = (p: MapPlace) => /булош|бисквит/i.test(p.name) ? 'Пекарни' : /максим»|bake/i.test(p.name) ? 'Кофейни' : /суши/i.test(p.name) ? 'Суши' : /додо|бистро|сорренто/i.test(p.name) ? 'Пицца' : 'Рестораны'
const places = computed(() => props.points.filter(p => (category.value === 'Все' || kind(p) === category.value) && `${p.name} ${p.address}`.toLowerCase().includes(search.value.toLowerCase())))
const selected = computed(() => places.value.find(p => p.id === selectedId.value))
const offersFor = (id: number) => props.offers.filter(p => p.point_id === id && p.is_active && p.is_available && p.quantity > 0)
const price = (id: number) => {
  const offers = offersFor(id)
  return offers.length ? Math.min(...offers.map(p => p.price)) : null
}
const photo = (p: MapPlace) => p.image_url?.startsWith('http') ? p.image_url : `${config.public.apiBase}${p.image_url || '/demo/media/bakeup.png'}`
function select(p: MapPlace) {
  selectedId.value = p.id
  if (map) map.setView([p.latitude, p.longitude], Math.max(map.getZoom(), 14), { animate: true })
  draw(false)
}
function draw(fit = true) {
  if (!map || !L || !markers) return
  markers.clearLayers()
  const index = createPlaceClusters(places.value, selectedId.value)
  const groups = index.getClusters([-180, -85, 180, 85], Math.floor(map.getZoom()))
  for (const group of groups) {
    if ('cluster' in group.properties) {
      const count = Number(group.properties.point_count)
      const clusterId = Number(group.properties.cluster_id)
      const [lon, lat] = group.geometry.coordinates
      if (lat === undefined || lon === undefined) continue
      const label = `Открыть ${countLabel(count, ['заведение', 'заведения', 'заведений'])}`
      const icon = L.divIcon({ className: 'eshkush-marker', html: `<span class="place-cluster">${count}<small>мест</small></span>`, iconSize: [48, 48], iconAnchor: [24, 24] })
      const marker = L.marker([lat, lon], { icon, title: label, keyboard: true }).on('click', () => {
        map?.setView([lat, lon], Math.min(index.getClusterExpansionZoom(clusterId), 19), { animate: true })
      }).addTo(markers)
      marker.getElement()?.setAttribute('aria-label', label)
      marker.getElement()?.setAttribute('data-point-count', String(count))
    } else {
      const p = places.value.find(p => p.id === group.properties.id)
      if (p) drawPlace(p)
    }
  }
  const active = selected.value
  if (active) drawPlace(active)

  if (fit && places.value.length) map.fitBounds(L.latLngBounds(places.value.map(p => [p.latitude, p.longitude] as [number, number])), { paddingTopLeft: [35, 90], paddingBottomRight: [35, selectedId.value ? 210 : 70], maxZoom: 14 })
}
function drawPlace(p: MapPlace) {
  if (!map || !L || !markers) return
  const amount = price(p.id)
  const compact = map.getZoom() < 13 && p.id !== selectedId.value
  const icon = L.divIcon({
    className: 'eshkush-marker',
    html: `<span class="place-marker ${compact ? 'compact-marker' : ''} ${p.id === selectedId.value ? 'is-selected' : ''}"><img src="/brand/bag.svg" alt="">${compact ? '' : amount === null ? 'ЕшьКуш' : `${amount} ₽`}</span>`,
    iconSize: compact ? [32, 32] : [78, 36], iconAnchor: compact ? [16, 35] : [39, 42]
  })
  const marker = L.marker([p.latitude, p.longitude], { icon, title: p.name, keyboard: true, riseOnHover: true, zIndexOffset: p.id === selectedId.value ? 1000 : 0 }).on('click', () => select(p)).addTo(markers)
  marker.getElement()?.setAttribute('aria-label', p.name)
  marker.getElement()?.setAttribute('data-point-count', '1')
}
function showAll() {
  selectedId.value = null
  draw()
}
function locate() {
  locationError.value = ''
  if (!navigator.geolocation) {
    locationError.value = 'Геолокация недоступна в этом браузере'
    return
  }
  locating.value = true
  navigator.geolocation.getCurrentPosition((value) => {
    locating.value = false
    if (disposed || !map || !L) return
    position?.remove()
    const coords: [number, number] = [value.coords.latitude, value.coords.longitude]
    position = L.circleMarker(coords, { radius: 8, color: '#fff', weight: 3, fillColor: '#6d9c65', fillOpacity: 1 }).addTo(map)
    map.setView(coords, 15)
  }, () => {
    locating.value = false
    locationError.value = 'Разрешите доступ к геопозиции, чтобы найти места рядом'
  }, { timeout: 10000 })
}
onMounted(async () => {
  L = await import('leaflet')
  if (disposed || !container.value) return
  map = L.map(container.value, { zoomControl: false, scrollWheelZoom: false }).setView([57.1522, 65.5472], 12)
  map.attributionControl.setPrefix(false).setPosition('topright')
  let loaded = false
  const tiles = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener">OpenStreetMap</a>'
  }).addTo(map)
  tiles.on('tileload', () => {
    loaded = true
    tileError.value = false
  })
  tiles.on('tileerror', () => {
    if (!loaded) tileError.value = true
  })
  markers = L.layerGroup().addTo(map)
  map.on('zoomend', () => draw(false))
  draw()
})
// Polling updates prices without moving the map away from the selected place.
watch(() => JSON.stringify(places.value.map(p => [p.id, p.latitude, p.longitude])), () => {
  if (!places.value.some(p => p.id === selectedId.value)) selectedId.value = null
  draw()
})
watch(() => JSON.stringify(props.offers.map(p => [p.id, p.price, p.quantity, p.is_available])), () => draw(false))
onBeforeUnmount(() => {
  disposed = true
  map?.remove()
  map = undefined
})
</script>

<template>
  <div
    class="places-map-shell"
    :class="{ 'has-selection': selected }"
  >
    <div
      ref="container"
      class="places-map-canvas"
      aria-label="Карта заведений Тюмени"
    />
    <div class="map-tools">
      <label class="map-search"><UIcon name="i-lucide-search" /><input
        v-model="search"
        placeholder="Заведение или адрес"
        aria-label="Поиск на карте"
      ></label>
      <div class="map-categories">
        <button
          v-for="c in ['Все', 'Пекарни', 'Кофейни', 'Пицца', 'Суши', 'Рестораны']"
          :key="c"
          :class="{ active: category === c }"
          @click="category = c"
        >
          {{ c }}
        </button>
      </div>
    </div>
    <div class="map-count">
      <span />{{ countLabel(places.length, ['место', 'места', 'мест']) }} · Тюмень
    </div>
    <p
      v-if="tileError"
      class="map-message"
    >
      Не удалось загрузить карту. Проверьте подключение к интернету.
    </p>
    <p
      v-if="locationError"
      class="map-message"
    >
      {{ locationError }}
    </p>
    <div class="map-controls">
      <button
        aria-label="Приблизить карту"
        @click="map?.zoomIn()"
      >
        <UIcon name="i-lucide-plus" />
      </button>
      <button
        aria-label="Отдалить карту"
        @click="map?.zoomOut()"
      >
        <UIcon name="i-lucide-minus" />
      </button>
      <button
        aria-label="Показать все заведения"
        @click="showAll"
      >
        <UIcon name="i-lucide-scan" />
      </button>
      <button
        :disabled="locating"
        aria-label="Моя геопозиция"
        @click="locate"
      >
        <UIcon :name="locating ? 'i-lucide-loader-circle' : 'i-lucide-locate-fixed'" />
      </button>
    </div>
    <article
      v-if="selected"
      class="map-place-card"
    >
      <img
        :src="photo(selected)"
        :alt="selected.name"
        class="map-place-photo"
      >
      <div class="map-place-info">
        <span class="map-place-kind">{{ kind(selected) }} <span>★ {{ selected.rating }}</span></span>
        <h2>{{ selected.name }}</h2>
        <p>{{ selected.address.replace('г. Тюмень, ', '') }}</p>
        <div class="map-place-bottom">
          <span>{{ countLabel(offersFor(selected.id).length, ['предложение', 'предложения', 'предложений']) }}<br>Забрать до {{ selected.closing_hours.slice(0, 5) }}</span><button
            :disabled="!offersFor(selected.id).length"
            @click="emit('offers', selected.id)"
          >
            Смотреть боксы <UIcon name="i-lucide-arrow-right" />
          </button>
        </div>
      </div>
      <button
        class="map-card-close"
        aria-label="Закрыть карточку заведения"
        @click="selectedId = null; draw(false)"
      >
        <UIcon name="i-lucide-x" />
      </button>
    </article>
    <div
      v-else
      class="map-hint"
    >
      <UIcon name="i-lucide-hand" /><span>{{ places.length ? 'Выберите место на карте' : 'Ничего не нашлось' }}<br><small>{{ places.length ? 'Вкусная еда ждёт вас рядом' : 'Попробуйте другой адрес или категорию' }}</small></span>
    </div>
  </div>
</template>

<style>
.places-map-shell{position:relative;isolation:isolate;border-radius:24px;overflow:hidden;height:650px;background:#f7f4ec;border:1px solid #e1e6d8}
.places-map-canvas{position:absolute;inset:0;z-index:0;font-family:Stolzl,sans-serif}
.places-map-canvas .leaflet-tile-pane{filter:saturate(.55) brightness(1.025)}
.places-map-canvas .leaflet-control-attribution{background:#fffdf5e8;font-size:9px;color:#73826a}
.place-marker{display:flex;align-items:center;justify-content:center;gap:6px;background:#6d9c65;border:2px solid #fff;color:#fff;border-radius:14px 14px 14px 3px;padding:6px 9px;box-shadow:0 3px 10px #284d3429;font:500 12px Stolzl,sans-serif;white-space:nowrap;transition:background .15s,transform .15s}
.place-marker img{width:14px;height:16px;filter:brightness(0) invert(1)}
.place-marker.is-selected{background:#346447;transform:scale(1.15);box-shadow:0 0 0 5px #91ca6d40}
.eshkush-marker:focus-visible{outline:3px solid #346447;outline-offset:4px;border-radius:14px}
.map-tools{position:absolute;z-index:5;top:22px;left:22px;right:65px;pointer-events:none}
.map-search{pointer-events:auto;display:flex;align-items:center;gap:10px;background:#fffdf9;border:1px solid #e0e6d8;box-shadow:0 3px 15px #34553712;border-radius:16px;padding:14px 17px;max-width:370px;color:#6d9c65}
.map-search input{background:none;border:0;outline:0;min-width:0;flex:1;font:12px Stolzl,sans-serif;color:#34472e}
.map-categories{display:flex;gap:7px;overflow:auto;padding:12px 0 3px;pointer-events:auto;scrollbar-width:none;width:max-content;max-width:100%}
.map-categories button{padding:9px 13px;border:1px solid #dce3d3;background:#fffdf9;border-radius:12px;color:#647a54;font:10px Stolzl,sans-serif;white-space:nowrap;box-shadow:0 2px 8px #284d3410}
.map-categories button.active{background:#e7f6d7;border-color:#6d9c65;color:#41763c}
.map-count{position:absolute;top:143px;left:25px;display:flex;gap:7px;align-items:center;background:#fffdf8ee;border-radius:9px;padding:8px 10px;font-size:10px;color:#647657;z-index:5}
.map-count>span{background:#6d9c65;width:6px;height:6px;border-radius:50%}
.map-controls{position:absolute;right:18px;bottom:28px;z-index:5;display:flex;flex-direction:column;gap:7px}
.map-controls button{display:grid;place-items:center;width:42px;height:42px;border:1px solid #dde5d3;border-radius:14px;background:#fffdf8;color:#6d9c65;box-shadow:0 3px 12px #284d3415;font-size:20px}
.map-controls button:last-child{border-radius:50%;margin-top:6px}
.map-place-card{position:absolute;z-index:6;bottom:22px;left:22px;display:flex;width:min(530px,calc(100% - 98px));background:#fffdf9;border-radius:20px;box-shadow:0 6px 32px #284d3420;overflow:hidden;min-height:166px}
.map-place-photo{width:145px;object-fit:cover;background:#e9eddf}
.map-place-info{padding:19px 20px;flex:1;min-width:0}
.map-place-kind{font-size:9px;color:#789164;display:flex;justify-content:space-between;padding-right:12px}
.map-place-card h2{font-size:16px;font-weight:500;color:#34472e;line-height:1.4;margin:8px 0}
.map-place-card p{font-size:10px;color:#87927c;line-height:1.5;margin:0}
.map-place-bottom{display:flex;align-items:center;justify-content:space-between;gap:15px;margin-top:14px}
.map-place-bottom>span{font-size:9px;line-height:1.7;color:#87927c}
.map-place-bottom button{background:#6d9c65;color:#fff;border:0;border-radius:11px;display:flex;align-items:center;gap:8px;font:10px Stolzl,sans-serif;padding:11px 13px;white-space:nowrap}
.map-card-close{position:absolute;right:7px;top:7px;display:grid;place-items:center;border:0;background:#fffdf9c9;border-radius:50%;color:#738568;width:24px;height:24px}
.map-hint{position:absolute;bottom:22px;left:22px;display:flex;gap:12px;align-items:center;background:#fffdf9ed;border:1px solid #e1e6d8;border-radius:16px;padding:15px 20px;z-index:5;font-size:12px;color:#547446}
.map-hint>.iconify{font-size:24px}.map-hint small{font-size:9px;color:#93a183}
.map-message{position:absolute;z-index:7;top:190px;left:22px;right:22px;width:max-content;max-width:calc(100% - 44px);background:#fffdf9;padding:12px;border-radius:12px;color:#7a765c;font-size:10px}
@media(max-width:760px){.places-map-shell{height:calc(100dvh - 220px);min-height:420px;border-radius:20px}.map-tools{top:20px;left:12px;right:12px}.map-search{max-width:100%;padding:13px}.map-count{left:15px;top:137px}.map-controls{right:12px;bottom:205px;gap:5px}.map-controls button{width:36px;height:36px;font-size:18px}.map-place-card{left:12px;right:12px;bottom:16px;width:auto;min-height:165px;border-radius:17px}.map-place-photo{width:95px}.map-place-info{padding:15px 13px}.map-place-card h2{font-size:13px;padding-right:10px}.map-place-card p{font-size:9px}.map-place-bottom{gap:7px;margin-top:10px}.map-place-bottom button{padding:9px;font-size:9px;gap:4px}.map-place-bottom>span{font-size:8px}.map-hint{left:12px;right:58px;bottom:20px;padding:13px;font-size:10px}.map-message{left:12px;right:12px;width:auto}.place-marker{font-size:11px}.places-map-canvas .leaflet-control-attribution{font-size:8px}}
</style>

<style>
.place-marker.compact-marker{width:32px;height:32px;padding:6px;border-radius:12px 12px 12px 3px}
</style>

<style>
@media(max-width:760px){.map-controls{flex-direction:row;bottom:85px}.map-controls button:last-child{margin-top:0}.places-map-shell.has-selection .map-controls{bottom:195px}}
</style>

<style>
.place-cluster{width:48px;height:48px;display:flex;flex-direction:column;align-items:center;justify-content:center;background:#346447;color:white;border:4px solid #dcecc9;border-radius:50%;box-shadow:0 3px 15px #284d3433;font:600 16px Stolzl,sans-serif}.place-cluster small{font-size:7px;font-weight:400;line-height:1.1}.eshkush-marker:hover .place-cluster{background:#547f4a}
</style>
