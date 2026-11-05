# Edição de vídeo e foto

Apps (pacman): **Kdenlive** (vídeo), **GIMP 3** (imagem), **darktable** (fotos RAW), **Inkscape** (vetor).

```bash
sudo pacman -S kdenlive kimageformats qt6-imageformats noise-suppression-for-voice \
               sox rnnoise ladspa gimp darktable opencl-mesa clinfo inkscape
```

Padrões de abertura: imagens no **qView**, vídeos no **mpv**, RAW no darktable, `.xcf` no GIMP,
`.kdenlive` no Kdenlive (`xdg-mime default gimp.desktop image/x-xcf`).

## GPU (Radeon Vega integrada)

| Recurso | Situação | Testar |
|---|---|---|
| VA-API (vídeo) | decodifica H.264, HEVC (8/10 bits), VP9; **codifica H.264 e HEVC**. Sem AV1. | `vainfo` |
| OpenCL (darktable) | Mesa **rusticl**, ligado sozinho (OpenCL 3.1) | `clinfo -l`, `darktable-cltest` |

O aviso "Patched Mesa libclc not detected" do rusticl é normal; o `darktable-cltest` passa sem erros.

## Kdenlive

- **Renderizar pela GPU**: na janela de renderização, use os perfis com **VAAPI** no nome
  (H.264 ou HEVC). Deixa a CPU livre para os efeitos. Se um perfil VAAPI der erro, use o x264 normal.
- **Proxies** (editar liso no notebook): Configurações → Configurar o Kdenlive → Clipes proxy →
  ative e escolha o perfil **x264-vaapi**. Para vídeo de celular (HEVC/4K) faz muita diferença.
  Na timeline, botão de proxy ligado; na renderização, "Usar clipes proxy" **desligado**.
- **Prévia da timeline** (pré-renderizar trechos pesados): `Shift+Enter` na região marcada.
- Remover ruído de voz: efeito **Noise Suppression for Voice** (pacote `noise-suppression-for-voice`).
- Rastreamento de movimento precisa do `opencv` (não instalado; `sudo pacman -S opencv`).

Comando equivalente ao perfil VAAPI (para converter vídeo no terminal):

```bash
ffmpeg -vaapi_device /dev/dri/renderD128 -i entrada.mov \
       -vf 'format=nv12,hwupload' -c:v h264_vaapi -b:v 12M -c:a aac saida.mp4
# HEVC (arquivo menor): troque h264_vaapi por hevc_vaapi
```

## darktable

- OpenCL já vem ligado (Preferências → Processamento → "usar OpenCL"). Com memória compartilhada
  (APU), se ficar instável, troque o perfil de agendamento OpenCL para **"muito rápido de GPU"** ou desligue.
- Catálogo e configurações ficam em `~/.config/darktable` (não versionado: é o banco de dados das fotos).

## GIMP 3

- Tema escuro por padrão. Abre PSD; exporte com Arquivo → Exportar como (`Ctrl+Shift+E`);
  `Ctrl+S` salva só em `.xcf` (projeto).
