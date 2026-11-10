// Turns streamed markdown into sentences worth reading aloud.
//
// Fed the text of a reply piece by piece, it hands back sentences as soon as
// they are complete. Fenced code blocks and tables are skipped, markdown
// syntax is stripped, and things that sound bad read out (paths, hashes, URLs,
// long inline code) are shortened or dropped.

const FENCE = /^\s*(```|~~~)/
const FENCE_START = /^\s*[`~]{0,3}$/
const ABBREVIATIONS = new Set(['e.g', 'i.e', 'vs', 'etc', 'dr', 'mr', 'mrs', 'ms', 'approx', 'no', 'fig'])
// Sentences shorter than this wait for the next one, so speech is not choppy.
const MIN_CHUNK = 28
// Sentences longer than this are split at a comma, so synthesis stays quick.
const MAX_CHUNK = 320

export class Segmenter {
  private buf = ''
  private inFence = false
  private carry = ''

  feed(text: string): string[] {
    this.buf += text

    return this.drain(false)
  }

  flush(): string[] {
    const out = this.drain(true)
    if (this.carry) out.push(this.carry)
    this.carry = ''
    this.buf = ''
    this.inFence = false

    return out
  }

  private drain(isFinal: boolean): string[] {
    const out: string[] = []

    for (;;) {
      const newline = this.buf.indexOf('\n')
      if (newline >= 0) {
        const line = this.buf.slice(0, newline)
        this.buf = this.buf.slice(newline + 1)
        this.line(line, out)
        continue
      }
      if (this.inFence) break
      if (isFinal) {
        if (this.buf) this.line(this.buf, out)
        this.buf = ''
        break
      }
      // A partial line that may still turn into a fence opener has to wait.
      if (FENCE_START.test(this.buf) || FENCE.test(this.buf)) break

      const cut = sentenceEnd(this.buf)
      if (cut > 0) {
        this.speech(this.buf.slice(0, cut), out)
        this.buf = this.buf.slice(cut)
      }
      break
    }

    return out
  }

  private line(line: string, out: string[]) {
    if (FENCE.test(line)) {
      this.inFence = !this.inFence
      this.release(out)

      return
    }
    if (this.inFence) return

    this.speech(line, out)
    // The end of a line (a list item, a heading, a paragraph) is a pause.
    this.release(out)
  }

  private speech(text: string, out: string[]) {
    const cleaned = clean(text)
    if (!cleaned) return
    this.carry = this.carry ? `${this.carry} ${cleaned}` : cleaned

    // Everything held is whole sentences. Hand them back one chunk each, but
    // keep a short last one, which may still grow into a longer chunk.
    const chunks = pack(this.carry)
    const last = chunks[chunks.length - 1] ?? ''
    if (last.length < MIN_CHUNK) {
      out.push(...chunks.slice(0, -1))
      this.carry = last
    } else {
      out.push(...chunks)
      this.carry = ''
    }
  }

  private release(out: string[]) {
    if (this.carry) out.push(...pack(this.carry))
    this.carry = ''
  }
}

// Splits whole sentences into chunks: one sentence each, short ones merged
// into their neighbour, long ones cut at a comma.
function pack(text: string): string[] {
  const sentences: string[] = []
  let from = 0
  const end = /[.!?]+["')\]]*(?=\s|$)/g
  for (let m = end.exec(text); m; m = end.exec(text)) {
    const stop = m.index + m[0].length
    const word = /([\w.]+)$/.exec(text.slice(0, m.index))?.[1]?.toLowerCase() ?? ''
    if (m[0].startsWith('.') && (ABBREVIATIONS.has(word) || /^[a-z]$/.test(word))) continue
    if ((text.slice(from, stop).match(/`/g)?.length ?? 0) % 2 === 1) continue
    sentences.push(text.slice(from, stop).trim())
    from = stop
  }
  if (text.slice(from).trim()) sentences.push(text.slice(from).trim())

  const chunks: string[] = []
  let current = ''
  for (const sentence of sentences) {
    current = current ? `${current} ${sentence}` : sentence
    if (current.length >= MIN_CHUNK) {
      chunks.push(...split(current))
      current = ''
    }
  }
  if (current) chunks.push(...split(current))

  return chunks
}

// Index just past the last sentence end that is followed by whitespace, or -1.
function sentenceEnd(text: string): number {
  let last = -1
  const end = /[.!?]+["')\]]*\s/g
  for (let m = end.exec(text); m; m = end.exec(text)) {
    const before = text.slice(0, m.index)
    const word = /([\w.]+)$/.exec(before)?.[1]?.toLowerCase() ?? ''
    if (m[0].startsWith('.') && (ABBREVIATIONS.has(word) || /^[a-z]$/.test(word))) continue
    const upTo = text.slice(0, m.index + m[0].length)
    if ((upTo.match(/`/g)?.length ?? 0) % 2 === 1) continue
    last = m.index + m[0].length
  }

  return last
}

function split(sentence: string): string[] {
  if (sentence.length <= MAX_CHUNK) return [sentence]
  const out: string[] = []
  let rest = sentence

  while (rest.length > MAX_CHUNK) {
    const at = Math.max(rest.lastIndexOf(', ', MAX_CHUNK), rest.lastIndexOf('; ', MAX_CHUNK))
    const cut = at > 80 ? at + 1 : rest.lastIndexOf(' ', MAX_CHUNK)
    out.push(rest.slice(0, cut > 0 ? cut : MAX_CHUNK).trim())
    rest = rest.slice(cut > 0 ? cut : MAX_CHUNK).trim()
  }
  if (rest) out.push(rest)

  return out
}

export function clean(raw: string): string {
  let t = raw
  if (/^\s*\|/.test(t)) return '' // table row
  if (/^\s*([-*_])(\s*\1){2,}\s*$/.test(t)) return '' // horizontal rule

  t = t
    .replace(/^\s{0,3}#{1,6}\s+/, '')
    .replace(/^\s*>\s?/, '')
    .replace(/^\s*(?:[-*+]|\d+[.)])\s+(?:\[[ xX]\]\s+)?/, '')
    .replace(/!\[[^\]]*\]\([^)]*\)/g, '')
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
    .replace(/<\/?[a-zA-Z][^>]*>/g, '')
    .replace(/https?:\/\/\S+/g, 'a link')
    .replace(/`([^`]+)`/g, (_, code: string) =>
      code.length <= 24 && !/[/\\{}()=<>;|&$]/.test(code) ? code.replace(/[_-]/g, ' ') : '',
    )
    .replace(/`+/g, '')
    .replace(/(\*\*|__)(.+?)\1/g, '$2')
    .replace(/\*(\S[^*]*?)\*/g, '$1')
    .replace(/~~(.+?)~~/g, '$1')
    // Paths read as their last segment; commit hashes are dropped.
    .replace(/(?:~|\.{1,2})?\/?(?:[\w.@+-]+\/){2,}([\w.@+-]+)/g, '$1')
    .replace(/\b(?=[0-9a-f]*\d)(?=[0-9a-f]*[a-f])[0-9a-f]{7,40}\b/gi, '')
    .replace(/\be\.g\./gi, 'for example')
    .replace(/\bi\.e\./gi, 'that is')
    .replace(/\bvs\.?(?=\s)/gi, 'versus')
    .replace(/\betc\./gi, 'et cetera.')
    .replace(/\s*(?:->|=>|→)\s*/g, ' to ')
    .replace(/\s*&\s*/g, ' and ')
    .replace(/\p{Extended_Pictographic}/gu, '')
    .replace(/\s+/g, ' ')
    .replace(/\s+([.,!?;:])/g, '$1')
    .trim()

  return /[A-Za-z]/.test(t) ? t : ''
}
