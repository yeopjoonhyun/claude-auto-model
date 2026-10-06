#!/usr/bin/env bash
# auto-model 모드 설치 (macOS / Linux)
# 1) ~/.claude/mods/auto-model 에 모드 파일 3개를 쓰고
# 2) ~/.claude/settings.json 의 env.CLAUDE_CODE_PLUGIN_DIRS 에 그 폴더를 등록한다.
set -euo pipefail

DIR="$HOME/.claude/mods/auto-model"
SETTINGS="$HOME/.claude/settings.json"

mkdir -p "$DIR/.claude-plugin" "$DIR/hooks"

cat > "$DIR/.claude-plugin/plugin.json" <<'PLUGIN_EOF'
{ "name": "auto-model", "version": "0.1.0", "description": "Picks Sonnet 5.5 or Opus 5.5 per prompt: Opus for hard work, Sonnet for easy work" }
PLUGIN_EOF

cat > "$DIR/hooks/hooks.json" <<'HOOKS_EOF'
{ "modules": ["./register.ts"] }
HOOKS_EOF

cat > "$DIR/hooks/register.ts" <<'REGISTER_EOF'
import type { Register } from 'claude-code'

const OPUS = 'claude-opus-5-5'
const SONNET = 'claude-sonnet-5-5'

// Words that suggest hard work: design, deep debugging, big changes.
const HARD = [
  '설계', '아키텍처', '구조', '리팩터', '리팩토링', '보안', '성능',
  '원인', '왜 안', '왜안', '안 돼', '안돼', '버그', '디버그', '전체', '복잡', '최적화', '알고리즘',
  'architecture', 'refactor', 'redesign', 'security', 'performance',
  'root cause', 'debug', 'race condition', 'optimize', 'algorithm', 'design',
]

// Words that suggest easy work: small edits, questions, explanations.
const EASY = [
  '오타', '이름 바꿔', '이름바꿔', '주석', '설명해', '뭐야', '무슨 뜻', '간단', '한 줄', '포맷', '정렬',
  '번역', '요약', '색', '문구', '텍스트', 'readme',
  'typo', 'rename', 'comment', 'explain', 'what is', 'simple', 'one line', 'format', 'translate', 'summarize',
]

const count = (text: string, words: string[]) => words.filter(w => text.includes(w)).length

// 'opus', 'sonnet', or undefined (not clear: keep whatever was chosen last).
function pick(prompt: string): 'opus' | 'sonnet' | undefined {
  const text = prompt.toLowerCase()
  const hard = count(text, HARD) + (text.length > 600 ? 1 : 0)
  const easy = count(text, EASY)

  if (hard >= 1 && hard >= easy) return 'opus'
  if (easy >= 1 && hard === 0 && text.length < 300) return 'sonnet'
  return undefined
}

let isEnabled = true
let chosen: string | undefined
let announced: string | undefined

export const register: Register = (on) => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'auto-model',
      description: 'Auto model switching: /auto-model on | off | status',
    })
    return next(e)
  })

  on('command.run', { command: 'auto-model' }, async (_$, e) => {
    const arg = e.args.trim()
    if (arg === 'on') isEnabled = true
    if (arg === 'off') {
      isEnabled = false
      chosen = undefined
    }
    const model = chosen === OPUS ? 'Opus 5.5' : chosen === SONNET ? 'Sonnet 5.5' : '세션 기본 모델 유지'
    return { text: `자동 모델 전환: ${isEnabled ? '켜짐' : '꺼짐'} | 현재 선택: ${model}` }
  })

  // Decide once per prompt, from the person's own text only.
  on('prompt.submit', async ($, e, next) => {
    if (isEnabled && e.origin.kind === 'composer') {
      const level = pick(e.text)
      if (level !== undefined) {
        const model = level === 'opus' ? OPUS : SONNET
        if (model !== announced) {
          announced = model
          $.ui.toast(level === 'opus' ? '자동 모델: Opus 5.5 (어려운 작업)' : '자동 모델: Sonnet 5.5 (쉬운 작업)')
        }
        chosen = model
      }
    }
    return next(e)
  })

  // Apply the choice to each request the main conversation makes.
  on('turn.step', async function* ($, e, next) {
    if (isEnabled && chosen !== undefined && e.agentId === undefined && e.model !== chosen) {
      return yield* next({ ...e, model: chosen })
    }
    return yield* next(e)
  })
}
REGISTER_EOF

python3 - "$SETTINGS" "$DIR" <<'PY_EOF'
import json, os, sys

path, mod = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)

env = data.setdefault("env", {})
current = [p for p in env.get("CLAUDE_CODE_PLUGIN_DIRS", "").split(os.pathsep) if p]
if mod not in current:
    current.append(mod)
env["CLAUDE_CODE_PLUGIN_DIRS"] = os.pathsep.join(current)

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY_EOF

echo "설치 완료: $DIR"
echo "새 Claude Code 세션부터 자동 모델 전환이 켜집니다. 끄려면 /auto-model off"
