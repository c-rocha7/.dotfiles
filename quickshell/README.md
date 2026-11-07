# Quickshell

Barra superior em formato de **ilha dinâmica** (estilo iPhone), feita em QML com o
[Quickshell](https://quickshell.org). Substitui o Waybar.

## Instalação

```bash
sudo pacman -S quickshell
ln -s ~/.dotfiles/quickshell ~/.config/quickshell
```

Rodar: `qs` (lê `~/.config/quickshell/shell.qml`). Ao salvar um arquivo, o Quickshell recarrega sozinho.
Logs: `qs log $(ls -t /run/user/$UID/quickshell/by-id/*/log.qslog | head -1)`.

## O que a ilha mostra (por prioridade)

| Tela | Quando | Conteúdo |
|---|---|---|
| wallpaper | SUPER+W ou botão na ilha aberta | grade de miniaturas para trocar o wallpaper |
| record | SUPER+R / SUPER+SHIFT+R | escolher o áudio antes de gravar a tela |
| keys | SUPER+/ | guia de atalhos (lido do hyprland.lua) |
| power | botão de power ou SUPER+X | menu de energia: Bloquear, Suspender, Sair, Reiniciar, Desligar |
| launcher | SUPER+Space / SUPER+V / SUPER+Tab | busca de apps, emojis, calculadora, comandos, histórico do clipboard e troca de janelas |
| connections | clique no bloco de Wi-Fi ou Bluetooth | painel de conexões: redes Wi-Fi e aparelhos Bluetooth |
| center | clique no sino | painel de notificações (fecha clicando fora ou com Esc) |
| hover | mouse em cima da ilha | workspaces, mídia, bateria, perfil de energia, bluetooth, bandeja, volume, sino, power, hora e calendário |
| volume / brightness | volume/mudo ou brilho mudou (2s) | barra de nível |
| notification | chegou notificação (5s; não aparece no "não perturbe") | ícone, título e texto (clique abre o app, direito dispensa) |
| toast | microfone mutado/ligado ou Caps Lock (1,5s) | ícone + texto |
| media | algo tocando | capa, título — artista, anterior/play/próximo |
| compact | resto do tempo | workspace atual · hora (+ gravando: ponto vermelho e tempo; Caps Lock ligado, bateria em vermelho abaixo de 20%) |

## Estrutura

| Arquivo | O que faz |
|---|---|
| `shell.qml` | Ponto de entrada: cria uma barra por monitor |
| `Theme.qml` | Cores (Catppuccin Mocha), fonte, medidas e tempos de animação |
| `Launcher.qml` | Estado do launcher, histórico do clipboard (clipvault) e comandos `qs ipc call launcher ...` |
| `PowerMenu.qml` | Ações de energia (usadas pelo menu e pelo launcher) e `qs ipc call power toggle` |
| `Cheatsheet.qml` | Guia de atalhos: lê `hyprctl binds -j` e agrupa pela descrição |
| `Lock.qml` | Tela de bloqueio: estado (sobrevive a recarregamentos), senha via PAM (`/etc/pam.d/hyprlock`) e `qs ipc call lock lock` |
| `Wallpaper.qml` | Troca de wallpaper: lista, miniaturas, `waypaper --wallpaper` e `qs ipc call wallpaper toggle|random` |
| `Recorder.qml` | Gravação de tela: seletor de áudio, estado e `qs ipc call recording ...` (usa `hypr/scripts/record.sh`) |
| `Keyboard.qml` | Estado do Caps Lock, lido da luz do teclado (`/sys/class/leds/*::capslock`) |
| `QuickSettings.qml` | Estado do painel de conexões (aba Wi-Fi/Bluetooth) e comandos `qs ipc call network ...` |
| `Battery.qml` | Bateria (UPower) e notificação de bateria fraca em 15% e 5% |
| `Updates.qml` | Atualizações pendentes (sistema, AUR, Flatpak) a cada hora; `qs ipc call updates refresh\|run` |
| `GameMode.qml` | Jogos: perfil Desempenho enquanto o GameMode está ativo, aviso e ícone na ilha (`qs ipc call gamemode started\|stopped`, chamado por `gamemode/hook.sh`) |
| `Brightness.qml` | Brilho da tela na escala do `hypr/scripts/brightness.sh` (0% = mínimo útil da tela), avisado via `qs ipc call brightness changed` |
| `NotificationService.qml` | Servidor de notificações (substitui o swaync): histórico, "não perturbe", ícones e comandos `qs ipc` |
| `lock/LockScreen.qml`, `lock/LockSurface.qml` | Bloqueio seguro do Wayland (ext-session-lock) e o visual da tela de bloqueio |
| `bar/Bar.qml` | Janela transparente que segura a ilha (só a ilha recebe cliques) |
| `bar/Island.qml` | A ilha: escolhe a tela atual e anima o tamanho |
| `bar/IslandView.qml` | Base de cada tela (centraliza e faz o fade) |
| `bar/CompactView.qml` | Tela fechada |
| `bar/MediaRow.qml` | Linha de mídia (usada na tela de mídia e no hover) |
| `bar/LevelView.qml`, `bar/VolumeView.qml`, `bar/BrightnessView.qml` | Aviso com barra de nível (volume e brilho) |
| `bar/BatteryPill.qml`, `bar/PowerProfilePill.qml`, `bar/BluetoothPill.qml` | Bateria, perfil de energia (clique alterna) e bluetooth (clique abre o painel, direito abre o blueman) |
| `bar/NotificationView.qml` | Aviso de notificação |
| `bar/NotificationCenter.qml`, `bar/NotificationCard.qml` | Painel de notificações e cada cartão |
| `bar/NotifIcon.qml` | Ícone da notificação (sino quando o app não manda ícone) |
| `bar/ThemedText.qml` | Texto padrão sem posicionamento automático |
| `bar/ClipImage.qml` | Prévia de imagem do histórico do clipboard (extrai para o cache) |
| `data/emojis.json` | Lista de emojis com nomes em português (Unicode + CLDR) |
| `bar/LauncherView.qml`, `bar/LauncherItem.qml` | Launcher (busca, resultados e teclas) e cada linha |
| `bar/ConnectionsView.qml`, `bar/WifiPanel.qml`, `bar/BluetoothPanel.qml` | Painel de conexões e suas abas |
| `bar/CheatsheetView.qml` | Guia de atalhos em 3 colunas |
| `bar/WallpaperView.qml`, `bar/WallpaperButton.qml` | Painel de wallpapers e o botão da ilha aberta |
| `scripts/wallpaper-thumbs.sh` | Gera as miniaturas (vipsthumbnail) e lista os wallpapers |
| `bar/RecordPickerView.qml`, `bar/RecordPill.qml` | Seletor de áudio da gravação e indicador "gravando" (com botão Parar na ilha aberta) |
| `bar/ToastView.qml` | Aviso curto (microfone, Caps Lock) |
| `bar/PowerView.qml` | Menu de energia (Sair/Reiniciar/Desligar pedem confirmação) |
| `bar/WifiPill.qml` | Bloco de Wi-Fi (sinal + rede); clique abre o painel |
| `bar/Toggle.qml`, `bar/SmallButton.qml` | Interruptor e botão pequeno |
| `bar/HoverView.qml` | Tela aberta com tudo |
| `bar/Calendar.qml` | Calendário do mês |
| `bar/Pill.qml`, `bar/BarText.qml` | Bloco arredondado e texto padrão |
| `bar/Workspaces.qml`, `Tray.qml`, `Volume.qml`, `Notifications.qml`, `PowerButton.qml` | Controles mostrados no hover |

Arquivos de `bar/` são importados com `import qs.bar`; os da raiz (`Theme`, `NotificationService`, `Launcher`, `PowerMenu`, `QuickSettings`, `Keyboard`, `Cheatsheet`, `Recorder`, `Lock`, `Wallpaper`, `Battery`, `Brightness`, `GameMode`, `Updates`) com `import qs`.

## Launcher

Sai da ilha. `SUPER+Space` abre nos apps; `SUPER+V` no histórico do clipboard (imagens com prévia);
`SUPER+Tab` na lista de janelas (a anterior vem primeiro, Enter vai até ela).
Se o `qs` não estiver rodando, os atalhos abrem o rofi no lugar.

| Digite | Faz |
|---|---|
| texto | busca apps (nome, descrição, palavras-chave), ações dos apps e Bloquear/Suspender/Sair/Reiniciar/Desligar |
| `=2+2*3` | calculadora (aceita `,` e `^`); Enter copia o resultado |
| `>comando` | roda o comando; Shift+Enter roda dentro do terminal |
| `:nome` | emojis (português ou inglês, ex.: `:coração`, `:fire`); Enter copia |

Teclas: ↑/↓ ou Tab escolhem, Enter executa, Esc (ou clicar fora) fecha. No clipboard, Delete apaga o item.

```bash
qs ipc call launcher toggle      # abre/fecha nos apps
qs ipc call launcher clipboard   # abre no histórico do clipboard
qs ipc call launcher windows     # abre na lista de janelas
qs ipc call launcher search ':'  # abre com um texto já digitado
```

## Wallpaper

`SUPER+W` (ou o botão na ilha aberta) mostra as imagens de `~/Imagens/Wallpapers`.
Clique ou Enter aplica (o painel continua aberto), R = aleatório, setas escolhem, Esc fecha.
Aplica com `waypaper --wallpaper` (transição do waypaper e escolha salva para o próximo login).
Miniaturas em `~/.cache/quickshell/.../wallpapers` (refeitas só se a imagem mudar).

## Tela de bloqueio

Bloqueia com `SUPER+X` → Bloquear, `loginctl lock-session`, ao suspender e após 15 min parado
(hypridle). Wallpaper atual desfocado, hora, data, foto (`~/Imagens/Icons/dog-sword.jpg`) e senha.

Proteções: o bloqueio é o protocolo seguro do Wayland; o Hyprland tem
`misc.allow_session_lock_restore = true` (outro programa pode assumir se o Quickshell cair);
o hypridle usa o hyprlock se o `qs` não responder; não existe comando que desbloqueie sem senha.

**Se travar** (tela vermelha ou sem campo de senha): `Ctrl+Alt+F3`, entre no terminal e rode
`hyprctl --instance 0 dispatch 'hl.dsp.exec_cmd("hyprlock")'`; volte com `Ctrl+Alt+F2` e
desbloqueie no hyprlock.

## Capturas e gravação de tela

Scripts em `hypr/scripts/` (chamados pelos atalhos do `hyprland.lua`):

- `screenshot.sh region|window|output` — `Print` (região), `SUPER+Print` (janela),
  `SUPER+SHIFT+Print` (tela inteira), `SHIFT+Print` (região e já abre o satty). Salva em `~/Imagens/Prints`, copia, e a notificação
  mostra a miniatura: **clique para editar no satty** (Enter salva e copia).
- `record.sh` — `SUPER+R` (região) e `SUPER+SHIFT+R` (tela inteira) abrem o seletor de áudio
  (Sem áudio / Som do PC / PC + microfone; lembra a última escolha). O mesmo atalho para.
  Gravando, a ilha mostra o tempo; na ilha aberta há o botão Parar. Vídeos em `~/Vídeos/Gravações`.
  Usa o `gpu-screen-recorder` (codifica na GPU AMD).

## Guia de atalhos

`SUPER+/` mostra os atalhos do Hyprland agrupados por categoria. Ele lê os atalhos que têm
descrição no `hyprland.lua`, no formato `"Categoria · O que faz"`:

```lua
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal), { description = "Apps · Terminal" })
```

Atalho sem `description` não aparece no guia.

## Menu de energia

`SUPER+X` ou o botão de power da ilha. Teclas: B bloquear, S suspender, E sair, R reiniciar,
D desligar (ou ←/→ e Enter). Sair, Reiniciar e Desligar pedem confirmação (segundo clique/Enter).
Se o `qs` não estiver rodando, o `SUPER+X` abre o wlogout no lugar.

## Conexões (Wi-Fi e Bluetooth)

Abre pelos blocos de Wi-Fi/Bluetooth da ilha aberta. Fecha clicando fora ou com Esc.

- **Wi-Fi:** liga/desliga, lista redes (conectada, salvas, depois pelo sinal), conecta
  (pede a senha se for nova), desconecta e esquece. VPN e redes corporativas: "Mais opções".
- **Bluetooth:** liga/desliga, procura aparelhos enquanto a aba está aberta, pareia,
  conecta/desconecta e esquece.
- O `nm-applet` e o `blueman-applet` continuam rodando com o ícone escondido: eles mostram
  as janelas de senha especial e de PIN de pareamento.

```bash
qs ipc call network toggle | wifi | bluetooth
```

## Notificações

O Quickshell é o daemon de notificações (não usa mais o swaync). Comandos para atalhos:

```bash
qs ipc call notifications toggle      # abre/fecha o painel
qs ipc call notifications toggleDnd   # liga/desliga o "não perturbe"
qs ipc call notifications clear       # apaga todas
```

O histórico fica na memória: some ao reiniciar o `qs` ou sair da sessão.

## Dependências

`quickshell`, `clipvault` + `wl-clipboard`, `hyprshot` + `satty`, `waypaper` + `awww` + `libvips` (vipsthumbnail), `gpu-screen-recorder` + `slurp`, `brightnessctl`, `power-profiles-daemon`, `bluez` + `blueman`, `upower`, `libnotify` (notify-send).

## Observações

- O `shell.qml` começa com `//@ pragma UseQApplication`: sem isso os menus da bandeja
  (Wi-Fi, Spotify, Vesktop...) não abrem (o erro só aparece no log).

- Em singletons (`Theme.qml`, `NotificationService.qml`, `Launcher.qml`, `PowerMenu.qml`, `QuickSettings.qml`, `Keyboard.qml`, `Cheatsheet.qml`, `Recorder.qml`, `Lock.qml`, `Wallpaper.qml`, `Battery.qml`, `Brightness.qml`, `GameMode.qml`, `Updates.qml`), o `pragma Singleton` tem que ser
  a **primeira linha** do arquivo, senão o Quickshell não o reconhece (e não mostra erro).

- A janela da ilha tem 1140x700 (o maior painel é o guia de atalhos); só a ilha recebe cliques.

- O Hyprland 0.55+ usa configuração em Lua, então os comandos enviados a ele usam
  a sintaxe Lua, por exemplo: `Hyprland.dispatch('hl.dsp.focus({ workspace = 2 })')`.

## Layout "moldura" (padrão; `Theme.layout`)

Inspirado no Noctalia: barra no topo + borda em volta da tela com os cantos de dentro arredondados
(concêntricos com as janelas do Hyprland: `frameRadius` 14 = `rounding` 12 + `gaps_out` 2). Painéis
**brotam da moldura** (mesma cor e contorno, com "orelhas" côncavas onde encontram a borda).

| Arquivo | O que é |
|---|---|
| `frame/Frame.qml` | Por monitor: 4 `Exclusion` (reservam espaço nas bordas) + `FrameWindow` |
| `frame/FrameWindow.qml` | A moldura: barra (workspaces · data/hora · status), painéis, avisos, clique fora/Esc fecha |
| `frame/FrameShape.qml` | Desenho da moldura (furo arredondado + contorno `frameOutline`) |
| `frame/FramePanel.qml` | Painel que cresce a partir da borda; tamanho vem do conteúdo (`body`) |
| `frame/PanelShape.qml` | Fundo do painel com orelhas: `top`, `topRight`, `right` |
| `frame/AudioView.qml`, `VolumeSlider.qml`, `AudioDevice.qml` + `Audio.qml` | Painel de áudio (pavucontrol): saída/entrada (volume, mudo, dispositivo padrão) e volume por app; "Avançado" abre o pavucontrol. Clique no volume da barra ou `qs ipc call audio toggle`. O PwObjectTracker precisa acompanhar os **candidatos** (pela estrutura: isStream/isSink) antes de filtrar pela classe: sem acompanhar, o nó não carrega `media.class` (`ready=false`) |

Onde fica cada coisa: topo (launcher, gravação, wallpapers, atalhos, energia, calendário + mídia ao clicar
na hora); canto direito (notificações, Wi-Fi/Bluetooth, áudio, notificação nova); borda direita (volume, brilho,
microfone, Caps Lock, GameMode). As telas são as mesmas de `bar/` (reaproveitadas). `Theme.layout: "ilha"`
volta para a ilha dinâmica.

### Painéis e extras da moldura

| Arquivo | O que é |
|---|---|
| `ControlCenter.qml` + `frame/ControlCenterView.qml`, `CcTile.qml`, `BrightnessSlider.qml`, `BatteryView.qml` | Central de controle (⚙ na barra; ícones de Wi-Fi/BT/volume/bateria abrem a página deles): botões Wi-Fi, Bluetooth, Não perturbe, Luz noturna, Microfone, Energia; volume e brilho; bateria; mídia. Subpáginas Wi-Fi, Bluetooth, Áudio, Bateria (consumo, saúde, perfis). `qs ipc call control toggle` / `mostrar wifi` |
| `NightLight.qml` | Luz noturna (hyprsunset): o estado fica aqui (o hyprsunset informa a última temperatura mesmo depois de `identity`) |
| `frame/StatusCluster.qml` | Botão da central na barra: só os ícones de Wi-Fi, Bluetooth e volume (clique abre a central; rolagem = volume; meio = mudo) |
| `CalendarPanel.qml` | Painel do calendário (duas colunas: calendário · clima + mídia); `qs ipc call calendar toggle` |
| `Overview.qml` + `frame/OverviewWindow.qml` | Visão geral das workspaces (`SUPER+Tab`, 3 dedos para cima): cards com wallpaper e miniaturas ao vivo (`ScreencopyView` da janela do Hyprland). Clique vai à janela/workspace, arrastar move a janela, clique do meio fecha, 1-5/Esc. As capturas só ligam com tamanho válido (tamanho negativo faz o Hyprland recusar). `qs ipc call overview toggle` |
| `Focus.qml` | Modo foco: Não perturbe (volta ao estado anterior), arquivo `$XDG_RUNTIME_DIR/modo-foco` para a minitela, Vesktop/Ferdium para `special:foco` (voltam para a 5). `qs ipc call foco toggle` |
| `bar/LauncherView.qml` (`@`) | Projetos: pastas de `~/Projetos` (+ repositórios git um nível abaixo) e `~/.dotfiles`; Enter VS Code, Shift+Enter terminal na pasta |
| `Health.qml` + `frame/HealthView.qml` + `scripts/saude.sh` | Central → Sistema: falhas de serviços, disco, memória, temperaturas, snapshots, atualizações, travamentos desde o boot (roda só com a central aberta) |
| `GitHub.qml` + `frame/GitHubView.qml` + `scripts/github.sh` | Central → GitHub: revisões pedidas, suas PRs, notificações (gh logado; a cada 5 min); ícone na barra com o total pendente |
| `Agenda.qml` + `frame/AgendaCard.qml` + `scripts/agenda.py` | Agenda (link iCal em `~/.config/agenda/ical-url`): próximos eventos no calendário, pontinho nos dias; salva `$XDG_RUNTIME_DIR/agenda.json` para a minitela |
| `lock/LockSurface.qml`, `lock/LockPreview.qml` | Tela de bloqueio no estilo da moldura; `qs ipc call lock previa` mostra sem bloquear (Esc fecha) |
| `frame/MediaCard.qml` | Mídia no calendário: capa, progresso arrastável, anterior/tocar/próximo, ⇄ troca de player (a posição do MPRIS é pedida a cada 1 s) |
| `frame/VerticalLevel.qml` | Aviso vertical de volume/brilho na borda direita |
| `frame/FrameWorkspaces.qml` | Workspaces com os ícones dos apps (até 3) |
| `Weather.qml` + `frame/WeatherCard.qml` | Clima: cidade pelo IP (ipwho.is; reserva ipapi.co), previsão Open-Meteo a cada 30 min; salva em `$XDG_RUNTIME_DIR/clima-*.json` (só substitui com resposta boa) — a minitela lê de lá |
| `bar/NotificationCenter.qml` | Agrupada por app (2 últimas; "+N" expande; × limpa o grupo); botões de ação já vinham do cartão |
| `bar/LauncherView.qml` | `/nome` busca arquivos (plocate; casa primeiro; pastas ocultas fora, menos `.dotfiles`/`.config`); Enter abre, Shift+Enter abre a pasta |

Transparência: moldura + fundos dos painéis numa camada só (`background` no FrameWindow, `Theme.frameOpacity`)
para não haver costura escura onde o painel encosta; desfoque pela `layer_rule` "moldura" no `hyprland.lua`.
