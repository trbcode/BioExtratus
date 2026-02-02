#include "protheus.ch"
/*/{Protheus.doc} ReadFile
@description Lê o conteúdo de um arquivo e retorna como string.     
@type function
@version 1.0
@author Igor Leonardo
@since 20/11/2025
@param cFile, character, Caminho completo do arquivo a ser lido.
@return cBuffer, character, Conteúdo do arquivo lido.
/*/
User Function xReadFile(cFile)

	Local aArea := {}
	Local cBuffer := ''
	Local nH
	Local nTam

	nH := Fopen(cFile)
	IF nH != -1
		nTam := fSeek(nH,0,2)
		fSeek(nH,0)
		cBuffer := space(nTam)
		fRead(nH,@cBuffer,nTam)
		fClose(nH)
	Else
		MsgStop("Falha na abertura do arquivo ["+cFile+"]","FERROR "+cValToChar(Ferror()))
	Endif
	RestArea(aArea)
Return cBuffer
