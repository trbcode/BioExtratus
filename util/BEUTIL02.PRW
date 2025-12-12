#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} GetBcoApi
Recupera a lista de bancos cadastrados para integração via API.
@type function
@version 1.0
@author igor.guimaraes
@since 12/11/2025
@return variant, array com os códigos dos bancos integrados via API
/*/
User Function GetBcoApi()

	Local cTMPSEE  := GetNextAlias()
	Local aBcoApt  := {}

	BeginSql Alias cTMPSEE

		SELECT EE_CODIGO, 
            EE_CODEMP, 
            EE_CONTA, 
            EE_DVCTA, 
            EE_AGENCIA, 
            EE_DVAGE, 
            EE_XXCARTE, 
            EE_XXMENS1, 
            EE_XXTXJUR, 
            EE_XXTXJDI, 
            EE_FAXATU, 
            EE_FAXFIM, 
            EE_DIASREC,
            EE_NUMCTR, 
            EE_CODCART, 
            EE_TIPCART,
            EE_DIASPRT,
            EE_TABELA,
            A6_NOME
            FROM %table:SEE% SEE
            INNER JOIN %table:SA6% SA6 on
                SA6.D_E_L_E_T_ <> '*'
                and A6_FILIAL = EE_FILIAL
                AND EE_CODIGO = A6_COD
                AND EE_AGENCIA = A6_AGENCIA
                AND EE_CONTA = A6_NUMCON
            WHERE SEE.D_E_L_E_T_ <> '*'
            AND SEE.EE_XXINTBC = '1'
            ORDER BY EE_CODIGO, EE_AGENCIA, EE_CONTA
	EndSql

	While (cTMPSEE)->(!Eof())

		aadd(aBcoApt, {;
			alltrim((cTMPSEE)->EE_CODIGO),;
			alltrim((cTMPSEE)->EE_CODEMP),;
			alltrim((cTMPSEE)->EE_AGENCIA),;
			alltrim((cTMPSEE)->EE_DVAGE), ;
			alltrim((cTMPSEE)->EE_CONTA), ;
			alltrim((cTMPSEE)->EE_DVCTA), ;
			alltrim((cTMPSEE)->EE_XXCARTE),;
			alltrim((cTMPSEE)->EE_XXMENS1), ;
			alltrim((cTMPSEE)->EE_XXTXJUR), ;
			alltrim((cTMPSEE)->EE_XXTXJDI), ;
			alltrim((cTMPSEE)->EE_FAXATU), ;
			alltrim((cTMPSEE)->EE_FAXFIM), ;
			alltrim((cTMPSEE)->EE_DIASREC),;
			alltrim((cTMPSEE)->EE_NUMCTR), ;
			alltrim((cTMPSEE)->EE_CODCART), ;
			alltrim((cTMPSEE)->EE_TIPCART),;
			alltrim((cTMPSEE)->EE_DIASPRT),;
			alltrim((cTMPSEE)->EE_TABELA),;
			alltrim((cTMPSEE)->A6_NOME) } )
		(cTMPSEE)->(DbSkip())
	EndDo

	(cTMPSEE)->(DbCloseArea())
Return aBcoApt
