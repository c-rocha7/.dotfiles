#!/usr/bin/env bash
# GitHub para a barra/central (GitHub.qml): uma linha JSON com
#   notificações não lidas, suas PRs abertas e PRs esperando a sua revisão.
# Usa o login do gh (gh auth login); sem gh ou sem login, devolve {"ok": false, "erro": ...}.
set -u
falha() { jq -cn --arg e "$1" '{ok: false, erro: $e}'; exit 0; }
command -v gh >/dev/null || falha "gh não instalado (sudo pacman -S github-cli)"
gh auth status >/dev/null 2>&1 || falha "sem login (gh auth login)"

# Link da página (a API devolve o endereço da API)
html='def html: if . == null then null else sub("api.github.com/repos"; "github.com") | sub("/pulls/"; "/pull/") end;'
notif=$(gh api notifications --jq "$html"' [.[] | {titulo: .subject.title, repo: .repository.full_name, tipo: .subject.type,
    motivo: .reason, url: ((.subject.url | html) // ("https://github.com/" + .repository.full_name))}]' 2>/dev/null) || falha "erro ao buscar notificações"
minhas=$(gh search prs --author=@me --state=open --json title,url,repository,number,isDraft --limit 20 2>/dev/null || echo '[]')
revisar=$(gh search prs --review-requested=@me --state=open --json title,url,repository,number --limit 20 2>/dev/null || echo '[]')

jq -cn --argjson n "$notif" --argjson m "$minhas" --argjson r "$revisar" '{ok: true,
    notificacoes: $n,
    minhas: [$m[] | {titulo: .title, url: .url, repo: .repository.nameWithOwner, numero: .number, rascunho: .isDraft}],
    revisar: [$r[] | {titulo: .title, url: .url, repo: .repository.nameWithOwner, numero: .number}]}'
