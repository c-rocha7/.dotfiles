#!/usr/bin/env bash
# SSH só com chave: desliga login por senha e login como root.
# PENDENTE no notebook. Só rode DEPOIS de, no desktop:
#   ssh-copy-id 7aauac@<ip-do-notebook>   e testar   ssh 7aauac@<ip>   (sem pedir senha)
#
# Rodar com:  sudo bash ssh-somente-chave.sh

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Rode com sudo."; exit 1; }

KEYS=/home/7aauac/.ssh/authorized_keys
if [[ ! -s "$KEYS" ]]; then
    echo "Nenhuma chave em $KEYS. Copie a chave do desktop primeiro (ssh-copy-id). Nada foi alterado."
    exit 1
fi
echo ">> Chaves autorizadas encontradas: $(grep -c . "$KEYS")"

# O sshd usa o primeiro valor que encontrar; o prefixo 10- faz este arquivo
# ser lido antes dos padrões do Arch (20-, 99-).
CONF=/etc/ssh/sshd_config.d/10-seguranca.conf
cat > "$CONF" <<'EOF'
# Acesso só por chave, sem root (rede local já restrita pelo ufw).
PasswordAuthentication no
PermitRootLogin no
AllowUsers 7aauac
EOF
chmod 644 "$CONF"

echo ">> Validando a configuração"
if ! sshd -t; then
    rm -f "$CONF"
    echo "Configuração inválida: arquivo removido, nada mudou."
    exit 1
fi

systemctl reload sshd
sshd -T | grep -E '^(passwordauthentication|permitrootlogin|pubkeyauthentication|allowusers) '
echo
echo "Pronto. Para desfazer: sudo rm $CONF && sudo systemctl reload sshd"
