import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, SessionContextUsage, ThemeKey } from 'claude-code'

import type { Fill, Limit } from '../types'

const limits = atom({ plugin: 'usage-gauge', key: 'limits' } as const, [] as Limit[])
const fill = atom({ plugin: 'usage-gauge', key: 'fill' } as const, null as Fill | null)
const model = atom({ plugin: 'usage-gauge', key: 'model' } as const, null as string | null)
const compactions = atom({ plugin: 'usage-gauge', key: 'compactions' } as const, 0)

const WIDTH = 10
const NARROW = 100
const LABELS: Record<string, string> = { five_hour: 'Session', seven_day: 'Week' }

const ICONS: Record<string, string> = {
  fable: '\u{F14F7}',
  opus: '\u{F075A}',
  sonnet: '\u{F03EB}',
  haiku: '\u{F024A}',
}

export const modelLabel = (name: string) => {
  const short = name.replace(/^claude-/, '')
  const icon = ICONS[Object.keys(ICONS).find(k => short.toLowerCase().includes(k)) ?? '']

  return icon ? `${icon} ${short}` : short
}

const COMPACT_ICON = '\u{F0615}'

export const compactColor = (count: number): ThemeKey =>
  count >= 10 ? 'error' : count >= 4 ? 'warning' : 'subtle'

export const bar = (percent: number) => {
  const filled = Math.round((Math.min(percent, 100) / 100) * WIDTH)

  return '█'.repeat(filled) + '░'.repeat(WIDTH - filled)
}

export const colorFor = (percent: number): ThemeKey =>
  percent >= 80 ? 'error' : percent >= 50 ? 'warning' : 'subtle'

export const until = (resetsAt: string | undefined, now: number) => {
  if (!resetsAt) {
    return ''
  }

  const minutes = Math.max(0, Math.round((Date.parse(resetsAt) - now) / 60000))
  const days = Math.floor(minutes / 1440)
  const hours = Math.floor((minutes % 1440) / 60)

  return days > 0 ? `${days}d${hours}h` : hours > 0 ? `${hours}h${minutes % 60}m` : `${minutes}m`
}

const short = (n: number) =>
  n >= 1_000_000 ? `${+(n / 1_000_000).toFixed(1)}M` : `${Math.round(n / 1000)}k`

const toFill = (c: SessionContextUsage): Fill => {
  const b = c.breakdown

  return {
    tokens: c.tokens ?? null,
    window: c.window,
    percent: c.percent ?? null,
    compact: b?.isAutoCompactEnabled && b.rawMaxTokens < c.window ? b.rawMaxTokens : null,
  }
}

export const contextPercent = (f: Fill) =>
  f.tokens === null
    ? null
    : f.compact === null
      ? (f.percent ?? 0)
      : Math.round((f.tokens / f.compact) * 100)

export const contextLabel = (f: Fill) => {
  const limit = f.compact ?? f.window
  const percent = contextPercent(f)

  return f.tokens === null
    ? `ctx –/${short(limit)}`
    : `ctx ${short(f.tokens)}/${short(limit)} (${percent}%)`
}

const refresh = async ($: EngineInterface) => {
  const { context } = await $.session.usage({ breakdown: 'summary' })
  await update($, fill, () => toFill(context))
  const name = await $.session.model()
  await update($, model, () => name)
}

export const gauges = (all: Limit[]) =>
  Object.keys(LABELS).flatMap(kind => {
    const limit = all.find(l => l.kind === kind)

    return limit ? [{ ...limit, label: LABELS[kind] ?? kind }] : []
  })

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    const { rateLimits } = await $.session.usage()
    await update($, limits, () => rateLimits)
    await refresh($)

    return result
  })

  on('session.compact', async ($, e, next) => {
    const result = await next(e)

    if (!('skip' in result && result.skip) && e.trigger !== 'precompute' && !e.agentId) {
      await update($, compactions, n => n + 1)
    }

    return result
  })

  on('session.measure', async ($, e, next) => {
    await update($, limits, () => e.rateLimits)

    if (e.changed.includes('context')) {
      await refresh($)
    }

    return next(e)
  })

  on('ui.render', { component: 'SessionMode' }, async ($, e, next) => {
    const shown = gauges(await read($, limits))
    const context = await read($, fill)
    const name = await read($, model)
    const compacted = await read($, compactions)

    if (shown.length === 0 && context === null && name === null) {
      return next(e)
    }

    const { Box, Text } = $.ui.resolve(e)
    const now = await $.clock.now()
    const isNarrow = (e.viewport?.columns ?? NARROW) < NARROW
    const hasModes = e.props.modes.length > 0

    return (
      <Box flexDirection="row" flexShrink={0}>
        {hasModes ? <Box marginRight={3}>{await next(e)}</Box> : ''}
        {name === null ? '' : <Text>{modelLabel(name)}   </Text>}
        {compacted === 0 ? '' : (
          <Text color={compactColor(compacted)} dimColor={compacted <= 3}>
            {COMPACT_ICON} {compacted}{'   '}
          </Text>
        )}
        {shown.map((g, i) => {
          const left = until(g.resetsAt, now)

          return (
            <Text key={g.kind}>
              {i > 0 ? '   ' : ''}
              <Text dimColor>{g.label} </Text>
              {isNarrow ? '' : <Text color={colorFor(g.percentUsed)}>{bar(g.percentUsed)} </Text>}
              <Text color={colorFor(g.percentUsed)}>{Math.round(g.percentUsed)}%</Text>
              {left ? <Text dimColor> · {left}</Text> : ''}
            </Text>
          )
        })}
        {context === null ? '' : (
          <Text>
            {shown.length > 0 ? '   ' : ''}
            {(contextPercent(context) ?? 0) < 50
              ? <Text dimColor>{contextLabel(context)}</Text>
              : <Text color={colorFor(contextPercent(context) ?? 0)}>{contextLabel(context)}</Text>}
          </Text>
        )}
      </Box>
    )
  })
}
