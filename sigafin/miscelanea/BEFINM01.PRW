/*//#########################################################################################
Projeto : project
Modulo  : module
Fonte   : BEFINM02
Objetivo: cHAMA ROTINA
*///#########################################################################################

#INCLUDE 'TOTVS.CH'

/*/{Protheus.doc} BEFINM01
Executa baixas dos títulos  Sicoob
@type user function
@author Igor Guimarães
@since 15/08/2024
@version version
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function BEFINM01(cTipo)

	Local aArea     := GetArea()
	Local lLogin    := Type("cEmpAnt") != "U"
	Local nX  		  := 0
	Local cDatIni   := ""
	Local cDatFim   := ""
	Local aBancos   := {}
	Local nPOS      := 1
	Local cBanco   := ""
	Local cAgencia := " "
	Local cConta   := "      "
	Local oBancoBB as Object
	Local lRet 		:= .F.
	Local dDatabkp    := ctod("")
	Private aParBox := {}
	Private aParRet := {}

	if !lLogin
		RpcSetEnv("01","01","Admin")
	endif

	if alltrim(cTipo) ==''
		cTipo := 'BIO'
	endif

	IF cTipo == 'BIO'
		cBanco   := "756"
		cAgencia := "4108 "
		cConta   := "8429      "
		//cCodClie  := "e24ab947-b2b6-4c55-86fb-2662a014a63b"
		cCodClie  := "e227419d-ce16-43c0-ac2e-a64cea1bd6d5"
	ELSEIF cTipo == 'FUP'
		cBanco   := GetMV("MV_XXFUPBA")
		cAgencia := Padr(GetMV("MV_XXFUPAG"), TamSX3("EE_AGENCIA")[1])
		cConta   := Padr(GetMV("MV_XXFUPCC"), TamSX3("EE_CONTA"	 )[1])
		cCodClie  := "28477a68-ed9d-43a6-8e97-9a161917e7ca"

		// FUPROM - Chikas
	ELSEIF cTipo == 'FUPCHK'
		cBanco   := GetMV("MV_XXFCHBA")
		cAgencia := Padr(GetMV("MV_XXFCHAG"), TamSX3("EE_AGENCIA")[1])
		cConta   := Padr(GetMV("MV_XXFCHCC"), TamSX3("EE_CONTA")[1])
		cCodClie  := "b7e6001d-1131-4687-a8b5-c7262f146f89"
	ELSEIF cTipo == 'BB'
		cBanco	 := "001"
		cAgencia := Padr("3394", TamSX3("EE_AGENCIA")[1])
		cConta   := Padr("105002", TamSX3("EE_CONTA")[1])
		dDatabkp  := dDataBase
		For nX:= 1 to 7
			if datavalida(DATE()-nX) <> DATE()
				cDatIni := STRZERO(DAY(DATE()-nX),2)+"."+STRZERO(MONTH(DATE()-nX),2)+"."+CVALTOCHAR(YEAR(DATE()-nX))
				cDatFim := cDatIni
				dDataBase := DATE()-nX
				EXIT
			EndIf
		Next nX

		U_IntegBB(@oBancoBB,cBanco, cAgencia, cConta)
		lRet := oBancoBB:recebimentoboletos(cDatIni, cDatFim,"B")
		IF lRet .and. !empty(oBancoBB:aRecebidosSucesso)
			FwAlertSuccess("Processamento de baixas do Banco do Brasil concluído com sucesso!", "BEFINM01 - BB")
		ENDIF
		dDataBase  := dDatabkp

	ENDIF

	if cTipo <> 'BB'
		AADD(aBancos, { "756","SICOOB","756.bmp","756-0",,,,,,,,"",,,,})    //Sicoob

		//Buscando parâmetros de banco  e atualizando o array de bancos
		dbSelectArea("SEE")
		dbSetOrder(1)   // EE_FILIAL  	+ EE_CODIGO + EE_AGENCIA + EE_CONTA +   EE_SUBCTA
		dbSeek( XFILIAL("SEE")	+ cBanco    + cAgencia   + cConta   +  '001',     .T.)

		aBancos[nPOS][5]	  := alltrim(SEE->EE_DVAGE)
		aBancos[nPOS][6]    :=  alltrim(SEE->EE_DVCTA)
		aBancos[nPOS][7]    :=  alltrim(SEE->EE_CONTA) + alltrim(SEE->EE_DVCTA)
		aBancos[nPOS][8]    :=  alltrim(SEE->EE_CODEMP)
		aBancos[nPOS][9]    :=  cConta
		aBancos[nPOS][10]   :=  cAgencia
		aBancos[nPOS][12]   :=  alltrim(SEE->EE_XXCARTE)
		aBancos[nPOS][13]   :=  alltrim(SEE->EE_FAXFIM)
		aBancos[nPOS][15]   :=  SEE->EE_XXTXJUR
		aBancos[nPOS][16]   :=  SEE->EE_XXTXJDI

		if !IsBlind()
			if !ValidPerg()
				Return()
			endif
			dDtaBx  := MV_PAR01
			cDatIni := dtos(dDtaBx)
			cDatFim := cDatIni
		else
			for nX:= 1 to 7
				if datavalida(DATE()-nX) <> DATE()
					cDatIni := CVALTOCHAR(YEAR(DATE()-nX))+STRZERO(MONTH(DATE()-nX),2)+STRZERO(DAY(DATE()-nX),2)
					dDtaBx := DATE()-nX
					exit
				endif
			Next nX
			cDatFim := cDatIni
		endif

		Processa({|| U_BEWS0002("BAI",,,aBancos,nPOS,,,,dDtaBx,cDatIni,cDatFim, cCodClie)}, "Baixando...")
	EndIf
	RestArea(aArea)
return()


/*/{Protheus.doc} ValidPerg
description
@type function
@version  
@author Igor Guimarães
@since 8/23/2024
@return variant, return_description
/*/
Static Function ValidPerg()

	Local lRet      := .F.
	Local dDataDe   := Date()-1
	Local nX

	for nX:= 1 to 7
		if datavalida(DATE()-nX) <> DATE()
			dDataDe := DATE()-nX
			exit
		endif
	Next nX
	//Adiciona os parametros para a pergunta

	AADD( aParBox , { 1 , "Dt Recebimento"  , dDataDe,  "", ".T.", "", ".T.", 80,  .F.})

	lRet := ParamBox(aParBox ,"Boleto Sicoob",aParRet)
Return lRet
