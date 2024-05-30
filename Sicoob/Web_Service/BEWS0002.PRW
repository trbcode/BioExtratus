/*//#########################################################################################
Projeto : Sicoob
Modulo  : module
Fonte   : BEWS0002
Objetivo: Integração EndPoints
*///#########################################################################################

#INCLUDE 'TOTVS.CH'


/*/{Protheus.doc} BEWS0002

    Integração EndPoints

    @author  Igor Guimarães
    @example Exemplos
    @param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
    @return  Especifica_o_retorno
    @table   Tabelas
    @since   29-05-2024
/*/

User Function BEWS0002(cOrigem,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,aCB_RN_NN)

	Local aAreaSICOOB     := Getarea()
	Local nX              := 0
	Local cCert	          := ""
	Local cKey	          := ""
	Local cBcoCNAB        := ""
	Local cAgeCNAB        := ""
	Local cCtaCNAB        := ""
	Local lInclui         := .F.
	Local lAlter          := .F.
	Local lExclui         := .F.
	Local lDetalh         := .F.
	Local cCodConv        := "338184"
	//Local cDir            := "/TMP/"
	Local lLogin          := Type("cEmpAnt") != "U"
	Local cDatBase        := ""
	Local cDatIni         := ""
	Local cDatFim         := ""
	Local cURL            := ""
	Local cCodClie        := ""
	Local cPath           := ""
	Local cToken          := ""
	Local aHeader         := {}
	Private oToken        As Object
	Private oJsonSicoob   As Object

	If !lLogin
		cOrigem   := "LIS"
		RpcSetEnv("01","0201","Admin")
	Else
		lInclui   := cOrigem == "GER"
		lAlter    := cOrigem == "ALT"
		lExclui   := cOrigem == "EXC"
		lDetalh   := cOrigem == "DET"
	EndIf

	cDatBase  := DtoS(dDataBase)
	dDatabkp  := dDataBase
	cCert     := "\certs\0201_certif_cert.pem"
	cKey      := "\certs\0201_certif_key.pem"
	cBcoCNAB  := AllTrim( SuperGETMV( "BE_BCSICOB",, "756" ))
	cAgeCNAB  := AllTrim( SuperGETMV( "BE_AGSICOB",, "4030" ))
	cCtaCNAB  := AllTrim( SuperGETMV( "BE_CCSICOB",, "421103"))
	cURL      := SuperGetMV("RL_URLSICO",.T.,"https://api.sicoob.com.br/cobranca-bancaria/v2")
	cCodClie := SuperGetMV("RL_CLISICO",.T.,"d33a45d6-bebd-4839-9f22-9672d5d83422")

	oToken := U_BEWS0001()
	cToken := oToken['token_type']+space(1)+oToken['access_token']

	Aadd(aHeader, 'Authorization: ' + cToken )
	Aadd(aHeader,'Content-Type: application/json')
	Aadd(aHeader,'Charset: UTF-8')
	Aadd(aHeader,'client_id: '+cCodClie)

	IF lInclui

		oJsonSicoob :=  JsonObject():New()

		oJsonSicoob['numeroContrato']                      := cCodConv
		oJsonSicoob['modalidade']                          := 1
		oJsonSicoob['numeroContaCorrente']                 := val(cCtaCNAB)
		oJsonSicoob['especieDocumento']                    := "DM"
		oJsonSicoob['dataEmissao']                         := FWTimeStamp(5,stod(aDadosTit[2]),Time())
		oJsonSicoob['seuNumero']                           := aDadosTit[1]
		oJsonSicoob['identificacaoEmissaoBoleto']          := 2
		oJsonSicoob['identificacaoDistribuicaoBoleto']     := 2
		oJsonSicoob['valor']                               := aDadosTit[5]
		oJsonSicoob['dataVencimento']                      := FWTimeStamp(5,stod(aDadosTit[4]),Time())
		oJsonSicoob['tipoDesconto']                        := 0
		oJsonSicoob['tipoMulta']                           := 0 //0 - Isento 1 - Valor Fixo 2 - Percentual
		//oJsonSicoob['dataMulta']                           := FWTimeStamp(5,stod(aDadosTit[4])+1,Time())
		//oJsonSicoob['valorMulta']                          := 0.33
		oJsonSicoob['tipoJurosMora']                       := 2 // 1 - Valor por dia 2 - Taxa Mensal 3 - Isento
		oJsonSicoob['dataJurosMora']                       := FWTimeStamp(5,stod(aDadosTit[4])+1,Time())
		oJsonSicoob['valorJurosMora']                      := 10.00
		oJsonSicoob['numeroParcela']                       := 1
		oJsonSicoob['codigoNegativacao']                   := 3
		oJsonSicoob['numeroDiasNegativacao']               := 60
		oJsonSicoob['codigoProtesto']                      := 3
		oJsonSicoob['numeroDiasProtesto']                  := 30
		oJsonSicoob['gerarPdf']                            := .f.
		oJsonSicoob['codigoCadastrarPIX']                  := 2
		oJsonSicoob['pagador']                             := JsonObject():new()
		oJsonSicoob['pagador']['numeroCpfCnpj']            := Alltrim(aDatSacado[7])
		oJsonSicoob['pagador']['nome']                     := Alltrim(aDatSacado[1])
		oJsonSicoob['pagador']['endereco']                 := Alltrim(aDatSacado[3])
		oJsonSicoob['pagador']['bairro']                   := Alltrim(aDatSacado[9])
		oJsonSicoob['pagador']['cidade']                   := Alltrim(aDatSacado[4])
		oJsonSicoob['pagador']['cep']                      := PadL(Alltrim(aDatSacado[6]),8,"0")
		oJsonSicoob['pagador']['uf']                       := Alltrim(aDatSacado[5])
		oJsonSicoob['beneficiarioFinal']                   := JsonObject():new()
		oJsonSicoob['beneficiarioFinal']['numeroCpfCnpj']  := STRTRAN(STRTRAN(STRTRAN(STRTRAN(STRTRAN(Alltrim(aDadosEmp[6]),"CNPJ:",""),".",""),"/",""),"-","")," ","")
		oJsonSicoob['beneficiarioFinal']['nome']           := UPPER(Alltrim(aDadosEmp[1]))

		cPath  := "/boletos"

		cBody := "["+EncodeUTF8(oJsonSicoob:ToJson())+"]"
		cPostRet := HTTPSPost( cUrl + cPath, cCert, cKey, cPswCert, cPostParms, cBody, nTimeOut, aHeader, @cHeaderGet)

		oResponse := JsonObject():new()
		oResponse:fromJson(FwNoAccent(cPostRet))
		If oResponse['resultado'][1]['status']['codigo'] == 200
			aCB_RN_NN[1] := cValtoChar(oResponse['resultado'][1]['boleto']['codigoBarras'])
			aCB_RN_NN[2] := cValtoChar(oResponse['resultado'][1]['boleto']['linhaDigitavel'])
			aCB_RN_NN[3] := cValtoChar(oResponse['resultado'][1]['boleto']['nossoNumero'])
			lRet := .T.
		Else
			Alert(cPostRet)
		EndIf
	EndIf
	IF cOrigem == "LIS"
		For nX:= 1 to 7
			if datavalida(DATE()-nX) <> DATE()
				cDatIni := CVALTOCHAR(YEAR(DATE()-nX))+STRZERO(MONTH(DATE()-nX),2)+STRZERO(DAY(DATE()-nX),2)
				dDataBase := DATE()-nX
				EXIT
			EndIf
		Next nX
	EndIF

	cDatFim     := cDatIni

	dDataBase := dDatabkp
	RestArea(aAreaSicoob)
Return()
