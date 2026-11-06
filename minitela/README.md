# Minitela (Positivo Vision R15M)

Tela secundária de 1,54" (240x240) acima do teclado. É um controlador **GC9002 ("AHMI")**
ligado por USB serial: `CherryUSB sxw-admin CDC_DEMO` (`0324:0324`), em `/dev/ttyACM0`
(atalho `/dev/minitela`). O firmware já desenha as páginas; o `minitela.py` só **preenche
valores** (relógio, bateria, Wi-Fi, Bluetooth, notificação, lembrete, página, brilho).

## O que aparece

| Página | Conteúdo |
|---|---|
| sistema (padrão) | data e hora, bateria (texto + ícone), Wi-Fi, Bluetooth |
| mensagens | cada notificação que chega na ilha (volta para "sistema" depois de 10 s) |
| lembrete | o texto de `minitela.py lembrete "..."` |
| clima, gif1-3 | conteúdo de fábrica (o clima não é preenchido) |

A minitela apaga quando a tela é bloqueada ou o notebook suspende, e acende ao voltar
(o desbloqueio da ilha chama `loginctl unlock-session` para avisar).

**Botão da minitela** (tecla `XF86Launch7`, código 194; atalho no `hypr/hyprland.lua`): cada toque avança
sistema → mensagens → lembrete → **apagada** → sistema. Apagada pelo botão, continua apagada até o
próximo toque (mesmo depois de bloquear/desbloquear) e não mostra notificações.

## Uso

```bash
sudo bash ~/.dotfiles/install/minitela.sh                          # uma vez: permissão (udev)
systemctl --user enable --now ~/.dotfiles/minitela/minitela.service  # serviço
M=~/.dotfiles/minitela/minitela.py
$M estado | $M botao | $M brilho 40 | $M pagina sistema | $M lembrete "Reunião 15h" | $M notificar "Teste" "oi"
journalctl --user -u minitela -f                                   # log
```

## Segurança (não mexer sem ler)

- Só o comando `SET_REGISTER` (0x0090). **Nunca** `HANDSHAKE` (põe a tela em modo de gravação até
  reiniciar), `SWITCH_STATE`, `REQUEST_DOWNLOAD`/`DOWNLOAD_DATA` (gravam a flash) ou `REBOOT`.
- **Texto vazio corrompe** a tabela de registros (só volta reiniciando): mandamos `" "`.
- Mandar o mesmo valor sem parar também corrompe: o serviço só envia o que mudou.
- Comandos em sequência rápida corrompem a tela: **0,15 s** entre comandos e espera a confirmação de
  cada um (o buffer de respostas da tela é pequeno). Se travar: `systemctl --user restart minitela`
  (reabrir a porta reinicia a tela). `estado` lê da própria tela a página e o brilho (`tela_*`).
- Registros que **não existem** neste firmware: CPU, GPU, qualidade do Wi-Fi, status do BT, mídia.
- Imagens próprias e temas gravam a flash (risco de travar a tela; recuperar exige corte de energia)
  e precisam do compilador do app oficial (Windows/Wine): **não implementado**.

## Créditos

Protocolo e achados (verificados na tela) dos projetos de engenharia reversa:
[caio-imperial/minitela-r15](https://github.com/caio-imperial/minitela-r15) (MIT) e
[martinswagner021/minitela-re](https://github.com/martinswagner021/minitela-re) (GPL-3.0).
O código aqui é próprio (só biblioteca padrão do Python).
