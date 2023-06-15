#!/bin/bash
#Instalador de certificados HTTPS
#v23.05.18
#mferraz@uporto.pt

# config
avhost_path="/etc/apache2/sites-available/" # localização da configuração dos vhosts apache

# script
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color


if [[ $1 == "" ]]; then 
	echo "./$0 certificado servidor"
	exit 0
fi


#host=`echo ${1##*/} | sed s/_cert.cer//g | sed s/_/./g`
host=`echo ${1##*/} | sed s/.pem//g | sed s/_/./g`
csr="$host.pem"
key="/etc/ssl/private/$host.key"

#cat $cabundle >> $1
mv $1 $host.pem

# se nao for indicado host, usar o host do certificado
if [[ $2 == "" ]]; then
	hostsrv=$host
	# verifica no DNS se é um servidor em www.up.pt
	hostsrvdns=`host $host | grep "has address" | cut -f 4 -d " " | uniq`
	if [[ $hostsrvdns == "193.137.55.13" ]]; then
		hostsrv="www1.up.pt"
	fi
else 
	hostsrv=$2
fi

# verifica qual o servidor web (apenas para nginx ou apache)
websrvchk=`ssh root@$hostsrv netstat -putan | grep :443 | grep apache | grep -v 127.0.0.1 | head -1`
if [[ $websrvchk == "" ]]; then
	webserver="nginx"
else
	webserver="apache"
fi

	# validar certificado com a chave
	valcsr=`openssl x509 -noout -modulus -in $csr | openssl md5 | cut -f 2 -d " "`
	valkey=`ssh root@$hostsrv openssl rsa -noout -modulus -in $key | openssl md5 | cut -f 2 -d " "`

# se validar, instalar
if [[ "$valcsr" == "$valkey" ]]; then

	scp $host.pem root@$hostsrv:/etc/ssl/
else 
	echo -e "${RED}[Erro]${NC} A chave e certificado não coincidem. A chave não foi instalada."
	exit 0
fi

# renomeia o certificado snakeoil
if [[ $webserver == "apache" ]]; then
	conffile=`ssh root@$hostsrv "apachectl -S | grep 443 | grep $host | cut -f 5 -d "/" | cut -f 1 -d :"`	
	ssh root@$hostsrv sed s/ssl-cert-snakeoil/$host/g -i $avhost_path$conffile
	ssh root@$hostsrv sed s^/etc/ssl/certs/^/etc/ssl/^g -i $avhost_path$conffile
fi

# reload ao servidor web se nao der erro

if [[ $webserver == "apache" ]]; then
	wstst=`ssh root@$hostsrv "apachectl -t 2>&1 | grep 'Syntax OK'"`
	if [[ $wstst == "Syntax OK" ]]; then
		ssh root@$hostsrv service apache2 reload
		echo -e "${GREEN}[OK]${NC}$host" 
	else 
		echo -e "${RED}[ERRO]${NC}Erro na validacao da configuracao do servidor web $hostsrv${NC}"
		exit 0
	fi
else 
	wstst=`ssh root@$hostsrv "nginx -t 2>&1 | grep \"test is successful\""`
	if [[ $wstst != "" ]]; then
		ssh root@$hostsrv service nginx reload
		echo -e "${GREEN}[OK]${NC}$host"
	else
		echo -e "${RED}[ERRO]${NC}Erro na validacao da configuracao do servidor web $hostsrv${NC}"
		exit 0
	fi
fi

# sync entre servidores www.up.pt
if [[ $hostsrvdns == "193.137.55.13" ]]; then
	ssh root@$hostsrv scripts/sync-www.sh
fi

rm $host.pem
