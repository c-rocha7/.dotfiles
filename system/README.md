# Configurações do sistema (/etc) — notebook Positivo Vision R15M

Cópias dos arquivos do `/etc` que foram configurados na instalação, com o mesmo caminho
(`system/etc/...` = `/etc/...`). São **cópias, não links**: o `/etc` não pode depender do `/home`.

Atualizar as cópias (antes de commitar):

```bash
sudo bash ~/.dotfiles/system/sync.sh
```

`system/boot/limine-tema/` não é cópia: são o wallpaper e a fonte do menu do Limine, gerados por
`install/gen_ly_dur.py` e instalados por `install/limine-tema.sh`.

## O que tem aqui

| Arquivo | Para quê |
|---|---|
| `etc/default/limine` | Limine + snapshots no menu (limine-mkinitcpio-hook / limine-snapper-sync) |
| `etc/boot/hooks/post.d/95-limine-fallback-assinado` | Secure Boot: copia o Limine assinado para a reserva `EFI/BOOT/BOOTX64.EFI` |
| `etc/mkinitcpio.conf` | Hooks do initramfs (systemd, `sd-btrfs-overlayfs` para iniciar por snapshots) |
| `etc/fstab` | Subvolumes Btrfs (`@`, `@home`, `@log`, `@pkg`, `@nix`, `@docker`, `@snapshots`) |
| `etc/systemd/zram-generator.conf` | Swap em RAM (zram) |
| `etc/pacman.conf`, `etc/pacman.d/chaotic-mirrorlist` | Cores, downloads paralelos, multilib, Chaotic-AUR |
| `etc/snapper/configs/root`, `etc/snapper/configs/home` | Limites dos snapshots do `/` e do `/home` |
| `etc/ly/`, `etc/kmscon/`, `etc/systemd/system/ly-kmsconvt@.service.d/` | Tela de login: config (Catppuccin, relógio grande), `startup.sh` (paleta do console), `lang/ptbr.ini`, desenho `catppuccin.dur` (gerado por `install/gen_ly_dur.py`); kmscon com FiraCode 16 px |
| `etc/locale.*`, `etc/vconsole.conf`, `etc/hostname`, `etc/hosts` | Idioma pt_BR, teclado ABNT2, nome `vision-r15m` |
| `etc/sudoers.d/*` | sudo para o grupo wheel e asteriscos ao digitar a senha |
| `etc/nix/nix.conf`, `etc/systemd/system/nix-daemon.*` | Nix com o `/nix` em subvolume próprio (ver `install/fase1-subvolumes.sh`) |
| `etc/default/earlyoom` | earlyoom: encerra o maior consumidor de memória antes de travar (nunca o desktop/áudio) |
| `etc/smartd.conf`, `etc/smartmontools/smartd-notificar.sh` | smartd vigia o NVMe e avisa na ilha (notificação crítica) |
| `etc/updatedb.conf` | plocate: não indexa `/.snapshots`, `/nix` nem o Docker |
| `etc/systemd/resolved.conf.d/10-dns-privado.conf`, `etc/NetworkManager/conf.d/dns.conf` | DNS over TLS (Quad9, modo flexível) via systemd-resolved |
| `etc/nsswitch.conf` | `mdns_minimal`: nomes `.local` e impressoras de rede (avahi) |
| `etc/ufw/user*.rules` | Firewall: só SSH da rede local |

## Numa reinstalação

Não copie tudo de uma vez: restaure arquivo por arquivo, conferindo.

- `fstab`: os **UUIDs mudam** se a partição for recriada (confira com `blkid`).
- `default/limine`: o UUID do `root=` também muda.
- `sudoers.d`: depois de copiar, valide com `sudo visudo -c`.
- `snapper/configs/root`: crie a config com `snapper create-config` (ver `install/fase2-snapper.sh`) e depois ajuste.
- Os scripts de `install/` refazem subvolumes, snapper e Limine na ordem certa.
