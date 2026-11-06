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
| lembrete | seu lembrete (`minitela.py lembrete "..."`); sem lembrete, a **música tocando** (MPRIS/playerctl; ao trocar de música mostra 6 s) ou **CPU, RAM e temperatura**. `lembrete ""` volta ao automático |
| clima, gif1-3 | conteúdo de fábrica (o clima não é preenchido) |

A minitela apaga quando a tela é bloqueada ou o notebook suspende, e acende ao voltar
(o desbloqueio da ilha chama `loginctl unlock-session` para avisar).

**Botão da minitela** (tecla `XF86Launch7`, código 194; atalho no `hypr/hyprland.lua`): cada toque avança
sistema → mensagens → lembrete → imagem 1 → imagem 2 → imagem 3 → **apagada** → sistema. Apagada pelo botão, continua apagada até o
próximo toque (mesmo depois de bloquear/desbloquear) e não mostra notificações.

## Travar numa página e começar apagada

Salvo em `minitela/config.json` (vale a cada login):

| Comando | Efeito |
|---|---|
| `minitela.py travar gif1` | a tela fica sempre nessa página (notificações e música não trocam mais); o botão só liga/desliga |
| `minitela.py destravar` | volta ao normal |
| `minitela.py inicio apagada` | começa apagada (o botão acende); também `sistema`, `gif1`, etc. |
| `minitela.py brilho 40` | o brilho também fica salvo |

O serviço do usuário começa no **login**. Para a minitela já começar apagada **desde o boot** (tela do
ly), o `install/minitela.sh` instala `minitela-apagar.service` (sistema, roda antes do login): se o
`config.json` tiver `"inicio": "apagada"`, ele manda só o comando de brilho 0. O script fica em
`/usr/local/lib/minitela/` (cópia de `system/usr/local/lib/minitela/`), e não na pasta pessoal, porque roda como root.

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
  (reabrir a porta reinicia a tela). `estado` lê da própria tela a página, o brilho e o lembrete (`tela_*`).
- Na volta da suspensão o USB da tela reinicia: o serviço espera 3 s e tenta de novo se a porta ainda não responder.
- Registros que **não existem** neste firmware: CPU, GPU, qualidade do Wi-Fi, status do BT, mídia (as páginas de
  fábrica não têm onde desenhar). Por isso música e CPU vão no texto da página de lembrete.
- Imagens próprias e temas **gravam a flash** (só a região de texturas): ver a seção abaixo.

## Imagens próprias e temas (`imagens.py`, grava a flash)

Precisa dos arquivos do pacote oficial `minitela_1.0.20_amd64.deb` (guardado em `~/.dotfiles/positivo-minitela/`,
**fora do git**: proprietário e 208 MB), extraídos **sem instalar** (o pacote abre todos os teclados para
qualquer usuário via `99-custom-input.rules`; não usar):

```bash
O=~/.local/share/minitela-oficial; mkdir -p $O && cd $O
bsdtar -xOf ~/.dotfiles/positivo-minitela/deb/minitela_1.0.20_amd64.deb 'data.tar*' | bsdtar -xf -
7z x -y -o"$O/appimage" usr/share/minitela/resources/MiniPanel-0.1.6.AppImage 'resources/IDE_utils/*'
mv appimage/resources/IDE_utils IDE_utils && rm -rf appimage
sudo pacman -S wine          # o compilador da fabricante é um .exe de Windows
```

```bash
I=~/.dotfiles/minitela/imagens.py
python3 $I temas                    # 22 temas de fábrica (prévias em .../gifs_imagens/N.gif)
python3 $I tema 7                   # grava um tema pronto
python3 $I fabrica                  # volta ao padrão de fábrica
python3 $I compilar foto.jpg [b c]  # interface padrão com até 3 imagens suas (páginas gif1-3)
python3 $I gravar ~/.local/share/minitela-oficial/trabalho/minitela-AAAAMMDD-HHMMSS.acf
```

A gravação usa o código do app oficial (`vendor/minitela_ctl.py`, do minitela-r15): só a região de texturas
(0x08100000), nunca bootloader/calibração; o serviço é parado e religado sozinho. **Se a tela congelar**
(imagem que o firmware não desenha): desligue o notebook por completo, ligue e rode `imagens.py fabrica`.

## Créditos

Protocolo e achados (verificados na tela) dos projetos de engenharia reversa:
[caio-imperial/minitela-r15](https://github.com/caio-imperial/minitela-r15) (MIT) e
[martinswagner021/minitela-re](https://github.com/martinswagner021/minitela-re) (GPL-3.0).
O código aqui é próprio (só biblioteca padrão do Python).
