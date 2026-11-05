# Jogos no Steam: opções de inicialização

Onde colar: Steam → clique direito no jogo → Propriedades → Geral → **Opções de inicialização**.
Configuração do GameMode e do MangoHud: `gamemode/` e `MangoHud/` (ver `gamemode/README.md`).

## Padrão (todo jogo)

GameMode (perfil Desempenho + prioridade) e MangoHud (FPS, temperatura etc.):

```
gamemoderun mangohud %command%
```

## Jogo pesado (720p ampliado para 1080p com FSR)

Roda o jogo em 1280x720 e o Gamescope amplia para a tela (1920x1080) com o FSR da AMD.
Dentro do Gamescope o overlay é o `--mangoapp` (no lugar de `mangohud`):

```
gamescope -w 1280 -h 720 -W 1920 -H 1080 -F fsr -f --mangoapp -- gamemoderun %command%
```

Variações:

- Mais leve ainda: `-w 960 -h 540` (540p).
- Limitar o FPS (economiza bateria e esquenta menos): acrescente `-r 30` antes do `--`.

## Atalhos do MangoHud no jogo

| Atalho | Ação |
|---|---|
| Shift direito + F12 | Mostra/esconde o overlay |
| Shift direito + F11 | Troca o canto |
| Shift esquerdo + F1 | Limite de FPS: sem limite → 30 → 60 |

## Proton

1. Steam → Configurações → Compatibilidade → **Ativar o Steam Play para todos os outros títulos**.
2. **Proton-GE**: abra o ProtonPlus (flatpak), escolha Steam e instale o GE-Proton mais recente.
3. Reinicie o Steam e, no jogo, Propriedades → Compatibilidade → escolha o **GE-Proton**.
