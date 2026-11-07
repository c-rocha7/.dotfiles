# Contexto do notebook: Positivo Vision R15M (Arch Linux + Hyprland)

> Contexto para o Claude Code: o que foi feito na instalação e configuração, o estado atual e o que falta.
> Atualizado em 2026-11-05.

## 0. Como trabalhar com o usuário

- Responda em **português do Brasil**. O usuário prefere ir **passo a passo**, com os comandos prontos.
- **Peça confirmação** antes de: `sudo`, `pacman`/`yay` (instalar ou remover), `systemctl enable/disable`,
  `rm`, `git push`, mexer em `/etc`, `/boot` ou no bootloader.
- O Claude não consegue digitar a senha do `sudo`: passos com root viram **scripts** que o usuário roda
  (`sudo bash <script>`), com verificações, backup e instruções para desfazer. Guarde-os em
  `~/.dotfiles/install/` — o scratchpad fica em `/tmp` (tmpfs) e **some no reboot**.
- `pacman -Syu` (não `-Syyuu`); `yay -S` **sem `--noconfirm`**.
- **Tudo centralizado no `~/.dotfiles`**: só crie links onde o programa exige (`~/.config/<app>`);
  nada de links extras em `~` (ex.: o flake é usado direto em `~/.dotfiles/nix-dotfiles`).
- Dotfiles na branch **`notebook-r15m`** (a `main` é do desktop, 2 monitores). Ver seção 10.
- Nunca grave senhas, chaves ou tokens em arquivos versionados.

## 1. Hardware

- **Positivo Vision R15M** (SMBIOS `R732512BI-15`), tela 15,6" Full HD (`eDP-1`, 1920x1080@60).
- **Ryzen 7 5825U** (Zen 3), GPU integrada Radeon Vega (Mesa: `RENOIR`), driver de CPU `amd-pstate-epp`.
- **32 GB RAM**, NVMe 512 GB (`/dev/nvme0n1`), Wi-Fi 6 + Bluetooth Realtek RTL8852BE, teclado **ABNT2**.
- Hostname `vision-r15m`, usuário `7aauac` (wheel, video, audio, docker).
- Uso: desenvolvimento (web/desktop, Docker, runtimes via mise), edição de vídeo/foto, jogos.

## 2. BIOS (AMI Aptio V1.05.X)

UMA 4 GB, Network Stack off, SVM on, **FlexiCharger: carga para em 80%**, CSM off (UEFI), **Fast Boot on**,
**Secure Boot on** (chaves próprias do sbctl + Microsoft; `install/fase4-secure-boot.sh`). Entradas UEFI: `Limine` (`\EFI\limine\limine_x64.efi`) e
`UEFI OS` (`\EFI\BOOT\BOOTX64.EFI`, também o Limine). O firmware às vezes reordena o boot sozinho.

## 3. Disco (Btrfs) e snapshots

- GPT: `nvme0n1p1` 1 GiB FAT32 em `/boot` (ESP); `nvme0n1p2` Btrfs, UUID `61b69d0d-6939-4d01-9bfd-a87c1bf4d558`.
- Subvolumes: `@` (/), `@home`, `@log`, `@pkg` (cache do pacman), **`@nix`** (/nix), **`@docker`**
  (/var/lib/docker), **`@snapshots`** (/.snapshots). Opções `noatime,compress=zstd:3,ssd,discard=async,space_cache=v2`;
  fstab sem `subvolid=`. Sem swap em disco: só zram.
- **Snapper** (config `root`, só o `@`): snap-pac (antes/depois do pacman), timeline 5h/7d/2s/1m,
  10 do pacman, grupo wheel lê sem sudo. GUI: `btrfs-assistant`.
- **Snapper `home`** (`install/snapshots-home.sh`): `/home` de hora em hora (24h/7d/4s/3m), em `/home/.snapshots`.
  `~/.cache` e `~/.local/share/Steam` são subvolumes próprios (fora dos snapshots). **Não é backup** (mesmo SSD).
  Recuperar: copiar de `/home/.snapshots/<N>/snapshot/7aauac/...`.
- `/nix` e Docker ficam **fora** do `@` de propósito: restaurar o `/` não pode quebrar o Nix.
  O `nix-daemon.service/.socket` foi **copiado** para `/etc/systemd/system` (o link para dentro do /nix
  não existe no boot antes de montar o `@nix`).

## 4. Boot (Limine + snapshots)

- Kernel `linux-zen` + `amd-ucode` (microcódigo embutido no initramfs). Hooks do mkinitcpio:
  `base systemd plymouth autodetect microcode modconf kms keyboard sd-vconsole block filesystems sd-btrfs-overlayfs fsck`.
- **`limine-mkinitcpio-hook` + `limine-snapper-sync`** (Chaotic-AUR): config em `/etc/default/limine`;
  kernel/initramfs em `/boot/<machine-id>/linux-zen/`; `limine.conf` **gerado** (não editar à mão).
  - O kernel é gerenciado pelo **`limine-update`** — não use `mkinitcpio -P`.
  - Snapshots "pre" aparecem no menu (submenu **Snapshots**); iniciar por um deles usa overlay
    (só leitura) e mostra o aviso **"Restaurar agora"** (`limine-snapper-restore`).
  - Limite de 80% da ESP (1 GiB); sem `inotify-tools` o plugin do snapper faz a sincronização.
- **Secure Boot ativo** (`install/fase4-secure-boot.sh`): só o Limine é assinado (sbctl, chaves em `/var/lib/sbctl`,
  cópia em `/home/.sbctl-backup`); o hash do `limine.conf` vai gravado no Limine (`ENABLE_ENROLL_LIMINE_CONFIG=yes`)
  e o conf tem o hash do kernel/initramfs (`ENABLE_VERIFICATION=yes`). Kernel não é assinado. Editor do menu desligado.
  - Ganchos em `/etc/boot/hooks/`: `10-limine-reset-enroll` → `90-limine-enroll-config` (grava hash + assina) →
    `95-limine-fallback-assinado` (copia para `EFI/BOOT/BOOTX64.EFI`). Rodam a cada `limine-update` e snapshot.
  - **Nunca edite o `limine.conf` à mão**: o hash não bate e o boot trava ("CHECKSUM MISMATCH"). Recuperar:
    BIOS → Secure Boot off; ver o cabeçalho do script. Conferir: `sudo bash install/fase4-secure-boot.sh status`.
  - "EFI fallback" fora do menu (`FIND_BOOTLOADERS=no` + entrada removida).
- **Visual do menu** (`install/limine-tema.sh`): bloco marcado no topo do `limine.conf` (as ferramentas mantêm o
  cabeçalho): wallpaper = desenho do ly, Catppuccin, Terminus negrito 2x, timeout 3. Arquivos em `/boot/limine-tema/`
  com `#hash` no caminho (Secure Boot: sem hash é ignorado, hash errado trava). Mudou o desenho? Rode o
  `gen_ly_dur.py` e o script de novo (ele confere tudo e restaura o backup se falhar).
- **Boot sem texto** (`install/plymouth.sh`): Plymouth com o tema `noite-catppuccin` (mesma cena, estrelas piscando,
  logo do Arch, anel girando; gerado pelo `gen_ly_dur.py`), hook `plymouth` depois do `systemd`, kernel com
  `quiet splash loglevel=3 ...` e Limine `terse`. ESC no boot mostra o texto. **Não use `plymouth quit --retain-splash`**:
  deixa o tty1 em modo gráfico e o `chvt 2` do ly (drop-in `ly-kmsconvt@tty2.service.d`) espera 5 s.

## 5. Sistema

- Fuso `America/Sao_Paulo`, `LANG=pt_BR.UTF-8`, console `br-abnt2`, sudo via `/etc/sudoers.d/`.
- `pacman.conf`: Color, ParallelDownloads=10, multilib, **Chaotic-AUR**. `yay`, `flatpak`.
- Rede: NetworkManager (sem `wait-online`: boot ~3 s mais rápido). **DNS over TLS** via systemd-resolved
  (Quad9, Cloudflare de reserva, modo `opportunistic`; `resolvectl status`). Firewall `ufw` (SSH só da LAN 192.168.15.0/24;
  mDNS 5353/udp liberado). **`sshd` ativo com senha**
  (pendente: só chave — `install/ssh-somente-chave.sh`). Docker: portas `-p` ignoram o ufw (use `127.0.0.1:`).
- Energia: **power-profiles-daemon** (troca automática: bateria = Economia, tomada = Equilíbrio, pela ilha).
  Bluetooth: `bluez` + `blueman` (applet roda escondido, só para PIN de pareamento).
- **earlyoom** (`/etc/default/earlyoom`): sem memória, encerra o maior consumidor (prefere abas/Electron/Kdenlive;
  nunca Hyprland, ilha, áudio). O `systemd-oomd` **não** serve: os apps do Hyprland ficam no cgroup da sessão.
- `/boot` só para o root (fstab `fmask=0077,dmask=0077`): para ler o `limine.conf` use `sudo`.
- Manutenção: `btrfs-scrub@-.timer` (mensal), `paccache.timer` (semanal). fstrim não precisa (discard=async).
- **SSD** (Neo Forza NSP095P3451, 512 GB): `smartd` vigia o `/dev/nvme0` e avisa na ilha
  (`/etc/smartmontools/smartd-notificar.sh`). Em 05/11: 0% de desgaste, 2,01 TB gravados, 15 desligamentos bruscos.
- Busca de arquivos: `plocate` (`locate nome`; não indexa `/.snapshots`, `/nix`, Docker). Exemplos de comandos: `tldr` (Nix).
- **Minitela** (tela de 1,54" acima do teclado; `minitela/`, ver README): controlador GC9002 por USB serial
  (`0324:0324`, `/dev/minitela`, regra udev `uaccess` em `install/minitela.sh`). Serviço do usuário `minitela.service`
  (Python, só stdlib): relógio, bateria, Wi-Fi, BT, notificações da ilha, lembrete automático (música via
  playerctl ou CPU/RAM/temperatura), apaga no bloqueio/suspensão. Botão
  `XF86Launch7` = próxima página/apagar. **Só SET_REGISTER**, nunca HANDSHAKE/gravação; sem texto vazio; 0,15 s
  entre comandos; só envia o que mudou. Botão: sistema → mensagens → lembrete → imagens 1-3 → apagada.
  `minitela/config.json`: `inicio` (página ou `apagada`), `travada` (página fixa; botão só liga/desliga), `brilho`.
  **Imagens/temas** (`minitela/imagens.py`, GRAVA a flash, só a região de texturas): arquivos do `.deb` oficial
  extraídos sem instalar em `~/.local/share/minitela-oficial` (o `.deb` fica em `positivo-minitela/`, **no .gitignore**;
  o pacote abre todos os teclados para qualquer usuário: não instalar). Compilador `.exe` via Wine. Testado: imagem
  própria gravada e exibida. Tela congelou? Desligar por completo e `imagens.py fabrica`.
- **Impressão**: CUPS sem driver (IPP Everywhere) + avahi/nss-mdns (`mdns_minimal` no nsswitch); painel
  `system-config-printer` ou http://localhost:631 (`install/rede-impressora.sh`).
- **faillock** (padrão do Arch): 3 senhas erradas em 15 min bloqueiam a conta por 10 min (sudo e tela de bloqueio).
- Login: **`ly-kmsconvt@tty2`** (ly dentro do kmscon: FiraCode Nerd Font Mono 16 px = 12 pt, paleta Catppuccin em
  `/etc/kmscon/kmscon.conf`, **teclado `xkb-layout=br`** — sem ele o kmscon usa o americano; drop-in tira o
  `--font-engine unifont`). Teclado numérico no ly: `xkb-options=numpad:mac` (sempre números; o kmscon não tem Num Lock ligado). Desenho de fundo `catppuccin.dur`
  (`install/gen_ly_dur.py`), relógio grande, pt_BR completo (`lang/ptbr.ini`). `install/ly.sh` (etapas, teste no tty3;
  `kmscon-desfazer` volta ao `ly@tty2`). No kmscon o ly não lê as luzes do teclado: `hide_keyboard_locks` e o erro
  do num lock aparece como "bem-vindo de volta". TTYs: fonte Terminus `ter-v24b`. O ly futuro troca o `config.ini`
  por `config.lua`: migrar ao atualizar. **Chaveiro: gnome-keyring**, desbloqueado no login pelo PAM do ly (o aviso
  `gkr-pam: unable to locate daemon control file` é normal). VS Code: `password-store` no `~/.vscode/argv.json`;
  Electron do Nix (vesktop, obsidian): `--password-store=gnome-libsecret` via `_electron-keyring.nix`
  (o Obsidian usa; o Vesktop não criptografa nada, o login fica em `~/.config/vesktop/sessionData`, modo 700).

## 6. Gráficos, áudio, apps

- Mesa + RADV (Vulkan) + VA-API (codifica H.264/HEVC na GPU) + OpenCL (rusticl). PipeWire + WirePlumber.
- **Edição** (ver `docs/edicao-video-foto.md`): Kdenlive (render/proxy VAAPI), GIMP 3, darktable (OpenCL), Inkscape.
- Gravação de tela: `gpu-screen-recorder` (VA-API). Prints: `hyprshot` + `satty`.
- Padrões: vídeo → **mpv** (Nix), imagem → **qView** (Nix), links → Zen (Nix), pastas → Dolphin.
  Depois de instalar apps pelo Nix: `kbuildsycoca6` (o `hmsf` já faz) para o Dolphin enxergá-los.
- **Jogos** (ver `gamemode/README.md`; comandos do Steam em `docs/jogos-steam.md`): Steam nativo (multilib), GameMode (usuário no grupo `gamemode`),
  MangoHud, Gamescope (FSR), Proton-GE pelo flatpak ProtonPlus. `vm.max_map_count` já é 1048576 (padrão do Arch).
  O GameMode **não** troca o governor (fica `powersave`/EPP): o `gamemode/hook.sh` avisa a ilha, que liga o
  perfil Desempenho do power-profiles-daemon e volta ao anterior no fim.

## 7. Desktop: Hyprland 0.57 (config em Lua) + Quickshell

- **Hyprland em Lua** (`hypr/hyprland.lua`): nada de sintaxe antiga. API em `/usr/share/hypr/stubs/hl.meta.lua`.
  - `hyprctl dispatch` exige **Lua**: `hyprctl dispatch 'hl.dsp.focus({ workspace = 2 })'`,
    `'hl.dsp.dpms({action = "off"})'`, `'hl.dsp.exec_cmd("...")'`.
  - Monitor externo: regra genérica (preferred, à direita); `SUPER+SHIFT+P`/`XF86Display` alterna estender →
    espelhar → só externa → só notebook (`scripts/monitor.sh`, aplica com `hyprctl eval 'hl.monitor{...}'`).
  - Tecla principal **SUPER**. Todo atalho tem `description = "Categoria · O que faz"` (aparece no guia `SUPER+/`).
  - `hypr/scripts/`: `brightness.sh` (0% = mínimo útil da tela, passos de 5%), `screenshot.sh`, `record.sh`.
  - **Janelas escondidas** (`scripts/scratchpad.sh`, workspaces especiais): `SUPER+'` terminal (classe
    `dev.scratchpad.terminal`), `SUPER+O` Obsidian, `SUPER+A` Spotify. **Apps na workspace**: 1 Zen, 2 VS Code/Navicat,
    3 livre, 4 Kdenlive/GIMP/darktable/Inkscape, 5 Vesktop/Ferdium. PiP do Zen: flutua fixo no canto inferior direito.
  - **Ferramentas** (também na central de controle): `SUPER+SHIFT+C` conta-gotas (`conta-gotas.sh`, hyprpicker),
    `SUPER+SHIFT+T` texto da tela (`texto-da-tela.sh`, tesseract por+eng), `SUPER+SHIFT+F` **modo foco** (`Focus.qml`:
    Não perturbe + minitela ignora notificações via `$XDG_RUNTIME_DIR/modo-foco` + Vesktop/Ferdium em `special:foco`),
    `SUPER+SHIFT+Return` sessão de trabalho (`sessao-trabalho.sh`). Launcher: `@projeto` (pastas de `~/Projetos` + `.dotfiles`).
  - `hypridle`: tela de bloqueio aos 15 min (Quickshell, hyprlock de reserva), tela apaga aos 16 min,
    **suspende aos 30 min só na bateria** (`scripts/suspend-bateria.sh`). Suspensão em S3 (`deep`), testada (menu e tampa).
    `hyprsunset`: luz noturna por horário (`hypr/hyprsunset.conf`).
- **Quickshell, layout "moldura"** (padrão, `Theme.layout`; `"ilha"` = a ilha antiga): barra + borda em volta da
  tela, painéis que brotam da moldura (`quickshell/frame/`, ver README): central de controle (ícones Wi-Fi/BT/volume
  na barra; energia no canto esquerdo; Wi-Fi/BT/áudio
  tipo pavucontrol/brilho/luz noturna/bateria), mídia com capa, clima (IP + Open-Meteo, também na minitela), notificações
  agrupadas, `/arquivo` no launcher, moldura translúcida com desfoque. Mesmas funções da ilha: notificações
  (substitui o swaync), launcher (`SUPER+Space`: apps, `:emoji`, `=conta`, `>comando`; `SUPER+V` clipboard;
  `SUPER+SHIFT+Tab` lista de janelas), **visão geral das workspaces** (`SUPER+Tab` ou 3 dedos para cima;
  miniaturas ao vivo, arrastar move a janela), Wi-Fi/Bluetooth, menu de energia (`SUPER+X`), wallpapers (`SUPER+W`),
  gravação (`SUPER+R` / `SUPER+SHIFT+R`), guia de atalhos (`SUPER+/`), tela de bloqueio (`SUPER+L`, PAM `hyprlock`),
  atualizações pendentes na ilha aberta (`Updates.qml`; clique roda o `atualizar`).
  - Detalhes técnicos (singletons, bandeja, logs): `quickshell/CLAUDE.md`.
- Visual: Catppuccin Mocha, **FiraCode Nerd Font 12** (GTK, Qt, Ghostty), Breeze-Dark, Papirus-Dark, Bibata.
  Ghostty usa `GTK_IM_MODULE=simple` (senão os acentos não funcionam).
- Wallpaper: `awww` + waypaper (a ilha usa `waypaper --wallpaper`). Imagens em `~/Imagens/Wallpapers`,
  prints em `~/Imagens/Prints`, gravações em `~/Vídeos/Gravações`.

## 8. Nix (home-manager) e mise

- Flake em **`~/.dotfiles/nix-dotfiles`** (flake-parts + import-tree), perfil `homeConfigurations."7aauac"`
  (o `cauaarch` é do desktop). Flakes ativos via `~/.config/nix`.
  - `hmsf` = switch (+ kbuildsycoca6), `nfu` = update do flake, `hmn` = news. `atualizar` = tudo (pacman/AUR,
    flatpak, Nix, mise).
  - **Arquivo novo no flake precisa de `git add`** (o Nix ignora arquivos que o git não acompanha).
  - Módulos ativos: ver `modules/home-modules.nix` (Navicat é um `flatpakref` com `sha256` em `_flatpak.nix`).
  - GPU para apps do Nix: `non-nixos-gpu-setup` já rodado (`/run/opengl-driver`).
- **mise**: em `~/.local/bin/mise`, **sem linguagens globais** (só lazygit, lazydocker, usage).
  Use `mise use node@lts` etc. **por projeto** — um Python global quebra utilitários do Arch e pacotes do AUR.

## 9. Armadilhas conhecidas

- `pkill -f <padrão>` dentro de um comando que contém o mesmo padrão **mata o próprio shell**:
  filtre processos por `pgrep -x` / `/proc/<pid>/cmdline`.
- O shell é **zsh**: variáveis sem aspas não são divididas em palavras (cuidado ao passar listas), e
  `path` é especial (ligada ao `PATH`): `for path in ...` apaga o PATH. Teste trechos de bash com `bash -c`.
- `busctl status <nome>` pode ativar serviços D-Bus (use `busctl --user list`).
- Instalar um pacote do repo que não existe cancela a transação inteira (mova para o yay).
- Wi-Fi de casa com latência alta; downloads grandes demoram.
- `claude-desktop` do AUR é não oficial; no Arch o suportado é o Claude Code (CLI).

## 10. Repositório e versionamento

- Branch **`notebook-r15m`** (este notebook) com commits por assunto; `main` = desktop (ainda com Waybar).
- Plano: no desktop, **unificar numa `main` só** com `hosts/<máquina>/` para o que muda entre as máquinas
  (monitores/workspaces do Hyprland, `system/etc`, caminhos do VS Code), carregado pelo hostname.
- Pastas não óbvias: `rofi/` e `wlogout/` são reserva (launcher e menu de energia agora são da ilha); `system/` =
  cópias do `/etc` (atualizar com `sudo bash system/sync.sh`); `positivo-minitela/` = `.deb` oficial, fora do git.

## 11. Pendências

1. Jogos: testar um jogo de verdade (GameMode, MangoHud, Gamescope, Proton-GE).
2. Backup do `/home` (precisa de destino: HD externo ou nuvem).
3. SSH só com chave (copiar a chave do desktop; `install/ssh-somente-chave.sh`).
4. Unificar dotfiles na `main` com `hosts/` (no desktop).
