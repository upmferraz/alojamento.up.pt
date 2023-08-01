# up-instalador-certificados-web
Instalador automatizado de certificados web (para Linux cliente e servidor)


- Definir as configurações com base nos ficheiros em .conf.orig, os ficheiros deverão ser copiados com as devidas configurações para $HOME/.private/

- Definir a localização dos downloads no ficheiro downloads-instala-certificados-https.sh

- Definir as credenciais de acesso ao e-mail no ficheiro HOME/.private/mailcredentials (se o PC for partilhado verificar as permissões do ficheiro, a cifra das credenciais ainda está por ser implementada) que deverá conter por linha o seguinte:

hostname
username
password

A ligação será feita por IMAP, e após a descarga do ficheiro .pem com a colocação do nome que irá ser retirado da linha "Common Name" do corpo do email, irá salvaguardar com o nome do host separado por _ em vez de .
No final o email será eliminado.

Os emails que serão pesquisados serão os que contenham o assunto "Enrollment Successful - Your SSL certificate is ready" com o remetente "support@cert-manager.com"

As configurações do ficheiro instala-certificado-https.sh apenas incluem a localização dos ficheiros vhost para os Apache, para a configuração da localização dos novos certificados ser alterada se se mantiver a standard que inclui o snakeoil, apenas servirá para a primeira instalação do certificado.
Este script inclui uma rotina de sincronização particular para servidores onde existe a replicação de configurações.

As ligações são sempre feitas com base no hostname definido no ficheiro do certificado descarregado, refazendo o nome substituindo os _ por . com queries ao DNS e ligações por ssh com o user root. Ainda não existe implementação para casos em que a instalação deva ser feita com um utilizador que faça posteriormente sudo.


