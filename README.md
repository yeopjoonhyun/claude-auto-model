# claude-auto-model

프롬프트를 보고 Sonnet 5.5와 Opus 5.5 중 맞는 모델로 자동 전환하는 Claude Code 모드.
어려운 작업(설계, 디버그, 보안, 성능 등)은 Opus, 쉬운 작업(오타, 이름 변경,
설명, 요약 등)은 Sonnet을 씁니다. 판단은 키워드와 길이로 하므로 토큰이 들지 않습니다.

## 설치 (macOS / Linux)

```bash
curl -fsSL https://raw.githubusercontent.com/yeopjoonhyun/claude-auto-model/main/install.sh | bash
```

`python3`가 필요합니다.

## 설치 (Windows)

PowerShell에서:

```powershell
irm https://raw.githubusercontent.com/yeopjoonhyun/claude-auto-model/main/install.ps1 | iex
```

Windows PowerShell 5.1과 PowerShell 7 모두 됩니다. 기존 `settings.json`은
`settings.json.bak`으로 남깁니다.

## 설치하면

`~/.claude/mods/auto-model`(Windows는 `%USERPROFILE%\.claude\mods\auto-model`)에
`mod/` 폴더의 파일을 내려받고 `~/.claude/settings.json`의
`env.CLAUDE_CODE_PLUGIN_DIRS`에 등록합니다. 새 세션부터 적용됩니다.
`AUTO_MODEL_REF` 환경 변수로 다른 브랜치나 태그에서 설치할 수 있습니다.

## 명령

- `/auto-model status`: 현재 상태와 선택된 모델 보기
- `/auto-model off`: 끄기
- `/auto-model on`: 켜기

## 주의

모델을 바꾸면 프롬프트 캐시가 새로 만들어져 첫 응답이 비쌀 수 있습니다.
키워드는 `mod/hooks/register.ts`의 `HARD`, `EASY` 목록에서 고칠 수 있습니다.
