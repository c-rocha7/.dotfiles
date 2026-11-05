# Scripts de instalação (notebook Positivo Vision R15M)

Scripts usados na configuração do sistema, na ordem. Todos param no primeiro erro,
conferem o estado antes de mexer e fazem backup do que alteram. Rodar com `sudo bash <script>`.

| Ordem | Script | O que faz |
|---|---|---|
| 1 | `fase1-subvolumes.sh` | Cria `@nix`, `@docker` e `@snapshots`; move `/nix` e `/var/lib/docker`; ajusta o serviço do Nix para subir no boot. **Reiniciar** e apagar os `.old`. |
| 2 | `fase2-snapper.sh` | Snapper do `/` com snapshots em `@snapshots`, snap-pac (antes/depois do pacman), limites e limpeza. |
| 3 | `fase3-limine-snapper.sh` | Snapshots no menu do Limine (limine-mkinitcpio-hook + limine-snapper-sync). **Reiniciar** e testar a entrada nova e um snapshot. |
| 4 | `fase3-limpeza.sh` | Remove a entrada "backup manual", o kernel antigo, a entrada antiga da BIOS e o hook antigo. |
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
