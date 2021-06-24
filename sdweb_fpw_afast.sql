DECLARE
-- EXPORTAR ARQUIVO DE AFASTAMENTO

/*
**********************************************************************************************************************
HISTÓRICO DE ATUALIZAÇÕES
Analista  Sistemas                       Analista Negocios    Data           comentários
Fabrício da Silva de Paula             Ana Dacri            28/09/2019       1a versão
Fabrício da Silva de Paula             Ana Dacri            10/10/2019       > retirar pontos do número de classe
                                                                             > retirar os DRs dos nomes do emitentes
                                                                             > pegar a sigla do conselho pelo campo TP_PROFISSIONAL
                                                                             > O indicador de mesmo motivo de afastamento é Sim caso
                                                                               o campo CD_CLASSIF seja 4102 e o tipo de afastamento
                                                                               seja 2, 5, 11 ou 19
Fabrício da Silva de Paula             Ana Dacri            21/10/2019       > quando não vier informação de profissional,
                                                                               informar como Médico
                                                                             > alinhar o código CID à esquerda (campo #18)
                                                                             > acertar o tamanho do campo #23 para 256 posições
Fabrício da Silva de Paula             Ana Dacri            22/10/2019       > acertar ocorrência para "01002"
                                                                             > campo #9. Se sexo for M, deixar em branco.
                                                                                                                                                                                                 Senão e tipo de afastamento for 12, informar "S"
Fabrício da Silva de Paula             Ana Dacri            23/10/2019       > tirar acentos e caracteres especiais do nome do médico
                                                                             > inscrição de órgao emitente: retirar caracteres
                                                                               não numéricos
                                                                             > campos em maiúsculo
                                                                             > selecionar registros com licença maior que
                                                                               15 dias apenas (NR_DIAS_AFAST <=15 e
                                                                               NR_DIAS_AUXILIO_DOENCA  = 0)
                                                                             > preencher com brancos o campo número do documento,
                                                                               que é parte da Descrição da Vara
                                                                             > preencher o campo #6 com o NR_DIAS_AFAST
                                                                             > preencher a ultima parte da descrição da vara
                                                                               com o NR_DIAS_AFAST
                                                                             > buscar o tipo de afastamento (camp #13) na tabela
                                                                               auxiliar
Fabrício da Silva de Paula             Ana Dacri            24/10/2019       > passar zeros na última parte do campo Descr.da Vara
                                                                             > informar o código CID apenas quando Cod.RAIS for 2
                                                                               ou 11 e situação for 59
Fabrício da Silva de Paula             Ana Dacri            07/11/2019       > acertar filtro de data para buscar apenas data corrente
Fabrício da Silva de Paula             Ana Dacri            29/11/2019       > retirar DRª do nome do emitente
                                                                             > diminuido o tamanho do ultimo campo do registro de saida
   de 256 para 255
Fabrício da Silva de Paula             Ana Dacri            29/01/2020       passar o NR_DIAS_AFAST (6o campo) também na última parte
                                                                             do campo Descrição de Vara
**********************************************************************************************************************
*/


CURSOR c_afast IS
SELECT

  SUBSTR(A.COD_EMPRESA,-3) AS COD_EMPRESA,
  A.MATRICULA,
  A.DTINIAFAST,
  A.DT_FIM_AFAST,

  --to_char(to_date(substr(A.DT_FIM_AFAST,7,2) || '/' || substr(A.DT_FIM_AFAST,5,2) || '/' || substr(A.DT_FIM_AFAST,1,4)) + 1, 'YYYYMMDD') AS DT_FIM_MAIS_UM,
  --substr(A.DT_FIM_AFAST,7,2) || substr(A.DT_FIM_AFAST,5,2) || substr(A.DT_FIM_AFAST,1,4) AS DT_FIM_MAIS_UM,
  
  A.NR_DIAS_AFAST,
  A.SEXO,
  A.COD_TIPO_AFAST,
  SUBSTR(A.COD_MOTIVO_AFAST,1,3) AS COD_MOTIVO_AFAST,
  NVL(A.IND_DOENCA,'N') AS IND_DOENCA,
  '0' AS DTAUXILIAR,
  A.COD_SITUACAO,
  '' AS CNPJ_CESSAO,
  '' AS CNPJ_SINDICATO,
  A.CID,
  A.COD_CID,
  CASE WHEN A.OBSERVACAO IS NULL THEN ' ' ELSE A.OBSERVACAO END AS OBSERVACAO,
  
  TRANSLATE(
    TRIM( REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(UPPER(A.NOME_MEDICO_EMIT), 'DR.',''),'DR ',''),'DRA.',''),'DRA ',''),'DRª ','') ),
    'ŠŽšžŸÁÇÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕËÜÏÖÑÝåáçéíóúàèìòùâêîôûãõëüïöñýÿ',
    'SZszYACEIOUAEIOUAEIOUAOEUIONYaaceiouaeiouaeiouaoeuionyy' ) AS NOM_EMITENTE,

  A.TIPO_ORGAO_CLASSE AS NOM_INSCR_ORGAO,
  CASE WHEN UPPER(NVL(TP_PROFISSIONAL,' ')) LIKE 'MÉDIC%' THEN
    'CRM'
  ELSE
    CASE WHEN UPPER(NVL(TP_PROFISSIONAL,' ')) = 'DENTISTA' THEN
      'CRO'
    ELSE
      ''
    END
  END AS ORGAO_CLASSE_EMIT,  --A.ORGAO_CLASSE_EMIT,
  
  REPLACE(REPLACE(
      REPLACE(CASE WHEN SUBSTR(A.ORGAO_CLASSE_EMIT,1,1) IN ('0','1','2','3','4','5','6','7','8','9') THEN
        A.ORGAO_CLASSE_EMIT
      ELSE
        CASE WHEN SUBSTR(A.ORGAO_CLASSE_EMIT,5,1) IN ('0','1','2','3','4','5','6','7','8','9') THEN
          SUBSTR(A.ORGAO_CLASSE_EMIT,5,LENGTH(A.ORGAO_CLASSE_EMIT)-4)
        ELSE
          '0'
        END
      END, '.', ''), '-', ''), '_', '')
  AS NUM_CLASSE,
  
  --DECODE(SUBSTR(A.ORGAO_CLASSE_EMIT,1,3), 'CRM', '1', 'CRO', '2', 'RMS', '3', '0') AS COD_TIPO_ORGAO,
  CASE WHEN UPPER(NVL(TP_PROFISSIONAL,' ')) LIKE 'MÉDIC%' THEN
    '1'
  ELSE
    CASE WHEN UPPER(NVL(TP_PROFISSIONAL,' ')) = 'DENTISTA' THEN
      '2'
    ELSE
      '1'--'0'
    END
  END AS COD_TIPO_ORGAO,
  
  NVL(A.UF_ORGAO_CLASSE,'RJ') AS COD_UF_ORGAO,
  '0' AS NRPROC,
  --' ' AS IND_AFAST_IGUAL_MOTIVO,
  AR.COD_MOTIVO AS COD_MOTIVO_REF,
  --CASE WHEN COD_FORMA_ACID IS NULL THEN '-1' ELSE COD_FORMA_ACID END AS COD_FORMA_ACID,
  A.COD_FORMA_ACID,
  AR.COD_SITUACAO AS COD_SITUACAO_REF,
  A.CD_CLASSIF,
  AR.COD_TIPO_AFASTAMENTO AS COD_TIPO_AFASTAMENTO_REF

FROM SDPLUS.VW_AFASTAMENTO A
  INNER JOIN
  TAFASTAMENTO_REF AR
  ON TO_CHAR(AR.COD_SDWEB) = A.COD_TIPO_AFAST
WHERE 1=1

  AND TRUNC(NVL(A.DATA_DIGITACAO, to_date('01/01/1910', 'DD/MM/YYYY'))) = TRUNC(SYSDATE)
  --AND TRUNC(NVL(A.DATA_DIGITACAO, to_date('01/01/1910', 'DD/MM/YYYY'))) >= TRUNC(SYSDATE-10)

  AND (CASE WHEN (A.NR_DIAS_AUXILIO_DOENCA > 15) THEN 'S' ELSE 'N' END) = AR.IND_PERIODO_MAIOR_15_DIAS

  -- licença maior que 15 dias
  AND (A.NR_DIAS_AFAST <= 15 AND A.NR_DIAS_AUXILIO_DOENCA = 0)

  AND AR.COD_MOTIVO IN ('1', '3')
ORDER BY
  SUBSTR(A.COD_EMPRESA,-3),
  A.MATRICULA,
  A.DTINIAFAST
;


   v_dir_out      VARCHAR2(500);
   v_arq_out      VARCHAR2(500);
   p_arq          UTL_FILE.FILE_TYPE;

   sIndicAbono    VARCHAR2(1);
   iQtdDiasAbono  PLS_INTEGER := 0;
   sParcelas      VARCHAR2(3) := '0';

   sRegistro      VARCHAR2(2000);

   v_dir_log      VARCHAR2(500);
   v_arq_log      VARCHAR2(500);
   p_log          UTL_FILE.FILE_TYPE;
   v_erro         VARCHAR2(1000);
   iQtdErro       PLS_INTEGER := 0;
   iQtdRegistro   PLS_INTEGER := 0;
   iQtdDiasFerias PLS_INTEGER := 0;
   sCodLotacaoAnt VARCHAR2(14) := '';
   sCodCargoAnt   VARCHAR2(8) := '';
   sDescrVara     VARCHAR2(40) := '';
   sIndAfastMesmoMotivo VARCHAR2(1) := 'N';
   sCodCID VARCHAR2(10) := '';

   sDiaFimMaisUm VARCHAR2(8) := '';

   sSeparadorRegistro VARCHAR2(1) := '';

   sDebug varchar2(2000) := '';
   
BEGIN
  execute immediate 'alter session set NLS_DATE_FORMAT = "DD/MM/YYYY"';

  v_dir_out  := 'SDWEB_DIR_OUT';
  
  v_arq_out    := 'sdweb_fpw_afast'            ||'_'|| 
                  TO_CHAR(SYSDATE, 'YYYYMMDD')     ||'_'|| 
                  TO_CHAR(SYSDATE, 'HH24MISS')       || 
                  '.txt';
  p_arq        := UTL_FILE.FOPEN(v_dir_out, v_arq_out, 'w', 2000);

  v_dir_log  := 'SDWEB_DIR_LOG';
  v_arq_log    := 'sdweb_fpw_afast'            ||'_'|| 
                  TO_CHAR(SYSDATE, 'YYYYMMDD')     ||'_'|| 
                  TO_CHAR(SYSDATE, 'HH24MISS')       || 
                  '.log';
  p_log        := UTL_FILE.FOPEN(v_dir_log, v_arq_log, 'W');


  v_erro := 'Inicio do Processamento '||TO_CHAR(SYSDATE,'DD/MM/YYYY hh24:mi:ss');
  UTL_FILE.PUT_LINE(p_log, v_erro);
  v_erro := '********** SDWEB FPW - AFASTAMENTO **********';
  UTL_FILE.PUT_LINE(p_log, v_erro);
  v_erro := '------------------------------------------------------------------------------------------------------------------';
  UTL_FILE.PUT_LINE(p_log, v_erro);

FOR reg_afast IN c_afast LOOP

   if ((reg_afast.SEXO='F') and (reg_afast.COD_TIPO_AFAST=12)) then
      sIndicAbono := 'S';
   else
      sIndicAbono := ' ';
   END IF;
   

   iQtdDiasAbono := 0;
   --... if... motivo_afast in (24, 14) ... 1, 2, 3 ???


   --...sParcelas = '';

   --...iQtdDiasFerias = 0;
      

/*
   if [(reg_afast.COD_MOTIVO_AFAST=14)] then
      sCodLotacaoAnt = reg_afast.CNPJ_CESSAO;
   elseif [(reg_afast.CODMOTAFAST=24)] then
      sCodLotacaoAnt = reg_afast.CNPJ_SINDICATO;
*/
   

   sCodCargoAnt := '';
   if ((reg_afast.COD_MOTIVO_REF=1) or (reg_afast.COD_MOTIVO_REF=3)) then
--   if ( reg_afast.COD_FORMA_ACID IN ('1301', '1401', '1101', '1201', '2302', '2402', '2102', '2202') ) then
      
      if (reg_afast.COD_FORMA_ACID IS NULL) then
        sCodCargoAnt := '3';
      else
        sCodCargoAnt := reg_afast.COD_FORMA_ACID;
       end if;

   end if;



   if ((reg_afast.COD_TIPO_AFASTAMENTO_REF=2) or (reg_afast.COD_TIPO_AFASTAMENTO_REF=5) or
       (reg_afast.COD_TIPO_AFASTAMENTO_REF=11) or (reg_afast.COD_TIPO_AFASTAMENTO_REF=19)) THEN
      if (reg_afast.CD_CLASSIF='4102') then
          sIndAfastMesmoMotivo := 'S';
      end if;
   end if;


   sCodCID := ' ';
   if (
       ((reg_afast.COD_TIPO_AFASTAMENTO_REF = '2') or (reg_afast.COD_TIPO_AFASTAMENTO_REF = '11')) and 
       (reg_afast.COD_SITUACAO_REF = '59')
       ) then
     sCodCID := reg_afast.COD_CID;
   end if;


/*
    sDescrVara := reg_afast.COD_TIPO_ORGAO || '|' ||
                 reg_afast.COD_UF_ORGAO || '|' ||
                 '0' || '|' || --... preciso saber ORIGEM DA ALTERAÇÃO
                 --LPAD(reg_afast.NRPROC, 20, '0') || '|' ||
                 LPAD(' ', 20, ' ') || '|' ||
                 sIndAfastMesmoMotivo || '|' ||
                 LPAD('0', 4, '0');
*/
    sDescrVara := reg_afast.COD_TIPO_ORGAO || '|' ||
                 reg_afast.COD_UF_ORGAO || '|' ||
                 '0' || '|' || --... preciso saber ORIGEM DA ALTERAÇÃO
                 --LPAD(reg_afast.NRPROC, 20, '0') || '|' ||
                 LPAD(' ', 20, ' ') || '|' ||
                 sIndAfastMesmoMotivo || '|' ||
                 LPAD(reg_afast.NR_DIAS_AFAST, 4, '0')|| '|' ||'0'|| '|';


   -- buscar a data fim e somar mais um dia, e depois formatar
   select to_char(to_date(
            substr(reg_afast.DT_FIM_AFAST, 7, 2) || '/' ||
            substr(reg_afast.DT_FIM_AFAST, 5, 2) || '/' ||
            substr(reg_afast.DT_FIM_AFAST, 1, 4))+1, 'YYYYMMDD')
       into sDiaFimMaisUm from dual;
/*
select
    'sysdate='||to_char(sysdate)||', ' ||
    '('||reg_afast.DT_FIM_AFAST||')' ||
            substr(reg_afast.DT_FIM_AFAST, 7, 2) || '/' ||
            substr(reg_afast.DT_FIM_AFAST, 5, 2) || '/' ||
            substr(reg_afast.DT_FIM_AFAST, 1, 4)
       into sDebug
from dual;
sDebug := 'debug... >' || sDebug || '<';
*/



 
   -- montar a linha a ser exportada
   sRegistro := LPAD(reg_afast.COD_EMPRESA, 3, '0') || sSeparadorRegistro ||
               LPAD(reg_afast.MATRICULA, 9, '0') || sSeparadorRegistro ||
               '01002' || sSeparadorRegistro ||
               TO_CHAR(reg_afast.DTINIAFAST) || sSeparadorRegistro ||
               sDiaFimMaisUm || sSeparadorRegistro ||
               LPAD(reg_afast.NR_DIAS_AFAST, 5, '0') || sSeparadorRegistro ||
               LPAD(reg_afast.DTAUXILIAR, 9, '0') || sSeparadorRegistro ||
               reg_afast.IND_DOENCA || sSeparadorRegistro ||
               sIndicAbono || sSeparadorRegistro ||
               LPAD(TO_CHAR(iQtdDiasAbono), 5, '0') || sSeparadorRegistro ||     -- campo #10
               LPAD(sParcelas, 3, '0') || sSeparadorRegistro ||
               LPAD('0', 8, '0') || sSeparadorRegistro ||
               LPAD(reg_afast.COD_TIPO_AFASTAMENTO_REF, 2, '0') || sSeparadorRegistro ||
               LPAD(reg_afast.COD_SITUACAO_REF, 3, '0') || sSeparadorRegistro ||   --------------#14
               LPAD(reg_afast.COD_MOTIVO_REF, 2, '0') || sSeparadorRegistro ||
               LPAD('0', 14, '0') || sSeparadorRegistro ||
               LPAD(sCodCargoAnt, 8, '0') || sSeparadorRegistro ||            --------- #17
               RPAD(sCodCID, 10, ' ') || sSeparadorRegistro ||
               RPAD(reg_afast.OBSERVACAO, 120, ' ') || sSeparadorRegistro ||
               RPAD(reg_afast.NOM_EMITENTE||' ', 250, ' ') || sSeparadorRegistro ||
               RPAD(reg_afast.NUM_CLASSE, 250, ' ') || sSeparadorRegistro ||
               RPAD(sDescrVara, 40, ' ') || sSeparadorRegistro ||
               LPAD(' ', 256, ' ');



   -- TUDO MAIUSCULO
   SELECT UPPER(sRegistro) into sRegistro from dual;



   -- exportar linha
   iQtdRegistro := iQtdRegistro + 1;
   UTL_FILE.PUT_LINE(p_arq, sRegistro);





/*
  EXCEPTION
  WHEN OTHERS THEN

            iQtdErro := iQtdErro + 1;
            v_erro := 'ERRO AO GRAVAR ARQUIVO: '||' '||
                      SQLCODE     || ' '||
                      SUBSTR(SQLERRM, 1, 100); 
                      
                      UTL_FILE.PUT_LINE(p_log, v_erro);                   
*/
   
END LOOP;

   v_erro := '------------------------------------------------------------------------------------------------------------------';
   UTL_FILE.PUT_LINE(p_log, v_erro);
   v_erro :='Erro(s) na exportação: ' || NVL(TO_CHAR(iQtdErro),0);
   UTL_FILE.PUT_LINE(p_log, v_erro);
   v_erro :='Total de linhas exportadas: ' || NVL(TO_CHAR(iQtdRegistro),0);
   UTL_FILE.PUT_LINE(p_log, v_erro);
   v_erro := 'Fim do Processamento '|| TO_CHAR(SYSDATE,'DD/MM/YYYY hh24:mi:ss');
   UTL_FILE.PUT_LINE(p_log, v_erro);
   v_erro := '------------------------------------------------------------------------------------------------------------------';
   UTL_FILE.PUT_LINE(p_log, v_erro);
 
   UTL_FILE.FCLOSE(p_log);  
   UTL_FILE.FCLOSE(p_arq);
  
/*
EXCEPTION

  WHEN UTL_FILE.INVALID_PATH THEN
    DBMS_OUTPUT.PUT_LINE('Caminho inválido para gravação do arquivo');
    UTL_FILE.FCLOSE(p_log);
    
  WHEN UTL_FILE.READ_ERROR THEN
    DBMS_OUTPUT.PUT_LINE('Erro durante a leitura.');
    UTL_FILE.FCLOSE(p_log);
   
  WHEN UTL_FILE.WRITE_ERROR THEN
    DBMS_OUTPUT.PUT_LINE('Erro durante a escrita.');
    UTL_FILE.FCLOSE(p_log);

  
  WHEN UTL_FILE.ACCESS_DENIED THEN
    DBMS_OUTPUT.PUT_LINE('Acesso ao arquivo negado - Consultar privilégios.');
    UTL_FILE.FCLOSE(p_log);

  
  WHEN UTL_FILE.FILE_OPEN THEN
    DBMS_OUTPUT.PUT_LINE('Arquivo já esta aberto para processamento.');
    UTL_FILE.FCLOSE(p_log);
    
  
  WHEN UTL_FILE.INVALID_MAXLINESIZE THEN
    DBMS_OUTPUT.PUT_LINE('Limite de linha excedeu os 32K - Consultar DBA.');
    UTL_FILE.FCLOSE(p_log);
    
  
  WHEN UTL_FILE.INTERNAL_ERROR THEN
    DBMS_OUTPUT.PUT_LINE('Erro interno do Oracle.');
    UTL_FILE.FCLOSE(p_log);
   
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erro não tratado.Consultar Analista Responsável ' ||
                         TRANSLATE(SUBSTR(SQLERRM, 1, 100), '()', '  '));
    UTL_FILE.FCLOSE(p_log);
*/
    
END;

/
SPOOL OFF
EXIT;
