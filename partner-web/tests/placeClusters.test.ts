import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { createPlaceClusters } from '../app/utils/placeClusters.ts'

const points = JSON.parse(readFileSync(new URL('../../backend/public/demo/catalog/tyumen.json', import.meta.url), 'utf8')).map((p: { latitude: number, longitude: number }, i: number) => ({ ...p, id: i + 1 }))
test('city overview groups nearby venues without losing any locations', () => {
  const index = createPlaceClusters(points)
  const groups = index.getClusters([-180, -85, 180, 85], 11)
  assert.ok(groups.length < points.length)
  assert.equal(groups.reduce((sum, g) => sum + ('cluster' in g.properties ? Number(g.properties.point_count) : 1), 0), 30)
})
test('clusters expand and reveal every venue at street zoom', () => {
  const index = createPlaceClusters(points)
  const group = index.getClusters([-180, -85, 180, 85], 11).find(g => 'cluster' in g.properties)
  assert.ok(group && 'cluster_id' in group.properties)
  assert.ok(index.getClusterExpansionZoom(Number(group.properties.cluster_id)) > 11)
  const leaves = index.getClusters([-180, -85, 180, 85], 19)
  assert.equal(leaves.length, 30)
  assert.equal(new Set(leaves.map(g => g.properties.id)).size, 30)
})
test('a selected venue is excluded from groups so its own marker stays accessible', () => {
  const index = createPlaceClusters(points, 1)
  const leaves = index.getClusters([-180, -85, 180, 85], 19)
  assert.equal(leaves.length, 29)
  assert.ok(leaves.every(g => g.properties.id !== 1))
})
