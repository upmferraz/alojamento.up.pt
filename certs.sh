#!/bin/bash
SHELL=/bin/bash

source $HOME/.private/webcertificados.conf
cd $scriptsdir

until grep -q "Não há certificados para instalar." <<< "$(./certificados.sh;)" 
do 
	echo "Aguardando os certificados…"
       	sleep 1
done
