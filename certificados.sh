#!/bin/bash
# Define o endereço do servidor de testes
SERVER="web.up.pt"

# Tenta conectar ao servidor na porta 22
nc -z -w5 $SERVER 22 >/dev/null 2>&1

# Verifica o status de saída do comando anterior
if [ $? -eq 0 ]; then
	cd $HOME/scripts/certificados
	python3 get-certificates-from-mail.py
	./downloads-instala-certificados-https.sh
else
  echo "Não é possível ligar aos servidores da UP, verificar rede e ligação VPN"
  exit 1
fi

