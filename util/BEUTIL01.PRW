#INCLUDE 'TOTVS.CH'
#INCLUDE "Fileio.ch"
/*/{Protheus.doc} FileTo64
Converte o conteúdo de um arquivo em uma string codificada em Base64.
@type function
@version 1.0  
@author Igor Guimarães 
@since 11/4/2025
@param cFile, character, nome do arquivo a ser convertido
@return variant, string codificada em Base64
/*/
User Function FileTo64(cFile)
	Local cTexto := ""
	Local aFiles := {} // O array receberá os nomes dos arquivos e do diretório
	Local aSizes := {} // O array receberá os tamanhos dos arquivos e do diretorio

	ADir(cFile, aFiles, aSizes)//Verifica o tamanho do arquivo, parâmetro exigido na FRead.

	nHandle := fopen(cFile , FO_READ)
	cString := ""
	If Len(aSizes) > 0
		FRead( nHandle, cString, aSizes[1] ) //Carrega na variável cString, a string ASCII do arquivo.
	EndIf

	cTexto := Encode64(cString) //Converte o arquivo para BASE64

	fclose(nHandle)
Return cTexto
/*/{Protheus.doc} ChecaFile
Verifica se o arquivo está vazio ou não existe.
@type function
@version 1.0  
@author Igor Guimarães
@since 11/4/2025
@param cFile, character, nome do arquivo a ser verificado
@return variant, retorna .T. se o arquivo estiver vazio ou não existir, caso contrário .F.
/**/
User Function ChecaFile(cFile)
	Local nHandle	:= FOPEN(cFile)     // Abre o arquivo binário
	Local cBuffer	:= SPACE(512)
	Local nBytes	:= FREAD(nHandle, @cBuffer, 128)
	FCLOSE(nHandle)
Return nBytes == 0 .OR. nHandle == -1
