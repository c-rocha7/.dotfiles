# Dual boot com o Windows 11

Objetivo: instalar o Windows 11 no mesmo NVMe **sem mudar nada no Arch** (Btrfs, subvolumes, Limine,
snapshots, Secure Boot continuam como estão). Script: `install/dual-boot-windows.sh`.

## Por que funciona sem mexer no Arch

- **Secure Boot**: o `db` já tem os certificados da Microsoft (`Windows Production PCA 2011` e
  `Windows UEFI CA 2023`; o `sbctl enroll-keys -m` os incluiu). O Windows inicia com o Secure Boot ligado.
- **TPM 2.0**: presente (fTPM do Ryzen). Requisito do Windows 11 atendido.
- **ESP de 1 GiB** com ~140 MB usados: o Windows usa a mesma ESP (`EFI/Microsoft`, ~50 MB). O limite de 80%
  do `limine-snapper-sync` continua folgado.
- **Espaço**: o Btrfs usa ~100 GB de 476 GB; dá para tirar 100–200 GB com o sistema rodando.

## Passo a passo

### 0. Antes (no Arch)

1. **Backup** do que importa em outro lugar (os snapshots estão no mesmo SSD; repartição sempre tem risco).
2. Pendrive do Windows 11 (ISO da Microsoft). No Linux, o `install.wim` passa de 4 GB e o FAT32 não aceita:
   use o **WoeUSB-ng** (AUR) ou, se tiver outro PC com Windows, a Media Creation Tool.
   Ventoy funciona, mas com Secure Boot pede o registro de uma chave MOK no primeiro boot.
3. Pendrive do Arch à mão (recuperação).

### 1. Liberar espaço

```sh
sudo bash ~/.dotfiles/install/dual-boot-windows.sh status
sudo bash ~/.dotfiles/install/dual-boot-windows.sh encolher 150   # GiB para o Windows
```

Encolhe o Btrfs e a `nvme0n1p2` (mesmo início e mesmo UUID: fstab e Limine não mudam) e deixa o fim do disco
não alocado. Reinicie uma vez no Arch para confirmar que está tudo normal antes de instalar o Windows.

### 2. Instalar o Windows

- Boot pelo pendrive: menu de boot da BIOS (com o Fast Boot ligado talvez precise de
  `systemctl reboot --firmware-setup` e escolher o pendrive lá).
- Na tela de discos: escolha o **"Espaço não alocado"** e clique em Avançar. **Não apague, formate nem
  "limpe" nenhuma outra partição.** O Windows reaproveita a ESP e cria MSR + Windows + Recuperação.
- Conta local (sem conta Microsoft): no OOBE, `Shift+F10` → `start ms-cxh:localonly` (builds recentes;
  o antigo `oobe\bypassnro` foi removido).

### 3. Ajustes dentro do Windows

1. **Desligar a Inicialização rápida** (Painel de Controle → Opções de energia → "Escolher a função dos botões"),
   ou de vez: `powercfg /h off` (Prompt como admin). Com ela ligada o NTFS fica "hibernado" e o Linux não
   deve gravar nele.
2. **Relógio**: o Windows usa o relógio da BIOS no horário local; o Linux, em UTC. No Windows (admin):
   `reg add "HKLM\System\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /t REG_DWORD /d 1 /f`
3. **BitLocker / Criptografia do dispositivo**: o Windows 11 liga sozinho. **Salve a chave de recuperação**
   (conta Microsoft: aka.ms/myrecoverykey, ou `manage-bde -protectors -get C:`). Mexer no Secure Boot
   (chaves do sbctl, desligar na BIOS) ou na forma de iniciar o Windows pede essa chave. Se não precisar de
   criptografia no Windows, desligue em Configurações → Privacidade e segurança → Criptografia do dispositivo.
4. Avisos de "atualização dos certificados de Secure Boot" no Windows são esperados: a Microsoft não consegue
   gravar no KEK porque o PK é o do sbctl. Os certificados de 2023 já estão no `db`; nada quebra.

### 4. De volta ao Arch

O Windows se coloca em 1º na BIOS e troca o `EFI/BOOT/BOOTX64.EFI` (reserva "UEFI OS") pelo dele.
Entre no Arch pelo menu de boot da BIOS (entrada **Limine**) e rode:

```sh
sudo bash ~/.dotfiles/install/dual-boot-windows.sh pos-windows
```

(Limine em 1º, reserva restaurada com o Limine assinado. O próximo `limine-update` faria o mesmo pelo
gancho `95-limine-fallback-assinado`.)

## Como escolher o sistema no boot

- **Padrão: Arch** (Limine, como hoje).
- **Windows no menu do Limine**: `sudo bash ~/.dotfiles/install/dual-boot-windows.sh limine-windows`
  (entrada "Windows 11" com `limine-entry-tool --add-efi`; o `limine.conf` continua gerado e os ganchos
  regravam o hash e assinam). Entradas `protocol: efi` não precisam de hash: quem confere a assinatura do
  `bootmgfw.efi` é a BIOS (certificados da Microsoft no `db`), então atualizações do Windows não travam a entrada.
  `FIND_BOOTLOADERS` continua `no` (senão volta o "EFI fallback"). Remover: `... limine-windows-remover`.
- **Sem passar pelo menu**: `sudo bash ~/.dotfiles/install/dual-boot-windows.sh windows` (reinicia no Windows
  só uma vez, via `efibootmgr --bootnext`) ou o menu de boot da BIOS.
- BitLocker: se o Windows pedir a chave de recuperação ao iniciar pelo Limine, digite-a uma vez e use sempre
  o mesmo caminho (Limine **ou** BIOS); ou desligue a criptografia do dispositivo.

## Depois (opcional)

- Ler os arquivos do Windows no Arch: driver `ntfs3` do kernel (`sudo mount -t ntfs3 -o ro /dev/nvme0n1pX /mnt`;
  só grave com a hibernação/Inicialização rápida desligada). O Windows não lê Btrfs (WinBtrfs existe, não recomendado).
- Fones/mouses Bluetooth pareados nos dois sistemas trocam de chave a cada pareamento: dá para copiar a chave
  do Windows para `/var/lib/bluetooth/` (ferramenta `bt-dualboot`).
- Atalho "Reiniciar no Windows" no menu de energia do Quickshell (precisa de regra no sudoers para o `efibootmgr -n`).

## Desfazer

Apague as partições do Windows (gparted no Arch) e a pasta `/boot/EFI/Microsoft`, remova a entrada da BIOS
(`sudo efibootmgr -b XXXX -B`) e devolva o espaço ao Arch:
`sudo bash ~/.dotfiles/install/dual-boot-windows.sh desfazer`.
