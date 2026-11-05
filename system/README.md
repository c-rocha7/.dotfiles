# Configurações do sistema (/etc) — notebook Positivo Vision R15M

Cópias dos arquivos do `/etc` que foram configurados na instalação, com o mesmo caminho
(`system/etc/...` = `/etc/...`). São **cópias, não links**: o `/etc` não pode depender do `/home`.

Atualizar as cópias (antes de commitar):

```bash
sudo bash ~/.dotfiles/system/sync.sh
```

## O que tem aqui

| Arquivo | Para quê |
|---|---|
| `etc/default/limine` | Limine + snapshots no menu (limine-mkinitcpio-hook / limine-snapper-sync) |
| `etc/mkinitcpio.conf` | Hooks do initramfs (systemd, `sd-btrfs-overlayfs` para iniciar por snapshots) |
| `etc/fstab` | Subvolumes Btrfs (`@`, `@home`, `@log`, `@pkg`, `@nix`, `@docker`, `@snapshots`) |
| `etc/systemd/zram-generator.conf` | Swap em RAM (zram) |
| `etc/pacman.conf`, `etc/pacman.d/chaotic-mirrorlist` | Cores, downloads paralelos, multilib, Chaotic-AUR |
| `etc/snapper/configs/root` | Limites dos snapshots do `/` |
| `etc/locale.*`, `etc/vconsole.conf`, `etc/hostname`, `etc/hosts` | Idioma pt_BR, teclado ABNT2, nome `vision-r15m` |
| `etc/sudoers.d/*` | sudo para o grupo wheel e asteriscos ao digitar a senha |
| `etc/nix/nix.conf`, `etc/systemd/system/nix-daemon.*` | Nix com o `/nix` em subvolume próprio (ver `install/fase1-subvolumes.sh`) |
| `etc/ufw/user*.rules` | Firewall: só SSH da rede local |

## Numa reinstalação

Não copie tudo de uma vez: restaure arquivo por arquivo, conferindo.

- `fstab`: os **UUIDs mudam** se a partição for recriada (confira com `blkid`).
- `default/limine`: o UUID do `root=` também muda.
- `sudoers.d`: depois de copiar, valide com `sudo visudo -c`.
- `snapper/configs/root`: crie a config com `snapper create-config` (ver `install/fase2-snapper.sh`) e depois ajuste.
- Os scripts de `install/` refazem subvolumes, snapper e Limine na ordem certa.
