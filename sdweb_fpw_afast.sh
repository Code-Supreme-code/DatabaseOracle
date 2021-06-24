#!/bin/sh -x
#!/bin/ksh
# SCRIPT DE CARGA DIARIA - SDWEB FPW AFASTAMENTOS
# FABRICIO DE PAULA - META 24/09/2019
#
clear
set -vx
ORACLE_HOME=/u01/app/oracle/product/11.2.0/dbhome_1

dir_log=/ligfs03/sdweb/prod/log                       # diretorio log do script
dir_pl=/ligfs03/sdweb/prod/plsql                # diretorio dos arquivos plsql
dir_s=/ligfs03/sdweb/prod/script         # diretorio do script (shell)
dir_in=/ligfs03/sdweb/prod/arq_in                          # diretorio de entrada para arquivos
dir_out=/ligfs03/sdweb/prod/arq_out             # diretorio de saida para arquivos  

ORACLE_SID=PRDSDP
NLS_LANG=AMERICAN_AMERICA.WE8DEC
export NLS_LANG
export ORACLE_HOME ORACLE_SID
LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/dt/lib:/usr/users/oracled/light_chr
export LD_LIBRARY_PATH

#
DATA=`date +%Y%m%d`
HORA=`date +%H%M%S`
data_log=`date '+%Y%m%d'`

acesso=sdweb_batch/batch_sdweb

#Valida se ambiente oracle está funcional
testora=`ps -ef | grep $ORACLE_SID | wc -l`
if [ $testora -le 4 ]
then 
  echo " **** O ORACLE nao esta ativo. Verifique. **** "|pg
  echo " script abortado ***  O ORACLE nao esta ativo. Verifique. ***" >> $dir_log/sdweb_fpw_afast$data_log.log
  echo " script encerrado" >> $dir_log/sdweb_fpw_afast$data_log.log
  exit 1
fi

#Processamento de AFASTAMENTOS

#processamento para carga na tabela de afastamentos
$ORACLE_HOME/bin/sqlplus $acesso@$ORACLE_SID @$dir_pl/sdweb_fpw_afast.sql

if [ $? -gt 0 ] 
then
   echo " Erro na execucao do sdweb_fpw_afast.sql "
   exit 2
fi


exit

