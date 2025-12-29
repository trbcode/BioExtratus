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
User Function BEFINM01()

	Local aArea     := GetArea()
	Local lLogin    := Type("cEmpAnt") != "U"
	Local nX  		:= 0
	Local cDatIni   := ""
	Local cDatFim   := ""
	Local aBancos   := {}
	Local aBcoAPI   := {}
	Local nPOS      := 1
	Local cBanco    := ""
	Local cAgencia  := " "
	Local cConta    := "      "
	Local oBancoBB  as Object
	Local lRet 	    := .F.
	Local dDatabkp  := ctod("")
	Private aParBox := {}
	Private aParRet := {}

	if !lLogin
		RpcSetEnv("01","01","Admin")
	endif

	dDatabkp  := dDataBase

	// Banco Siccob
	cBanco   := "756"
	cAgencia := "4108 "
	cConta   := "8429      "
	cCodClie  := u_getIdClientSicoob(alltrim(cBanco), alltrim(cAgencia), alltrim(cConta)) //"e227419d-ce16-43c0-ac2e-a64cea1bd6d5"

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
	// Fim Banco Siccob

	/********************************************************************************************************************/

	// Banco do Brasil
	SLEEP(5000)

	cBanco	   := "001"
	aBcoAPI    := u_GetBcoApi()
	if !IsBlind() .and. !Empty(MV_PAR01)
		dDataBase  := MV_PAR01
		cDatIni    := STRZERO(DAY(MV_PAR01),2)+"."+STRZERO(MONTH(MV_PAR01),2)+"."+CVALTOCHAR(YEAR(MV_PAR01))
		cDatFim    := cDatIni
	else
		For nX:= 1 to 7
			if datavalida(DATE()-nX) <> DATE()
				cDatIni   := STRZERO(DAY(DATE()-nX),2)+"."+STRZERO(MONTH(DATE()-nX),2)+"."+CVALTOCHAR(YEAR(DATE()-nX))
				cDatFim   := cDatIni
				dDataBase := DATE()-nX
				EXIT
			EndIf
		Next nX
	endif

	for nX := 1 to Len(aBcoAPI)
		if aBcoAPI[nX][1] == cBanco
			oBancoBB := JsonObject():New()
			cAgencia := Padr(aBcoAPI[nX][3], TamSX3("EE_AGENCIA")[1])
			cConta   := Padr(aBcoAPI[nX][5], TamSX3("EE_CONTA")[1])
			U_IntegBB(@oBancoBB,cBanco, cAgencia, cConta)
			lRet := oBancoBB:recebimentoboletos(cDatIni, cDatFim,"B")
			IF lRet .and. !empty(oBancoBB:aRecebidosSucesso)
				// Enviar email de confirmação
				//cHtml := "<h3>Confirmação de Baixas - Banco do Brasil</h3>"
				//cHtml += "<p>Prezado(a),</p>"
				//cHtml += "<p>O processamento de baixas dos boletos do Banco do Brasil foi concluído com sucesso.</p>"
				//cHtml += "<ul>"
				//oSendMail := sendMail():New()
				//oSendMail:Send("Confirmação de Baixas - Banco do Brasil", 'trbcode@gmail.com','iglalguimaraes@gmail.com', cHtml )
			ENDIF
			freeObj(oBancoBB)
			sleep(5000)
		endif
	Next nX
	IF !IsBlind()
		cMsg := '<font color="#269426ff" size="4">Processamento de baixas finalizado com sucesso!</font>' + '<br>'
		FWAlertSuccess(cMsg , "Processamento Baixas Automática - BEFINM01")
	ENDIF
	dDataBase  := dDatabkp
	// Fim Banco do Brasil
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
