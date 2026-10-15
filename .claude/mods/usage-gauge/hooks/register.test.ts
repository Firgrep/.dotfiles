import { describe, expect, test } from 'claude-code/testing'

import { bar, colorFor, compactColor, contextLabel, gauges, modelLabel, until } from './register'

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

  test('prefixes the model with a nerd font glyph and drops the claude- prefix', async () => {
    expect(modelLabel('claude-sonnet-5-5')).toBe('\u{F03EB} sonnet-5-5')
    expect(modelLabel('claude-opus-5-5')).toBe('\u{F075A} opus-5-5')
    expect(modelLabel('claude-haiku-5-5')).toBe('\u{F024A} haiku-5-5')
    expect(modelLabel('claude-fable-5-1')).toBe('\u{F14F7} fable-5-1')
    expect(modelLabel('mystery-1')).toBe('mystery-1')
  })

  test('colors the compaction count by how many have happened', async () => {
    expect(compactColor(1)).toBe('subtle')
    expect(compactColor(3)).toBe('subtle')
    expect(compactColor(4)).toBe('warning')
    expect(compactColor(9)).toBe('warning')
    expect(compactColor(10)).toBe('error')
  })
})
