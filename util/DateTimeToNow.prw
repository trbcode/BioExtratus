#Include "protheus.ch"
/*/{Protheus.doc} DateTimeToNow
@description Verifica se o token armazenado no arquivo JSON ainda é válido.
@type function
@version 1.0
@author Igor Leonardo
@since 20/11/2025
@return nRet, numeric, Retorna o timestamp Unix atual.
 /*/
User Function DateTimeToNow()

	Local dBase       := CtoD("01/01/1970")
	Local nDias       := Date() - dBase
	Local nSegDia     := 0
	Local nHora       := 0
	Local nMin        := 0
	Local nSeg        := 0
	Local cHora       := Time()
	Local nRet 				:= 0

	// cHora: "HH:MM:SS"
	nHora := Val(SubStr(cHora,1,2))
	nMin  := Val(SubStr(cHora,4,2))
	nSeg  := Val(SubStr(cHora,7,2))

	nSegDia := (nHora * 3600) + (nMin * 60) + nSeg
	nRet := (nDias * 86400) + nSegDia

Return nRet
