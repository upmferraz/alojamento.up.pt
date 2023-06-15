# Importar as bibliotecas necessárias
import imaplib
import email
import re
import requests
import os

# Definir as credenciais de acesso ao e-mail
with open(os.path.expandvars('$HOME/.private/mailcredentials')) as f:
    server = f.readline().strip()
    mailusername = f.readline().strip()
    mailpassword = f.readline().strip()

# Conectar ao servidor de e-mail via IMAP
imap = imaplib.IMAP4_SSL(server)
imap.login(mailusername, mailpassword)

# Selecionar a caixa de entrada
imap.select('INBOX')

# Buscar as mensagens que têm o assunto e o remetente desejados
status, messages = imap.search(None, '(SUBJECT "Enrollment Successful - Your SSL certificate is ready") (FROM "support@cert-manager.com")')

# Criar uma lista vazia para armazenar os links
links = []

# Percorrer as mensagens encontradas
for num in messages[0].split():
    # Buscar o conteúdo da mensagem
    status, data = imap.fetch(num, '(RFC822)')
    # Converter os bytes em string
    message = email.message_from_bytes(data[0][1])
    # Obter o corpo da mensagem
    body = message.get_payload(decode=True).decode()
    # Procurar os links que terminam em format=pemia usando uma expressão regular
    matches = re.findall(r'https?://\S+format=pemia', body)
    # Adicionar os links encontrados à lista
    links.extend(matches)

# Percorrer os links da lista
for link in links:
    # Obter o número da mensagem correspondente ao link
    num = messages[0].split()[links.index(link)]
    # Buscar o conteúdo da mensagem
    status, data = imap.fetch(num, '(RFC822)')
    # Converter os bytes em string
    message = email.message_from_bytes(data[0][1])
    # Obter o corpo da mensagem
    body = message.get_payload(decode=True).decode()
    # Fazer o download do link usando a biblioteca requests
    response = requests.get(link)
    # Verificar se o download foi bem sucedido
    if response.status_code == 200:
        # Procurar o nome comum nos e-mails usando uma expressão regular
        match = re.search(r'Common Name : (.*)', body)
        # Verificar se o nome comum foi encontrado
        if match:
            # Obter o nome comum do grupo de captura da expressão regular
            common_name = match.group(1).strip()
            # Substituir os . por _ no nome comum usando uma expressão regular
            common_name = re.sub(r'\.', '_', common_name)
            # Adicionar a extensão .pem ao final do nome comum
            common_name = common_name + '.pem'
            # Construir o caminho completo do ficheiro no diretório $HOME/Downloads/
            filepath = os.path.join(os.path.expandvars('$HOME/Downloads/'), common_name)
            # Escrever o conteúdo do link no ficheiro
            with open(filepath, 'wb') as g:
                g.write(response.content)
            # Mostrar uma mensagem de sucesso
            print(f'Link {link} salvo em {filepath}')
        else:
            # Mostrar uma mensagem de erro
            print(f'Não foi possível encontrar o nome comum no e-mail')
    else:
        # Mostrar uma mensagem de erro
        print(f'Erro ao fazer o download do link {link}: {response.status_code}')

    # Marcar o e-mail como eliminado
    imap.store(num, '+FLAGS', '\\Deleted')
    # Remover os e-mails marcados como eliminados
    imap.expunge()

# Fechar a conexão com o servidor de e-mail
imap.close()
imap.logout()
