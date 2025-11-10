#! /bin/sh

echo "ANALISE DE VELOCIDADES: Semblance Painel NMO e Painel CVS"
########################################################################
# AGG323-Sismica II
# Profs.: Liliana e Renato
########################################################################

# Pode entrar com nome do arquivo e valores de velocidade pelo comando de linha
#	file vmin dv vmax
# EXEMPLO:
# sh velan3m.sh cdp.data 1300 100 3000

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
    suxpicker <tmp1 xbox=834 ybox=10 wbox=900 hbox=400 \
	     title="Constant Velocity Stack CMP $picknow" \
	     label1="Time [s]" label2="Velocity [m/s]" \
	     f2=$fv d2=$l d2num=$ld2num n2tic=2 verbose=0 \
             mpicks=pickscvs.$picknow perc=99 cmap=rgb0 2> /dev/null &
   
    suximage <tmp1 xbox=834 ybox=50 wbox=500 hbox=400 \
	     windowtitle="Constant Velocity Stack CMP $picknow" \
	     title="Constant Velocity Stack CMP $picknow" \
	     label1="Time [s]" label2="Velocity [m/s]" \
	     f2=$fv d2=$l d2num=$ld2num n2tic=2 verbose=0 \
             mpicks=pickscvs.$picknow perc=99 cmap=rgb0 2> /dev/null &

    suxpicker <tmp.pnmo xbox=834 ybox=400 wbox=900 hbox=400 \
	     title="Constant Velocity NMO CMP $picknow" \
	     label1="Time [s]" label2="Velocity [m/s]" \
	     f2=$fv d2=$lpnmo d2num=$ld2num n2tic=2 verbose=0 \
             mpicks=picksnmo.$picknow perc=90  2> /dev/null &		


#------------------------------------------------
# Plotagem Semblance...
#------------------------------------------------
##    echo "Posicione o cursor sobre o grafico semblance ou"
##    echo "  sobre o painel CVS e digite 's' para definir as velocidades" 
    echo "Posicione o cursor sobre o grafico semblance "
    echo "  e digite 's' para definir as velocidades" 
    echo "  Digite'q' no grafico semblance quando finalizar."
    echo "  Um conjunto corrigido NMO serah plotado..."

    suvelan <cmp.$picknow nv=$nv dv=$dv fv=$fv |
    suximage xbox=10 ybox=10 wbox=400 hbox=600 \
	     windowtitle="Semblance  ('Velocity Spectrum') " \
	     units="semblance" f2=$fv d2=$dv \
	     label1="Time [s]" label2="Velocity [m/s]" \
	     title="Semblance Plot CMP $picknow" cmap=hsv2 \
	     legend=1 units=Semblance verbose=0 gridcolor=black \
	     grid1=solid grid2=solid mpicks=picks.$picknow 2> /dev/null
    
#    sort <picks.$picknow -n |

    mkparfile <picks.$picknow string1=tnmo string2=vnmo >par.$i

#------------------------------------------------
# Plotagem NMO e Perfil Velocidade...
#------------------------------------------------
		
    >tmp2
    echo "cdp=$picknow" >>tmp2
    cat par.$i >>tmp2
    sunmo <cmp.$picknow par=tmp2 2> /dev/null |
    suxpicker title="CMP gather after NMO" xbox=10 ybox=10 \
	     wbox=400 hbox=600 verbose=0 key=offset perc=94 2> /dev/null &
    
        sed <par.$i '
        s/tnmo/xin/
	s/vnmo/yin/ ' >par.uni.$i

    unisam nout=$nt fxout=0.0 dxout=$dt par=par.uni.$i method=linear >teste.unisam

    xgraph <teste.unisam n=$nt nplot=1 d1=$dt f1=0.0 label1="Time [s]" label2="Velocity [m/s]" title="Stacking Velocity Function CMP $picknow" linewidth=0 mark=1 marksize=3 -geometry 350x400+422+10 x2beg=$fv x2end=$vmax & 

# Nao Funciona com os parametros a seguir
# grid1=solid grid2=solid linecolor=3 marksize=1 mark=0  titleColor=red axesColor=blue & 

    echo "Picks OK? (y/n) " >/dev/tty
    read response
    rm tmp*

zap xwigb 
zap ximage 
zap xpicker 
zap xgraph

#    case $response in
#	n*) i=$i echo "Picks removed" ;;
#        *) i=`expr $i + 1` echo "$picknow  $i" >>par.cmp ;;
#    esac

if [ "$response" = 'n' ]; then echo "Picks removed" 
   else echo "$picknow  $i" >>par.cmp ; i=`expr $i + 1` ; fi

echo  i=$i

done


#------------------------------------------------
# Create Velocity Output File...
#------------------------------------------------

mkparfile <par.cmp string1=cdp string2=# >par.0

i=0
while [ $i -le $nrpicks ]
do
	cat par.$i >>$outdata
	i=`expr $i + 1`
done

rm -f cmp.* picks.* tmp* #par.* 

exit

