#!/bin/bash
DISPLAY=:0

scriptsdir=/home/mferraz/scripts/certificados/
downloadsdir=/home/mferraz/downloads/

cd $downloadsdir

# Verificar se existem ficheiros *_*.pem
if ! ls *_*.pem 2>/dev/null ; then
	echo 'Não há certificados para instalar.'
	exit
fi

for i in $(ls *_*.pem); do
	output=$($scriptsdir/instala-certificado-https.sh $i)
	if [[ $output == *"OK"* ]]; then
		notify-send "Certificado instalado: $output"
	else
		notify-send "Certificado não instalado: $output"
	fi
done
