#!/usr/bin/env bash
# auto-model 모드 설치 (macOS / Linux). Windows는 install.ps1 을 쓴다.
# 1) 이 저장소의 mod/ 파일 3개를 ~/.claude/mods/auto-model 에 내려받고
# 2) ~/.claude/settings.json 의 env.CLAUDE_CODE_PLUGIN_DIRS 에 그 폴더를 등록한다.
# AUTO_MODEL_REF 로 내려받을 브랜치나 태그를 고를 수 있다 (기본 main).
set -euo pipefail

DIR="$HOME/.claude/mods/auto-model"
SETTINGS="$HOME/.claude/settings.json"
BASE="https://raw.githubusercontent.com/yeopjoonhyun/claude-auto-model/${AUTO_MODEL_REF:-main}/mod"

mkdir -p "$DIR/.claude-plugin" "$DIR/hooks"

for f in .claude-plugin/plugin.json hooks/hooks.json hooks/register.ts; do
  curl -fsSL "$BASE/$f" -o "$DIR/$f"
done

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
