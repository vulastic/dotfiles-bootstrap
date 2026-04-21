# Dotfiles Bootstrap

Windows PowerShell과 Linux 계열 환경(Ubuntu, Termux)에서 동일한 작업 흐름을 재현하기 위한 크로스플랫폼 쉘 부트스트랩 프로젝트다.

## 목표

다음 환경에서 최대한 비슷한 사용 경험을 제공한다.

* Windows PowerShell
* Ubuntu
* Termux

공통 사용자 경험 기준:

* `tmux` 기반 터미널 워크스페이스
* `LazyVim` 기반 편집 환경
* `git`, `fzf`, `ghq`, 디렉터리 점프 도구 사용
* Tokyo Night 계열 시각 언어
* Sarasa Mono K, Iosevka Nerd Font 폰트 조합

## 플랫폼별 구성

### Windows

* PowerShell
* Starship
* Terminal-Icons
* zoxide

### Linux / Ubuntu / Termux

* fish
* starship
* zoxide
* `eza`로 `ls` 대체

## 공통 도구

* `tmux`
* `neovim` + `LazyVim`
* `git`
* `fzf`
* `ghq`
* `bat`
* `ripgrep`
* `fd`

## 적용 내용

* Starship 기반 크로스플랫폼 프롬프트 설정 (Tokyo Night 테마)
* IosevkaTerm Nerd (우선) 및 Sarasa Monk K 폰트 구성
* tmux 상단 상태바 테마
* LazyVim용 Tokyo Night 색상 설정
* 공통 alias 레이어 (`ls`, `ll`, `la`, `vim`, `cat`, `grep`, `find`)

## 참고 사항

* 폰트는 플랫폼별 패키지 가용성 차이로 인해 일부 환경에서는 수동 지정이 필요하다.
* Ubuntu의 `eza`는 외부 저장소를 추가해서 설치한다.
* 기존 사용자 설정 파일이 있으면 `.bak` 백업을 남긴다.
