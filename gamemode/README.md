# Jogos (GameMode + MangoHud + Gamescope)

Links: `~/.config/gamemode.ini` → `gamemode/gamemode.ini` e `~/.config/MangoHud` → `MangoHud/`.

Pacotes: `steam gamemode lib32-gamemode mangohud lib32-mangohud gamescope` + `vulkan-radeon lib32-vulkan-radeon`.
O usuário precisa estar no grupo `gamemode` (`sudo usermod -aG gamemode $USER` e sair/entrar da sessão).

## Como funciona

- **GameMode**: prioridade de CPU/disco para o jogo e bloqueio da tela de descanso. Não mexe no
  governor (o `amd-pstate-epp` fica com o power-profiles-daemon): ao abrir um jogo, `hook.sh` avisa a
  ilha (`quickshell/GameMode.qml`), que liga o perfil **Desempenho** e volta ao anterior quando o jogo fecha.
- **MangoHud**: FPS, tempo de quadro, CPU/GPU (uso e temperatura), RAM/VRAM e bateria.
  `Shift direito+F12` liga/desliga, `Shift direito+F11` troca o canto, `Shift esquerdo+F1` limite de FPS.
- **Gamescope**: roda o jogo numa resolução menor e amplia com FSR (bom na Vega integrada).

## Steam e Proton

Comandos prontos das opções de inicialização e passo a passo do Proton-GE: [`docs/jogos-steam.md`](../docs/jogos-steam.md).

## Testar

```bash
gamemoded -s                 # ativo/inativo
gamemoderun sleep 10 &       # simula um jogo: a ilha mostra "GameMode ativo" e o perfil vai para Desempenho
mangohud vkcube              # testa o overlay
journalctl --user -u gamemoded -n 20
```
