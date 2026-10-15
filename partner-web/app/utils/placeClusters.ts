import Supercluster from 'supercluster'

export function createPlaceClusters(points: { id: number, latitude: number, longitude: number }[], selectedId: number | null = null) {
  const index = new Supercluster<{ id: number }>({ radius: 140, maxZoom: 17, extent: 512 })
  index.load(points.filter(p => p.id !== selectedId).map(p => ({
    type: 'Feature' as const,
    geometry: { type: 'Point' as const, coordinates: [p.longitude, p.latitude] },
    properties: { id: p.id }
  })))
  return index
}
