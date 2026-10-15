import { describe, expect, test } from 'claude-code/testing'

import { bar, colorFor, contextLabel, gauges, until } from './register'

describe('usage gauge', () => {
  test('orders session before week and drops other windows', async () => {
    const shown = gauges([
      { kind: 'seven_day', percentUsed: 12 },
      { kind: 'spend_limit', percentUsed: 3 },
      { kind: 'five_hour', percentUsed: 34.5 },
    ])

    expect(shown.map(g => g.label)).toEqual(['Session', 'Week'])
  })

  test('fills the bar and colors by level', async () => {
    expect(bar(34.5)).toBe('███░░░░░░░')
    expect(bar(140)).toBe('██████████')
    expect(colorFor(20)).toBe('subtle')
    expect(colorFor(60)).toBe('warning')
    expect(colorFor(85)).toBe('error')
  })

  test('formats time to reset', async () => {
    const now = Date.parse('2026-10-12T12:00:00Z')
    expect(until('2026-10-12T15:12:00Z', now)).toBe('3h12m')
    expect(until('2026-10-15T14:00:00Z', now)).toBe('3d2h')
    expect(until(undefined, now)).toBe('')
  })

  test('labels the context window', async () => {
    expect(contextLabel({ tokens: 84_000, window: 1_000_000, percent: 8, compact: null })).toBe('ctx 84k/1M (8%)')
    expect(contextLabel({ tokens: null, window: 200_000, percent: null, compact: null })).toBe('ctx –/200k')
    expect(contextLabel({ tokens: null, window: 1_000_000, percent: null, compact: 250_000 })).toBe('ctx –/250k')
    expect(contextLabel({ tokens: 50_000, window: 1_000_000, percent: 5, compact: 250_000 })).toBe('ctx 50k/250k (20%)')
  })
})
