/*//#########################################################################################
Projeto : project
Modulo  : module
Fonte   : BEFINM02
Objetivo: cHAMA ROTINA
*///#########################################################################################

#INCLUDE 'TOTVS.CH'

/*/{Protheus.doc} BEFINM02
Executa parâmetros para impressão Boleto Sicoob
@type user function
@author Igor Guimarães
@since 15/08/2024
@version version
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function BEFINM02()
	Local lLogin    := Type("cEmpAnt") != "U"
	Local cCodiC    := ""
	Local cLojaC    := ""
	Private aParBox := {}
	Private aParRet := {}

	If !lLogin
		RpcSetEnv("01","01","Admin")
	EndIf

	If !ValidPerg()
		Return()
	EndIf

	//cNFpr01,cNFpr02,cPfxpr02,dDtpr04,dDtpr05,cMSGpr06,cMSGpr07,cMSGpr08,cCodiC,cLojaC,cCamArq,oDANFE,lImpBol
	//Chamada rotina envio Dados Sicoob
	DbSelectArea("SF2")
	DbSetOrder(1)
	DbSeek(xFilial("SF2")+aParRet[1]+aParRet[3])
	cCodiC    := SF2->F2_CLIENTE
	cLojaC    := SF2->F2_LOJA
	U_BEFINM01(aParRet[1],aParRet[2],aParRet[3],aParRet[4],aParRet[5],Alltrim(aParRet[6]),Alltrim(aParRet[7]),Alltrim(aParRet[8]),cCodiC,cLojaC)
Return()


/*/{Protheus.doc} ValidPerg
description
@type function
@version  
@author iglal
@since 8/14/2024
@return variant, return_description
/*/
Static Function ValidPerg()

	Local lRet      := .F.
	Local dDataDe   := FirstDate(Date())
	Local dDataAt   := LastDate(Date())

	//Adiciona os parametros para a pergunta
	AADD( aParBox , { 1 , "Nota de"     , Space(TAMSX3("E1_NUM")[1]),  "", ".T.", "SF2", ".T.", 80,  .F.})
	AADD( aParBox , { 1 , "Nota até"    , Space(TAMSX3("E1_NUM")[1]),  "", ".T.", "SF2", ".T.", 80,  .T.})
	AADD( aParBox , { 1 , "Prefixo"     , Space(TAMSX3("E1_PREFIXO")[1]),  "", ".T.", "", ".T.", 80,  .T.})
	AADD( aParBox , { 1 , "Emissão de"  , dDataDe,  "", ".T.", "", ".T.", 80,  .F.})
	AADD( aParBox , { 1 , "Emissão até" , dDataAt,  "", ".T.", "", ".T.", 80,  .T.})
	AADD( aParBox , { 1 , "Msg01"       , Space(100), "", ".T.", "",    ".T.", 120, .F.})
	AADD( aParBox , { 1 , "Msg02"       , Space(100), "", ".T.", "",    ".T.", 120, .F.})
	AADD( aParBox , { 1 , "Msg03"       , Space(100), "", ".T.", "",    ".T.", 120, .F.})

	lRet := ParamBox(aParBox ,"Boleto Sicoob",aParRet)
Return lRet
