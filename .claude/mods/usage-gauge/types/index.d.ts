export type Limit = { kind: string; percentUsed: number; resetsAt?: string }
export type Fill = { tokens: number | null; window: number; percent: number | null; compact: number | null }

declare module 'claude-code' {
  interface PluginState {
    'usage-gauge': { limits: Limit[]; fill: Fill | null; model: string | null }
  }
}
