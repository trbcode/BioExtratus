#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} GetBcoApi
Recupera a lista de bancos cadastrados para integração via API.
@type function
@version 1.0
@author igor.guimaraes
@since 12/11/2025
@param   cCodBco, string, Código do banco para filtro (opcional)
@param   cAgencia, string, Agência do banco para filtro (opcional)
@param   cConta, string, Conta do banco para filtro (opcional)
@return variant, Array com os bancos cadastrados para integração via API.
/*/
User Function GetBcoApi(cCodBco, cAgencia, cConta)

	Local cTMPSEE  := GetNextAlias()
	Local aBcoApt  := {}
	Local cFiltro := ""

	if !Empty(cCodBco)
		cFiltro += " AND SEE.EE_CODIGO = '" + AllTrim(cCodBco) + "' "
	EndIf
	if !Empty(cAgencia)
		cFiltro += " AND SEE.EE_AGENCIA = '" + AllTrim(cAgencia) + "' "
	EndIf
	if !Empty(cConta)
		cFiltro += " AND SEE.EE_CONTA = '" + AllTrim(cConta) + "' "
	EndIf

	cFiltro := "% " + cFiltro + " %"

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
			%Exp:cFiltro%
            ORDER BY EE_CODIGO, EE_AGENCIA, EE_CONTA
	EndSql

	While (cTMPSEE)->(!Eof())

		aadd(aBcoApt, {;
			alltrim((cTMPSEE)->EE_CODIGO), ; //1 - Código do Banco
		alltrim((cTMPSEE)->EE_CODEMP), ; //2 - Código Convenio
		alltrim((cTMPSEE)->EE_AGENCIA),; //3 - Agência
		alltrim((cTMPSEE)->EE_DVAGE),  ; //4 - DV Agência
		alltrim((cTMPSEE)->EE_CONTA),  ; //5 - Conta
		alltrim((cTMPSEE)->EE_DVCTA),  ; //6 - DV Conta
		alltrim((cTMPSEE)->EE_XXCARTE),; //7 - Carteira
		alltrim((cTMPSEE)->EE_XXMENS1),; //8 - Mensagem 1
		alltrim((cTMPSEE)->EE_XXTXJUR),; //9 - Taxa de Juros
		alltrim((cTMPSEE)->EE_XXTXJDI),; //10 - Taxa de Juros por Dia
		alltrim((cTMPSEE)->EE_FAXATU), ; //11 - Faixa Atual
		alltrim((cTMPSEE)->EE_FAXFIM), ; //12 - Faixa Final
		alltrim((cTMPSEE)->EE_DIASREC),; //13 - Dias para Recibo
		alltrim((cTMPSEE)->EE_NUMCTR), ; //14 - Número do Contrato
		alltrim((cTMPSEE)->EE_CODCART),; //15 - Código da Carteira
		alltrim((cTMPSEE)->EE_TIPCART),; //16 - Tipo da Carteira
		alltrim((cTMPSEE)->EE_DIASPRT),; //17 - Dias para Protesto
		alltrim((cTMPSEE)->EE_TABELA), ; //18 - Tabela
		alltrim((cTMPSEE)->A6_NOME)    ; //19 - Nome do Banco
		} )
		(cTMPSEE)->(DbSkip())
	EndDo

	(cTMPSEE)->(DbCloseArea())
Return aBcoApt
