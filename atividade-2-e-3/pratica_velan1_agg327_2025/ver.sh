#! /bin/sh

suximage <arq1.su perc=90 wbox=1200 hbox=420 ybox=0 windowtitle=arq1 &

suximage <arq2.su perc=90 wbox=1200 hbox=420 ybox=430 windowtitle=arq2 &

suchart <arq1.su key1=fldr key2=cdp | xgraph n=60 nplot=200 marksize=5 mark=0 linewidth=0 x1beg=0 x2beg=0 label1=ep label2=cdp &



# Para analise de velocidades: utilizar o script velan3m.sh


# Para a correcao de NMO

#cmp_inputfile=arq2.su
#sunmo par=vpick.data <$cmp_inputfile >nmo.su
#suximage <nmo.su wbox=1200 hbox=420 perc=90 title="corrigido de NMO" &


# Empilhamento
# sustack <nmo.su  >stacked.su
# suximage <stacked.su title="empilhado" &
