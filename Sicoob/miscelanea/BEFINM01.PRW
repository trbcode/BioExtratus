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
	Local cBcoCNAB  := ""
	Local cAgeCNAB  := ""
	Local cCtaCNAB  :=  ""
	Local nPOS      := 1
	Private aParBox := {}
	Private aParRet := {}

	if !lLogin
		RpcSetEnv("01","01","Admin")
	endif

	cBcoCNAB  := PADR(AllTrim( SuperGETMV( "BE_BCSICOB",, "756" )),TAMSX3("A6_COD")[1])
	cAgeCNAB  := PADR(AllTrim( SuperGETMV( "BE_AGSICOB",, "4108" )),TAMSX3("A6_AGENCIA")[1])
	cCtaCNAB  := PADR(AllTrim( SuperGETMV( "BE_CCSICOB",, "8429" )),TAMSX3("A6_NUMCON")[1])

	AADD(aBancos, { "756","SICOOB","756.bmp","756-0",,,,,,,,"",,,,})    //Sicoob

	//Buscando parâmetros de banco  e atualizando o array de bancos
	dbSelectArea("SEE")
	dbSetOrder(1)   // EE_FILIAL  	+ EE_CODIGO + EE_AGENCIA + EE_CONTA +   EE_SUBCTA
	dbSeek( XFILIAL("SEE")	+ cBcoCNAB    + cAgeCNAB   + cCtaCNAB   +  '001',     .T.)

	aBancos[nPOS][5]	 :=  alltrim(SEE->EE_DVAGE)
	aBancos[nPOS][6]    :=  alltrim(SEE->EE_DVCTA)
	aBancos[nPOS][7]    :=  alltrim(cCtaCNAB) + alltrim(SEE->EE_DVCTA)
	aBancos[nPOS][8]    :=  alltrim(SEE->EE_CODEMP)
	aBancos[nPOS][9]    :=  cCtaCNAB
	aBancos[nPOS][10]   :=  cAgeCNAB
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

	Processa({|| U_BEWS0002("BAI",,,aBancos,nPOS,,,,dDtaBx,cDatIni,cDatFim)}, "Baixando...")
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
	Local dDataDe   := FirstDate(Date())

	//Adiciona os parametros para a pergunta

	AADD( aParBox , { 1 , "Dt Recebimento"  , dDataDe,  "", ".T.", "", ".T.", 80,  .F.})

	lRet := ParamBox(aParBox ,"Boleto Sicoob",aParRet)
Return lRet
