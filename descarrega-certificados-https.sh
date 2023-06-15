#!/bin/bash

# Importar as variáveis de autenticação do arquivo ~/.private
source ~/.private

# Configurações da conexão IMAP com o servidor de e-mail
SERVER="mail.up.pt"
USERNAME="$mailusername"
PASSWORD="$mailpassword"

# Conecte-se ao servidor e selecione a caixa de entrada
exec 3<>/dev/tcp/${SERVER}/993
openssl s_client -connect ${SERVER}:993 -quiet <&3 &
pid=$!
echo "a001 LOGIN ${USERNAME} ${PASSWORD}" >&3
echo "a002 SELECT inbox" >&3
echo "a003 SEARCH SUBJECT \"Enrollment Successful - Your SSL certificate is ready\"" >&3

# Ler as mensagens do servidor e obter o link usando o corpo do e-mail
while read -r line; do
  if [[ "$line" =~ ^a003.* ]]; then
    search_result="$line"
  elif [[ "$line" =~ ^\*.* ]]; then
    message_id=$(echo "$line" | awk '{print $2}')
    echo "a004 FETCH $message_id (BODY[TEXT])" >&3
  fi

  # Encontrar o link diretamente no resultado do comando FETCH usando o comando grep
  response=$(cat <&3 | tr -d '\r')
  url=$(echo "$response" | grep -o 'https://cert-manager.com/customer/fccn/ssl?action=download.*format=pemia')

  if [[ ! -z $url ]]; then
    echo "Link encontrado no e-mail"
    file_name="certificado.pemia"
    curl --output "$HOME/Downloads/${file_name}" "${url}"
    echo "Arquivo salvo em $HOME/Downloads/${file_name}"
    break
  fi
done < <(timeout 60 tail -f <&3 | tee /dev/null)

# Encerrar a conexão com o servidor IMAP
echo "a005 LOGOUT" >&3
wait $pid
exec 3<&-

