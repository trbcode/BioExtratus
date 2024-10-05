/*//#########################################################################################
Projeto : Sicoob
Modulo  : module
Fonte   : BEWS0002
Objetivo: Integração EndPoints SICOOB
*///#########################################################################################
#INCLUDE "apwizard.ch"
#Include "FileIO.ch"
#INCLUDE 'TOTVS.CH'
/*/{Protheus.doc} BEWS0002
    Integração EndPoints
    @author  Igor Guimarães
	@type    user function
    @example Exemplos
    @param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
    @return  Logical
    @table   Tabelas
    @since   29-05-2024
	U_BEWS0002("GER",@aDadosEmp,aDadosTit,@aBancos, nPOS,aDatSacado,aBolText,@aDados)
/*/

User Function BEWS0002(cOrigem,aDadosEmp,aDadosTit,aBancos,nPOS,aDatSacado,aBolText,aDados,dDtaBx,cDatIni,cDatFim, cCodClie, cNossoNum)

	Local aAreaSICOOB     := Getarea()
	Local nY,nZ           := 0
	Local cBcoCNAB        := ""
	Local cAgeCNAB        := ""
	Local cCtaCNAB        := ""
	Local lInclui         := .F.
	Local lAlter          := .F.
	Local lExclui         := .F.
	Local lDetalh         := .F.
	Local lBaixa          := .F.
	Local cCodConv        := ""
	Local lLogin          := Type("cEmpAnt") != "U"
	Local cURL            := ""
	Local cPath           := ""
	Local cToken          := ""
	Local cMsg            := ""
	Local aHeader         := {}
	Local cKey 	          := ""
	Local cCert           := ""
	Local cPostParms      := ""
	Local nTimeOut        := 120
	Local cPswCert        := ""
	Local cHeaderGet      := ""
	Local cPostRet        := ""
	Local lRet            := .F.
	local nVlrBio		  := 0
	local nVlrFup		  := 0
	local nVlrChk		  := 0
	local cCtaBio		  := ""
	local cCtaFup		  := ""
	local cCtaChk		  := ""
	Local ntotal          := 0
	Local natual          := 0
	Local nVlrJur         := 0
	Local nTotJur         := 0
	Local cNNomArq        := ""
	Local bError		  := .F.
	Local oFile           As Object
	Private oToken        As Object
	Private oJsonSicoob   As Object
	Private cDir          := "/TMP/"
	Private cArquivo      := ""
	Private cDecode       := ""
	Private cNomeArq      := ""
	Private cJsonStr      := ""
	Default dDtaBx        := date()
	Default cDatIni       := dtos(date())
	Default cDatFim       := dtos(date())

	if !lLogin
		RpcSetEnv("01","01","Admin")
	endif

	lInclui   := cOrigem == "GER"
	lAlter    := cOrigem == "ALT"
	lExclui   := cOrigem == "EXC"
	lDetalh   := cOrigem == "DET"
	lBaixa    := cOrigem == "BAI"
	cCodConv  := AllTrim( aBancos[nPOS][8])
	cBcoCNAB  := aBancos[nPOS][1]//PADR(AllTrim( SuperGETMV( "BE_BCSICOB",, "756" )),TAMSX3("A6_COD")[1])
	cAgeCNAB  := PADR(Alltrim(aBancos[nPOS][10]),TAMSX3("A6_AGENCIA")[1])//PADR(AllTrim( SuperGETMV( "BE_AGSICOB",, "4108" )),TAMSX3("A6_AGENCIA")[1])
	cCtaCNAB  := PADR(Alltrim(aBancos[nPOS][7]),TAMSX3("A6_NUMCON")[1])//PADR(AllTrim( SuperGETMV( "BE_CCSICOB",, "84298" )),TAMSX3("A6_NUMCON")[1])
	cKey 	  := SuperGetMV("BE_CHVKEY",.T.,"\certs\000002_key.pem")
	cCert     := SuperGetMV("BE_CHVCER",.T.,"\certs\000002_cert.pem")
	cPswCert  := GETMV("BE_PSWSICO")
	cURL      := SuperGetMV("BE_URLSICO",.T.,"https://api.sicoob.com.br/cobranca-bancaria/v2")
	//cCodClie  := SuperGetMV("BE_CLISICO",.T.,"e24ab947-b2b6-4c55-86fb-2662a014a63b")

	oToken := U_BEWS0001(cCodClie)
	cToken := oToken['token_type']+space(1)+oToken['access_token']

	Aadd(aHeader, 'Authorization: ' + cToken )
	Aadd(aHeader,'Content-Type: application/json')
	Aadd(aHeader,'Charset: UTF-8')
	Aadd(aHeader,'client_id: '+cCodClie)

	if lInclui

		oJsonSicoob :=  JsonObject():New()
		oJsonSicoob['numeroContrato']                      := cCodConv
		oJsonSicoob['modalidade']                          := 1
		oJsonSicoob['numeroContaCorrente']                 := val(cCtaCNAB)
		oJsonSicoob['especieDocumento']                    := "DM"
		oJsonSicoob['dataEmissao']                         := FWTimeStamp(5,stod(aDadosTit[2]),Time())
//		oJsonSicoob['nossoNumero']						   := cNossoNum   	
		oJsonSicoob['seuNumero']                           := aDadosTit[1]
		oJsonSicoob['identificacaoEmissaoBoleto']          := 2
		oJsonSicoob['identificacaoDistribuicaoBoleto']     := 2
		oJsonSicoob['valor']                               := aDadosTit[5]
		oJsonSicoob['dataVencimento']                      := FWTimeStamp(5,stod(aDadosTit[4]),Time())
		oJsonSicoob['dataLimitePagamento']                 := FWTimeStamp(5,stod(aDadosTit[4])+30,Time())
		oJsonSicoob['tipoDesconto']                        := 0
		oJsonSicoob['tipoMulta']                           := 2 //0 - Isento 1 - Valor Fixo 2 - Percentual
		oJsonSicoob['dataMulta']                           := FWTimeStamp(5,stod(aDadosTit[4])+1,Time())
		oJsonSicoob['valorMulta']                          := aBancos[nPOS][15] // buscar na SEE
		oJsonSicoob['tipoJurosMora']                       := 2 // 1 - Valor por dia 2 - Taxa Mensal 3 - Isento
		oJsonSicoob['dataJurosMora']                       := FWTimeStamp(5,stod(aDadosTit[4])+1,Time())
		oJsonSicoob['valorJurosMora']                      := aBancos[nPOS][15] // buscar na SEE
		oJsonSicoob['numeroParcela']                       := 1
		oJsonSicoob['codigoNegativacao']                   := 3
		oJsonSicoob['numeroDiasNegativacao']               := 60
		oJsonSicoob['codigoProtesto']                      := 3
		oJsonSicoob['numeroDiasProtesto']                  := 30
		oJsonSicoob['gerarPdf']                            := .f.
		oJsonSicoob['codigoCadastrarPIX']                  := 1
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
		if oResponse['resultado'][1]['status']['codigo'] == 200
			aDados[2]  := cValtoChar(oResponse['resultado'][1]['boleto']['codigoBarras'])
			aDados[3]  := cValtoChar(oResponse['resultado'][1]['boleto']['linhaDigitavel'])
			aDados[13] := substr(padl(cValtoChar(oResponse['resultado'][1]['boleto']['nossoNumero']),8,"0"),1,7)+"-"+right(cValtoChar(oResponse['resultado'][1]['boleto']['nossoNumero']),1)
			aDados[38] := oResponse['resultado'][1]['boleto']['qrCode']
			lRet := .T.
		else
			Alert(cPostRet)
		endif

	elseif lAlter

		oJsonSicoob :=  JsonObject():New()
		oJsonSicoob['numeroContrato']                      := cCodConv
		oJsonSicoob['modalidade']                          := 1
		oJsonSicoob['nossoNumero']						   := cNossoNum
		oJsonSicoob['dataVencimento']                      := FWTimeStamp(5,aDadosTit[4],Time())

		cPath  := "/boletos/prorrogacoes/data-vencimento"
		cBody := EncodeUTF8(oJsonSicoob:ToJson())
		cResponse := HTTPQuote( cURL+cPath, "PATCH", "", "["+cBody+"]", 120, aClone(aHeader), @cHeaderGet )
		oResponse := JsonObject():new()
		oResponse:fromJson(FwNoAccent(cResponse))
		if oResponse['resultado'][1]['status']['codigo'] == 200 .or. (oResponse['resultado'][1]['status']['codigo'] == 400 )
			freeObj(oResponse)
			freeObj(oJsonSicoob)
			cPath  := "/boletos"
			cParams := "client_id=" + cCodClie +"&"
			cParams += "modalidade=1&"
			cParams += "numeroContrato="+cCodConv+"&"
			cParams += "nossoNumero="+cNossoNum
			cPostRet := HTTPSGet( cUrl + cPath, cCert, cKey, cPswCert, cParams, nTimeOut, aHeader, @cHeaderGet)
			oResp:= JsonObject():new()
			oResp:fromJson(FwNoAccent(cPostRet))
			aDados[2]  := cValtoChar(oResp['resultado']['codigoBarras'])
			aDados[3]  := cValtoChar(oResp['resultado']['linhaDigitavel'])
			aDados[38] := cValtoChar(oResp['resultado']['qrCode'])
			cMsg := '<font color="#0F0F00" size="4">Data de vencimento alterado com sucesso!</font>'
			cMsg += '<br>'
			cMsg += '<font color="#AD2121" size="4">O Sicoob pode levar algum tempo para processar essa alteração!</font>'

			FWAlertSuccess(cMsg, "Retorno Sicoob-BEWS0002")
			lRet := .T.
		else
			FWAlertWarning("Falha ao cancelar cobrança! "+ oResponse['resultado'][1]['status']['mensagem'], "Retorno Sicoob-BEWS0002")
		endif

	elseif lExclui

		cPath  := "/boletos/baixa"
		nRecno := aDados[3]
		dbSelectArea( "SE1" )
		SE1->(DbGoTo(nRecno))
		oJsonSicoob :=  JsonObject():New()
		oJsonSicoob['numeroContrato']  := val(cCodConv)
		oJsonSicoob['modalidade']      := 1
		oJsonSicoob['nossoNumero']     := val(strtran(SE1->E1_NOSNUM,"-",""))
		oJsonSicoob['seuNumero']       := Alltrim(SE1->E1_NUM)+Alltrim(SE1->E1_PARCELA)

		cBody := EncodeUTF8(oJsonSicoob:ToJson())
		cResponse := HTTPQuote( cURL+cPath, "PATCH", "", "["+cBody+"]", 120, aClone(aHeader), @cHeaderGet )

		oResponse := JsonObject():new()
		oResponse:fromJson(FwNoAccent(cResponse))
		if oResponse['resultado'][1]['status']['codigo'] == 200 .or. (oResponse['resultado'][1]['status']['codigo'] == 400 .and. "processo de baixa" $ oResponse['resultado'][1]['status']['mensagem'])

			cMsg := '<font color="#0F0F00" size="4">Cancelamento da cobrança do título '+ oResponse['resultado'][1]['boleto']['seuNumero']+', realizado com sucesso!</font>'
			cMsg += '<br>'
			cMsg += '<font color="#AD2121" size="4">O Sicoob pode levar algum tempo para processar este cancelamento!</font>'

			FWAlertSuccess(cMsg, "Retorno Sicoob-BEWS0002")
			lRet := .T.
		else
			FWAlertWarning("Falha ao cancelar cobrança! "+ oResponse['resultado'][1]['status']['mensagem'], "Retorno Sicoob-BEWS0002")
		endif

	elseif lBaixa

		cNNomArq  := "liqui_"+cDatIni+"_"+Alltrim(cAgeCNAB)+"_"+Alltrim(cCtaCNAB)
		dDatabkp  := dDataBase
		dDataBase := dDtaBx
		cPath     := "/boletos/solicitacoes/movimentacao"
		oFile     := FWFileWriter():New("\TMP\"+cNNomArq+".json", .T.)
		If !oFile:Exists()

			oJsonSicoob :=  JsonObject():New()
			oJsonSicoob['numeroContrato']                  := val(cCodConv)
			oJsonSicoob['tipoMovimento']                   := 5
			oJsonSicoob['dataInicial']                     := FWTimeStamp(5,ddatabase,Time())
			oJsonSicoob['dataFinal']                       := FWTimeStamp(5,ddatabase,Time())

			cBody := EncodeUTF8(oJsonSicoob:ToJson())
			cPostRet := HTTPSPost( cUrl + cPath, cCert, cKey, cPswCert, cPostParms, cBody, nTimeOut, aHeader, @cHeaderGet)

			oResponse := JsonObject():new()
			oResponse:fromJson(FwNoAccent(cPostRet))
			if valtype(oResponse['resultado']['codigoSolicitacao']) == "N"
				cParams := "numeroContrato=" + cCodConv +"&"
				cParams += "codigoSolicitacao=" + cValtoChart(oResponse['resultado']['codigoSolicitacao'])
				cPostRet := HTTPSGet( cUrl + cPath, cCert, cKey, cPswCert, cParams, nTimeOut, aHeader, @cHeaderGet)
				SLEEP( 20000 )
				oResp:= JsonObject():new()
				oResp:fromJson(FwNoAccent(cPostRet))

				if !valtype(oResp['mensagens']) =="A"
					if oResp['resultado']['quantidadeArquivo'] > 0
						cPath := "/boletos/movimentacao-download"
						for nZ := 1 to Len(oResp['resultado']['idArquivos'])
							_cParams := cParams+"&idArquivo="+cValtoChar(oResp['resultado']['idArquivos'][nZ])
							cPostRet := HTTPSGet( cUrl + cPath, cCert, cKey, cPswCert, _cParams, nTimeOut, aHeader, @cHeaderGet)
							oRespZip:= JsonObject():new()
							oRespZip:fromJson(FwNoAccent(cPostRet))
							if !Empty(oRespZip['resultado']['arquivo'])
								cNomeArq := substr(oRespZip['resultado']['nomeArquivo'],1,len(oRespZip['resultado']['nomeArquivo'])-4)
								cArquivo := cDir+cNomeArq+".zip"
								cDecode  := Decode64(oRespZip['resultado']['arquivo'])
								MemoWrite(cArquivo,cDecode)
								FUnzip( cArquivo, cDir)
								FRename(cDir+cNomeArq+".json", cDir+cNNomArq+".json")
							endif
						next nZ
						bError := .T.
					else
						bError := .F.
					endif
				Else
				/*
					if !IsBlind()
						cMsgErr := "<br>Infelizmente, a baixa referente ao dia   <b>" + DTOC(STOD(cDatFim)) + "</b> apresentou um erro. "
						cMsgErr	+= " Por gentileza, confirme se é um dia útil e refaça o procedimento.<br><br>"
						U_EnviaEmail("Erro na Baixa Automática", cMsgErr, "alesssandro.magno@bioextratus.com.br", "", "")
					else
						FWAlertWarning(cMsgErr, "Erro na Baixa Automática")						
						U_EnviaEmail("Erro na Baixa Automática", cMsgErr, "alesssandro.magno@bioextratus.com.br", "", "")
						FWLogMsg("ERROR", "", "Erro", "BEWS0002", "", "", EncodeUTF8("Erro ao baixar título com o número "+cNossoNum+"!") , 0, 0)
					endIf
				*/
					bError := .F.
				EndIf
			else
				bError := .F.
			endif
		endif

		oFile:Close()
		cJsonStr := decodeutf8(ReadFile(cDir+cNNomArq+".json", cDatFim))
		oJson := JSonObject():New()
		oJson:FromJson(cJsonStr)
		FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("Inicio baixa API Sicoob!") , 0, 0)
		if len(oJson) = 0
			bError := .F.
		endif
		for nY := 1 to Len(oJson)
			nVlrJur := 0
			nMulta  := 0
			lLiq := oJson[nY]['modalidade'] == 1
			cNosso := substr(padl(cValToChar(oJson[nY]['numeroTitulo']),8,"0"),1,7)+"-"+right(cValToChar(oJson[nY]['numeroTitulo']),1)
			nRecno := GetChave(cNosso)
			if lLiq .and. nRecno > 0
				dDatMov     := datavalida(StoD(strtran(substr(oJson[nY]['dataLiquidacao'],1,10),'-','')))
				dDatCred    := datavalida(StoD(strtran(substr(oJson[nY]['dataPrevisaoCredito'],1,10),'-','')))
				nValBx      := oJson[nY]['valorTitulo']
				ntotal      += oJson[nY]['valorTitulo']
				natual      += oJson[nY]['valorLiquido']
				if (oJson[nY]['valorLiquido'] - oJson[nY]['valorTitulo']) > 0
					nVlrJur := (oJson[nY]['valorLiquido'] - oJson[nY]['valorTitulo'])
					nTotJur += nVlrJur
				endif
				if BE02GrBx(nRecno, nValBx, cBcoCNAB, cAgeCNAB, cCtaCNAB,dDatCred,dDatMov,nVlrJur,nMulta)
					FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("O titulo com o nosso numero "+cNosso+" foi baixado com sucesso!") , 0, 0)

					if CVALTOCHAR(oJson[nY]['numeroContaCorrente'])== '84298'
						nVlrBio  += oJson[nY]['valorTarifaMovimento']
						cCtaBio := CVALTOCHAR(oJson[nY]['numeroContaCorrente'])
					elseif CVALTOCHAR(oJson[nY]['numeroContaCorrente'])== '160687'
						nVlrFup  += oJson[nY]['valorTarifaMovimento']
						cCtaFup := CVALTOCHAR(oJson[nY]['numeroContaCorrente'])
					elseif CVALTOCHAR(oJson[nY]['numeroContaCorrente'])== '393800'
						nVlrChk  += oJson[nY]['valorTarifaMovimento']
						cCtaChk := CVALTOCHAR(oJson[nY]['numeroContaCorrente'])
					endif
				else
					FWLogMsg("ERROR", "", "Erro", "BEWS0002", "", "", EncodeUTF8("Erro ao baixar titulo com o nosso numero ") , 0, 0)
				endif
				bError := .T.
			endif
			nRecno := 0
		next nY

		if nVlrBio > 0
			if IncMov(cBcoCNAB,cAgeCNAB,cCtaBio,"2040003", "P", , , nVlrBio, dDatCred, , , "Movimento tariafa gerado com sucesso!")
				FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("Tarifa gerada com sucesso!") , 0, 0)
				lRet := .T.
			endif
		endif

		if nVlrFup > 0
			if IncMov(cBcoCNAB,cAgeCNAB,cCtaFup,"2040003", "P", , , nVlrFup, dDatCred, , , "Movimento tariafa gerado com sucesso!")
				FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("Tarifa gerada com sucesso!") , 0, 0)
				lRet := .T.
			endif
		endif

		if nVlrChk > 0
			if IncMov(cBcoCNAB,cAgeCNAB,cCtaChk,"2040003", "P", , , nVlrChk, dDatCred, , , "Movimento tariafa gerado com sucesso!")
				FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("Tarifa gerada com sucesso!") , 0, 0)
				lRet := .T.
			endif
		endif

		if !bError
			cMsgErr := "<br>Infelizmente, a baixa referente ao dia   <b>" + DTOC(STOD(cDatFim)) + "</b> apresentou um erro. "
			cMsgErr	+= " Por gentileza, confirme se é um dia útil e refaça o procedimento.<br><br>"
			U_EnviaEmail("Erro na Baixa Automática", cMsgErr, "alesssandro.magno@bioextratus.com.br", "", "")
		endif

		FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("Valor total baixa ="+Transform(ntotal ,'@E 999,999,999.99')) , 0, 0)
		FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("Valor total Original ="+Transform(natual ,'@E 999,999,999.99')) , 0, 0)
		FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("Valor total Original ="+Transform(nTotJur,'@E 999,999,999.99')) , 0, 0)


		dDataBase := dDatabkp
	endif

	FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("Fim baixa API Sicoob!") , 0, 0)
	RestArea(aAreaSicoob)
Return(lRet)


/*/{Protheus.doc} BE02GrBx
Baixa os títulos a receber
@type function

@author iglal
@since 8/14/2024
@param nRecnoSE1, numeric, recno do título de baixa
@param nValBx, numeric, param_description
@param cBcoCNAB, character, param_description
@param cAgeCNAB, character, param_description
@param cCtaCNAB, character, param_description
@param dDatCred, date, param_description
@param dDatMov, date, param_description
@param nVlrJur, numeric, param_description
@return variant, return_description
/*/
Static Function BE02GrBx(nRecnoSE1, nValBx, cBcoCNAB, cAgeCNAB, cCtaCNAB,dDatCred,dDatMov,nVlrJur,nMulta)

	Local aAreaSE1       := GetArea()
	Local lRet           :=  .F.
	Local aVetor         := {}
	local cChaveSA6      := cBcoCNAB+cAgeCNAB+cCtaCNAB
	Local cFunName		 := FunName()
	Private lMsErroAuto  := .F.
	Private lMsHelpAuto  := .T.
	Private lMostraErro  := .F.
	Default nValBx       := 0
	Default nRecnoSE1    := 0

	lMsErroAuto := .F.
	dbSelectArea( "SE1" )
	SE1->(DbGoTop())
	SE1->(DbSetOrder(1))
	SE1->(DbGoTo(nRecnoSE1))
	cChvSE1 := xFilial("SE1") +  SE1->E1_PREFIXO +  SE1->E1_NUM  +  SE1->E1_PARCELA +  SE1->E1_TIPO
	SE1->(MsSeek(cChvSE1 ))
	if SE1->E1_SALDO > 0

		dbSelectArea("SA6")
		dbSetOrder(1)
		dbSeek(xFilial("SA6")+cChaveSA6)

		dbSelectArea("SA1")
		dbSetOrder(1)
		dbSeek(xFilial("SA1")+SE1->E1_CLIENTE + SE1->E1_LOJA )

		SetFunName("FINA070")

		AADD(aVetor,{"E1_FILIAL"        , SE1->E1_FILIAL        , Nil } )
		AADD(aVetor,{"E1_PREFIXO"		, SE1->E1_PREFIXO 		,Nil})
		AADD(aVetor,{"E1_NUM"			, SE1->E1_NUM       	,Nil})
		AADD(aVetor,{"E1_PARCELA"		, SE1->E1_PARCELA  		,Nil})
		AADD(aVetor,{"E1_TIPO"	   	 	, SE1->E1_TIPO     		,Nil})
		AADD(aVetor,{"E1_CLIENTE"		, SE1->E1_CLIENTE  		,Nil})
		AADD(aVetor,{"E1_LOJA"	    	, SE1->E1_LOJA     		,Nil})
		AADD(aVetor,{"E1_MOEDA"	    	, SE1->E1_MOEDA     	,Nil})
		AADD(aVetor,{"AUTMOTBX"	    	, "NOR"            		,Nil})
		AADD(aVetor,{"AUTDTBAIXA"		, dDatMov				,Nil})
		AADD(aVetor,{"AUTDTCREDITO"	    , dDatCred				,Nil})
		AADD(aVetor,{"AUTHIST"	    	, OemToAnsi("Baixa API Sicoob")	,Nil})
		AADD(aVetor,{"AUTBANCO"			, SE1->E1_PORTADO		,NIL}) //Banco
		AADD(aVetor,{"AUTAGENCIA"		, SE1->E1_AGEDEP		,NIL}) //agencia
		AADD(aVetor,{"AUTCONTA"			, SE1->E1_CONTA			,NIL}) //Conta
		if nVlrJur > 0
			AADD(aVetor,{"AUTJUROS"	    ,nVlrJur                ,Nil })
		endif
		AADD(aVetor,{"AUTVALREC"		, nValBx+nVlrJur		,NIL}) //Valor de pagamento
		AADD( aVetor, { "AUTMULTA"  	, nMulta						, Nil } )

		MSExecAuto({|x,y| Fina070(x,y)},aVetor,3)

		//Em caso de erro na baixa desarma a transacao
		if lMsErroAuto
			lRet:= .F.
			FWLogMsg("ERROR", "", "Alerta!", "BEWS0002", "", "", EncodeUTF8("Erro ao baixar o título"+SE1->E1_PREFIXO+"-"+SE1->E1_NUM+"-"+SE1->E1_PARCELA+", favor fazer baixa manual!") , 0, 0)
			if !IsBlind()
				MOSTRAERRO() // Sempre que o micro comeca a apitar esta ocorrendo um erro desta forma
			endif
		else
			FWLogMsg("INFO", "", "Sucesso!", "BEWS0002", "", "", EncodeUTF8("O tÍtulo "+SE1->E1_PREFIXO+"-"+SE1->E1_NUM+"-"+SE1->E1_PARCELA+" com o nosso numero "+cNosso+" foi baixado com sucesso!") , 0, 0)
			lRet := .T.
		endif
	else
		FWLogMsg("WARN", "", "Alerta!", "BEWS0002", "", "", EncodeUTF8("O tÍtulo "+SE1->E1_PREFIXO+"-"+SE1->E1_NUM+"-"+SE1->E1_PARCELA+" sem saldo para baixa!") , 0, 0)
		lRet := .F.
	endif
	SetFunName(cFunName)
	RestArea(aAreaSE1)
Return lRet


/*/{Protheus.doc} GetChave
description
@type function
@version  
@author Igor Guimarães
@since 8/19/2024
@param cNosso, character, param_description
@return variant, return_description
/*/
Static Function GetChave(cNosso)

	Local nRet      := 0
	Local cTMPSE1   := GetnextAlias()

	BeginSql Alias cTMPSE1
        SELECT
            R_E_C_N_O_
        FROM
            %Table:SE1% E1
        WHERE
            E1.E1_NUMBCO = %Exp:cNosso%
            AND D_E_L_E_T_ = ' ' 
			AND E1.E1_PORTADO = '756'
			AND E1.E1_SALDO > 0
	EndSql
	while (cTMPSE1)->(!Eof())
		nRet := (cTMPSE1)->(R_E_C_N_O_)
		(cTMPSE1)->(dbskip())
	enddo
	(cTMPSE1)->(DbCloseArea())
Return(nRet)


/*/{Protheus.doc} ReadFile6
Leitura arquivo 
@type function
@version  
@author Igor Guimarães
@since 8/22/2024
@param cFile, character, param_description
@return variant, return_description
/*/
Static Function ReadFile(cFile, cDatFim)

	Local cBuffer := ''
	Local nH , nTam
	local cParaErro:=  'protheus@bioextratus.com.br,jeane.alvernaz@bioextratus.com.br'
	local cMsgErr := ''

	nH := Fopen(cFile)
	if nH != -1
		nTam := fSeek(nH,0,2)
		fSeek(nH,0)
		cBuffer := space(nTam)
		fRead(nH,@cBuffer,nTam)
		fClose(nH)
	else
		cMsgErr    := "<br>Infelizmente, a baixa referente ao dia   <b>" + DTOC(STOD(cDatFim)) + "</b> apresentou um erro. "
		cMsgErr	+= " Por gentileza, refaça o procedimento através do menu.<br><br>"
		cMsgErr	+= "Nome do Arquivo: "+ cFile + "<br><br>"
		if cDatFim == DTOS(DataValida(cDatFim))
			U_BIOPADEM(cParaErro, "[BAIXAS AUTOMÁTICAS] - Erro na Baixa Automática: ", cMsgErr, "" , , )
		end if//		MsgStop("Falha na abertura do arquivo ["+cFile+"]","FERROR "+cValToChar(Ferror()))
	endif
Return cBuffer

/*/{Protheus.doc} IncMov

    Inclusão Movimento Financeiro

    @author  Igor Guimarães
    @example Exemplos
    @param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
    @return  Especifica_o_retorno
    @table   Tabelas
    @since   26-03-2024
/*/

Static Function IncMov(cBanco,cAgenc,cConta,cNatureza, cTpNatur, cCodLanc, cNatMoeda, nValorLanc, dDataLanc, nTaxa, lShowErr, cLog)

	Local aFina100      := {}
	Local nOpc          := 0
	Local cRecPag       := ""
	Local lRet          := .T.
	Default cMoedaSM2   := padr("M1",TamSx3("E5_MOEDA")[1])
	Default cTipDoc     := padr("DH",TamSx3("E5_TIPODOC")[1])
	Default nTaxa       := 0
	Default cNumchq     := Dtos(dDataBase)
	Default lShowErr    := .T.
	Private lMsErroAuto := .F.

	if !lShowErr
		Private lAutoErrNoFile  := .T.
		Private lMsHelpAuto     := .T.
	endif

	if cTpNatur == 'P'
		nOpc    := 3
		cRecPag := "P"
	elseif cTpNatur == 'R'
		nOpc    := 4
		cRecPag := "R"
	endif
	cConta:= Substr(cConta,1,len(cConta)-1)
	aFina100 := { {"E5_DATA"   , dDataLanc                 , Nil},;
		{"E5_VENCTO" , dDataLanc                 , Nil},;
		{"E5_MOEDA"  , cMoedaSM2                 , Nil},;
		{"E5_VALOR"  , nValorLanc                , Nil},;
		{"E5_NATUREZ", cNatureza                 , Nil},;
		{"E5_BANCO"  , cBanco                    , Nil},;
		{"E5_AGENCIA", cAgenc                    , Nil},;
		{"E5_CONTA"  , cConta 					 , Nil},;
		{"E5_TXMOEDA", nTaxa                     , Nil},;
		{"E5_RECPAG" , cRecPag                   , Nil},;
		{"E5_TIPODOC", cTipDoc                   , Nil},;
		{"E5_NUMCHEQ", cNumchq                   , Nil},;
		{"E5_HISTOR" , 'TARIFA BANCARIA SICOOB'  , Nil}} //"Lanc entre naturezas"

	aFina100 := FWVetByDic(aFina100,"SE5",.F.,1)
	MsExecAuto({|x,y,z| FINA100(x,y,z)},0,aFina100, nOpc)
	if lMsErroAuto
		if lShowErr
			MostraErro()
		else
			aEval(GetAutoGRLog(), {|l| cLog += l + CRLF})
		endif
		lRet := .F.
	endif

Return lRet
