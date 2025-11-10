#! /bin/sh

echo "ANALISE DE VELOCIDADES:  Painel NMO "
########################################################################
# AGG232 e AGG323 -Sismica I  e  II
# Profs.: Liliana e Renato
########################################################################

# Pode entrar com nome do arquivo e valores de velocidade pelo comando de linha
#	file vmin dv vmax
# EXEMPLO:
# sh velan1.sh cdp.data 1300 100 3000

indata=$1 fv=$2 dv=$3 vmax=$4
# Se esquecer ou nao quiser, o shel vai pedir entrada pelo teclado

rm -f panel.* picks.* par.* tmp*

#------------------------------------------------
# Definindo Variaveis etc...
#------------------------------------------------

#indata=cdp.data
if [ -z "$indata" ]; then 
echo Entre com o nome do arquivo de dados
read indata
fi
echo "Analise de Velocidades"

#*****************
## !!!!!!!!! VERIFICAR SE nt E dt ESTAO CORRETOS !!!!!!!!!!
#surange <$indata
nt=251
dt=0.008
#****************

outdata=vpick.data

if [ -z "$fv" ]; then 
echo "qual a primeira velocidade?" 
read fv
echo "qual o intervalo de velocidades?" 
read dv
echo "qual a maxima velocidade?" 
read vmax
fi

nv=`bc -l <<-END
scale=0
(($vmax - $fv) / $dv) + 1
END`
echo "painel com $nv velocidades"

>$outdata   # cria arquivo vazio
>par.cmp    #  "      "      "

#------------------------------------------------
# Analise Interativa de Velocidades...
#------------------------------------------------

echo "Analisar quantos conjuntos CMP?" >/dev/tty 
read nrpicks

i=1	
while [ $i -le $nrpicks ]
do
    echo "Especifique o conjunto CMP desejado $i" >/dev/tty 
    read picknow
    echo "Preparing Location $i of $nrpicks for Picking "
#    echo " CMP $picknow "

#------------------------------------------------
# CMP Plotagem...
#------------------------------------------------

    suwind <$indata key=cdp min=$picknow \
            max=$picknow >cmp.$picknow 
    suxwigb <cmp.$picknow xbox=422 ybox=10 \
             wbox=400 hbox=600 \
             title="CMP gather $picknow" \
             perc=94 key=offset verbose=0 2> /dev/null &
    
#------------------------------------------------
# Painel CVS (Constant Velocity Stack) aguarde...
#e
# Painel NMO 
#------------------------------------------------

    >tmp1
    >tmp.pnmo
	trpnmo=$(surange <cmp.$picknow | head -c 2 )
lpnmo=`bc -l <<-END
$dv / ($trpnmo + 2)
END`

echo
echo cmp $picknow com $trpnmo tracos
echo

    j=1
    k=`expr $picknow + 9`
l=`bc -l <<-END
$dv / 12
END`
ld2num=`bc -l <<-END
2 * $dv
END`
    suwind <$indata key=cdp min=$picknow \
            max=$k >tmp0
    while [ $j -le $nv ]
    do
vel=`bc -l <<-END
$fv + $dv * ( $j - 1)
END`
	sunmo <tmp0 vnmo=$vel 2> /dev/null |sustack >>tmp1
        sunull ntr=2 nt=$nt dt=$dt >>tmp1
	sunmo <cmp.$picknow vnmo=$vel 2> /dev/null >>tmp.pnmo
        sunull ntr=2 nt=$nt dt=$dt >>tmp.pnmo
        j=`expr $j + 1`
    done
    #suxpicker <tmp1 xbox=834 ybox=10 wbox=900 hbox=400 \
	     title="Constant Velocity Stack CMP $picknow" \
	     label1="Time [s]" label2="Velocity [m/s]" \
	     f2=$fv d2=$l d2num=$ld2num n2tic=2 verbose=0 \
             mpicks=pickscvs.$picknow perc=99 cmap=rgb0 2> /dev/null &
   
    #suximage <tmp1 xbox=834 ybox=50 wbox=500 hbox=400 \
	     windowtitle="Constant Velocity Stack CMP $picknow" \
	     title="Constant Velocity Stack CMP $picknow" \
	     label1="Time [s]" label2="Velocity [m/s]" \
	     f2=$fv d2=$l d2num=$ld2num n2tic=2 verbose=0 \
             mpicks=pickscvs.$picknow perc=99 cmap=rgb0 2> /dev/null &

    suxpicker <tmp.pnmo xbox=834 ybox=400 wbox=900 hbox=400 \
	     title="Constant Velocity NMO CMP $picknow" \
	     label1="Time [s]" label2="Velocity [m/s]" \
	     f2=$fv d2=$lpnmo d2num=$ld2num n2tic=2 verbose=0 \
         perc=90  2> /dev/null &		



#------------------------------------------------
# Plotagem NMO e Perfil Velocidade...
#------------------------------------------------
#

#    sunmo <cmp.$picknow par=tmp2 2> /dev/null |
#    suxpicker title="CMP gather after NMO" xbox=10 ybox=10 \
#	     wbox=400 hbox=600 verbose=0 key=offset perc=94 2> /dev/null &
    

    echo "CMP válido? (y/n (y=sim) (n=não))"
    echo "Se responder (n) não será contabilizado no total de CMPs escolhidos " >/dev/tty
    read response
    
rm tmp*
zap xwigb 
zap ximage 
zap xpicker 
zap xgraph


if [ "$response" = 'y' ]; then i=`expr $i + 1` ; fi

echo  "análise:" i=$i

done



