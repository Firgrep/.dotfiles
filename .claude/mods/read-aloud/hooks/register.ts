import type { EngineInterface, Register } from 'claude-code'

import { Segmenter } from './segmenter'

// Spool directory the worker (bin/worker.py) watches. Written through `sh` so
// `$HOME` resolves, and renamed into place so the worker never reads half a file.
const SPOOL = '$HOME/.cache/claude-tts/spool'
const WORKER =
  'exec "$HOME/.local/share/claude-tts/.venv/bin/python" ' +
  '"$HOME/.claude/mods/read-aloud/bin/worker.py" "$HOME/.cache/claude-tts/spool"'

const DEFAULT_VOICE = 'af_heart'
const DEFAULT_SPEED = 1

// What the module holds in memory; `$.store` keeps the settings across sessions.
let enabled: boolean | undefined
let voice = DEFAULT_VOICE
let speed = DEFAULT_SPEED
let seq = 0
let isWorkerStarted = false
// The sentences of the latest reply, kept so `/speak replay` can say them again.
let lastReply: string[] = []
// Spool writes run one after another so sentences keep their order.
let writes: Promise<unknown> = Promise.resolve()

function spool($: EngineInterface, name: string, text: string) {
  writes = writes
    .then(() =>
      $.process.run(
        ['sh', '-c', `f="${SPOOL}/$1"; cat > "$f.tmp" && mv "$f.tmp" "$f"`, 'sh', name],
        { stdin: text, timeoutMs: 5000 },
      ),
    )
    .catch(() => undefined)

  return writes
}

function say($: EngineInterface, text: string) {
  return spool($, `${Date.now()}-${String(seq++).padStart(6, '0')}.txt`, text)
}

function stop($: EngineInterface) {
  return spool($, 'stop', String(Date.now()))
}

function writeConfig($: EngineInterface) {
  return spool($, 'config.json', JSON.stringify({ voice, speed }))
}

async function load($: EngineInterface) {
  if (enabled !== undefined) return
  enabled = (await $.store.get('enabled')) !== false
  voice = String((await $.store.get('voice')) ?? DEFAULT_VOICE)
  speed = Number((await $.store.get('speed')) ?? DEFAULT_SPEED)
}

// The worker lives as long as this module: spawn's child is killed when the
// loop ends or the module unloads. It is restarted a few times if it dies.
function startWorker($: EngineInterface) {
  if (isWorkerStarted) return
  isWorkerStarted = true

  void (async () => {
    await $.process.run(['sh', '-c', `mkdir -p "${SPOOL}" "$HOME/.cache/claude-tts/tmp"`])
    await writeConfig($)

    for (let attempt = 0; attempt < 4; attempt++) {
      const started = Date.now()
      try {
        for await (const piece of $.process.spawn({ argv: ['sh', '-c', WORKER] })) {
          if ('text' in piece) $.ui.log(piece.text.trimEnd(), { to: 'debug' })
        }
      } catch (error) {
        $.ui.log(`read-aloud: worker failed to start: ${String(error)}`, { to: 'debug' })
      }
      // A run that lasted a while was healthy; only quick deaths count.
      if (Date.now() - started > 60_000) attempt = -1
      await new Promise(resolve => setTimeout(resolve, 3000))
    }
    isWorkerStarted = false
    $.ui.toast('read-aloud: the speech worker keeps stopping. Is install.sh done?')
  })()
}

// Every sentence is remembered; it is only said while speech is on.
function speak($: EngineInterface, sentences: string[]) {
  lastReply.push(...sentences)
  if (!enabled) return
  for (const sentence of sentences) void say($, sentence)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const started = await next(e)
    await $.command.register({
      name: 'speak',
      description: 'Read replies aloud: on | off | stop | replay | voice <name> | speed <n> | status',
    })
    await load($)
    startWorker($)

    return started
  })

  // Speak the model's text as it streams, a sentence at a time. Code blocks,
  // tables, tool calls and tool output never reach the speech: only `text`
  // chunks of the main loop do, and the segmenter drops fences and tables.
  on('turn.step', async function* ($, e, next) {
    if (e.agentId !== undefined) return yield* next(e)
    await load($)
    if (enabled) startWorker($)

    const segmenter = new Segmenter()
    const blocks = new Set<number>()
    const stream = next(e)

    for await (const chunk of stream) {
      if (chunk.kind === 'text') {
        // A new text block starts a new paragraph.
        if (!blocks.has(chunk.index)) {
          speak($, segmenter.flush())
          blocks.add(chunk.index)
        }
        speak($, segmenter.feed(chunk.text))
      }
      yield chunk
    }
    speak($, segmenter.flush())

    return await stream.result
  })

  // A new reply starts a new memory for `/speak replay`.
  on('turn.start', async ($, e, next) => {
    if (e.agentId === undefined) lastReply = []

    return next(e)
  })

  // Talking over a new prompt is never wanted: cut it off when one is sent.
  on('prompt.submit', async ($, e, next) => {
    if (enabled) void stop($)

    return next(e)
  }).catch(($, e, next) => next(e))

  // An interrupted turn falls silent too.
  on('turn.complete', async ($, e, next) => {
    if (enabled && e.reason === 'aborted') void stop($)

    return next(e)
  })

  on('command.run', { command: 'speak' }, async ($, e) => {
    await load($)
    const [action = 'status', arg] = e.args.trim().split(/\s+/)

    switch (action) {
      case 'on':
      case 'off': {
        enabled = action === 'on'
        await $.store.set('enabled', enabled)
        if (enabled) startWorker($)
        else await stop($)

        return { text: `Speech ${enabled ? 'on' : 'off'}.` }
      }
      case 'stop':
        await stop($)

        return { text: 'Stopped.' }
      case 'replay': {
        if (lastReply.length === 0) return { text: 'Nothing to replay yet.' }
        startWorker($)
        await stop($)
        // The worker drops what is older than the stop, so wait out its millisecond.
        await new Promise(resolve => setTimeout(resolve, 25))
        for (const sentence of lastReply) void say($, sentence)

        return { text: 'Replaying the last reply.' }
      }
      case 'voice': {
        if (!arg) {
          return { text: `Voice: ${voice}. Try af_heart, af_bella, bf_emma, am_michael, bm_george.` }
        }
        voice = arg
        await $.store.set('voice', voice)
        await writeConfig($)
        await say($, 'This is how I sound now.')

        return { text: `Voice set to ${voice}.` }
      }
      case 'speed': {
        const value = Number(arg)
        if (!(value >= 0.5 && value <= 2)) {
          return { text: `Speed: ${speed}. Give a number from 0.5 to 2.` }
        }
        speed = value
        await $.store.set('speed', speed)
        await writeConfig($)

        return { text: `Speed set to ${speed}.` }
      }
      default:
        return {
          text: `Speech is ${enabled ? 'on' : 'off'}. Voice ${voice}, speed ${speed}. Usage: /speak on|off|stop|replay|voice <name>|speed <n>`,
        }
    }
  })
}
