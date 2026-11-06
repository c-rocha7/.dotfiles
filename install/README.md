# Scripts de instalação (notebook Positivo Vision R15M)

Scripts usados na configuração do sistema, na ordem. Todos param no primeiro erro,
conferem o estado antes de mexer e fazem backup do que alteram. Rodar com `sudo bash <script>`.

| Ordem | Script | O que faz |
|---|---|---|
| 1 | `fase1-subvolumes.sh` | Cria `@nix`, `@docker` e `@snapshots`; move `/nix` e `/var/lib/docker`; ajusta o serviço do Nix para subir no boot. **Reiniciar** e apagar os `.old`. |
| 2 | `fase2-snapper.sh` | Snapper do `/` com snapshots em `@snapshots`, snap-pac (antes/depois do pacman), limites e limpeza. |
| 3 | `fase3-limine-snapper.sh` | Snapshots no menu do Limine (limine-mkinitcpio-hook + limine-snapper-sync). **Reiniciar** e testar a entrada nova e um snapshot. |
| 4 | `fase3-limpeza.sh` | Remove a entrada "backup manual", o kernel antigo, a entrada antiga da BIOS e o hook antigo. |
| 5 | `fase4-secure-boot.sh` | Secure Boot com chaves próprias (sbctl) + hash do `limine.conf` no Limine; tira o "EFI fallback" do menu. Em partes: `preparar` → reiniciar → BIOS em Setup Mode → `chaves` → BIOS liga o Secure Boot → `status`. |
| – | `ajustes-sistema.sh` | `/boot` só para o root (fstab `fmask/dmask=0077`) e earlyoom. |
| – | `ssd-saude.sh` | smartmontools + smartd vigiando o SSD, com aviso na ilha e notificação de teste. |
| – | `plocate.sh` | Busca de arquivos (`locate`), sem indexar snapshots, `/nix` e Docker. |
| – | `snapshots-home.sh` | Snapshots horários do `/home` (snapper); `~/.cache` e Steam ficam fora. Não é backup. |
| – | `rede-impressora.sh` | Boot sem esperar a rede, DNS criptografado (desfaz se falhar) e impressora de rede sem driver. |
| – | `ly.sh` | Tela de login ly: Catppuccin, desenho de fundo, relógio grande, pt_BR completo. Em etapas: aplicar → `kmscon-teste` → `kmscon-ativar` (FiraCode igual ao sistema). Teste no tty3. |
| – | `gen_ly_dur.py` | Gera o desenho "noite Catppuccin": fundo do ly (`.dur`), wallpaper e fonte do Limine. |
| – | `limine-tema.sh` | Visual do menu do Limine (wallpaper do ly, Catppuccin, Terminus 2x), com hash para o Secure Boot; confere e desfaz sozinho se falhar. |
| – | `plymouth.sh` | Boot sem texto: Plymouth com a cena do Limine/ly (estrelas, logo do Arch, anel girando); `desfazer` volta ao texto. |
| – | `minitela.sh` | Permissão da minitela (udev `uaccess`, `/dev/minitela`); o serviço fica em `minitela/`. |
| – | `manutencao.sh` | Scrub mensal do Btrfs e limpeza semanal do cache do pacman. |
| – | `ssh-somente-chave.sh` | **Pendente:** SSH só com chave (copiar a chave do desktop antes). |
| – | `gen_emojis.py` | Regera a lista de emojis do launcher (instruções no arquivo). |

O UUID da partição Btrfs (`61b69d0d-…`) está fixo nos scripts das fases 1 a 3: numa
reinstalação, troque pelo novo (`blkid`).

## Restaurar um snapshot

- Pelo menu do Limine: **Snapshots** → escolher → o sistema inicia daquele ponto → aviso
  "Restaurar agora" (ou `limine-snapper-restore`).
- Pela interface: `btrfs-assistant` → Snapper → Restore.
- O kernel agora é gerenciado pelo `limine-update` (não use `mkinitcpio -P`).
