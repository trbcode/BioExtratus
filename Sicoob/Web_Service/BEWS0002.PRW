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
	U_BEWS0002("GER",@aDadosEmp,aDadosTit,@aBancos, nPOS,aDatSacado,aBolText,@aDados)
/*/

User Function BEWS0002(cOrigem,aDadosEmp,aDadosTit,aBancos,nPOS,aDatSacado,aBolText,aDados)

	Local aAreaSICOOB     := Getarea()
	Local nX,nY,nZ        := 0
	Local cBcoCNAB        := ""
	Local cAgeCNAB        := ""
	Local cCtaCNAB        := ""
	Local lInclui         := .F.
	Local lAlter          := .F.
	Local lExclui         := .F.
	Local lDetalh         := .F.
	Local cCodConv        := AllTrim( aBancos[nPOS][8])
	Local lLogin          := Type("cEmpAnt") != "U"
	Local cDatIni         := ""
	Local cDatFim         := ""
	Local cURL            := ""
	Local cCodClie        := ""
	Local cPath           := ""
	Local cToken          := ""
	Local aHeader         := {}
	Local cKey 	          := SuperGetMV("BE_CHVKEY",.T.,"\certs\000002_key.pem")
	Local cCert           := SuperGetMV("BE_CHVCER",.T.,"\certs\000002_cert.pem")
	Local cPostParms      := ""
	Local nTimeOut        := 120
	Local cPswCert        := GETMV("BE_PSWSICO")
	Local cHeaderGet      := ""
	Local cPostRet        := ""
	Local lRet        := .F.
	Private oToken        As Object
	Private oJsonSicoob   As Object

	If !lLogin
		cOrigem   := "LIS"
		RpcSetEnv("01","01","Admin")
	Else
		lInclui   := cOrigem == "GER"
		lAlter    := cOrigem == "ALT"
		lExclui   := cOrigem == "EXC"
		lDetalh   := cOrigem == "DET"
	EndIf

	dDatabkp  := dDataBase

	IF cOrigem == "LIS"
		For nX:= 1 to 7
			if datavalida(DATE()-nX) <> DATE()
				cDatIni := CVALTOCHAR(YEAR(DATE()-nX))+STRZERO(MONTH(DATE()-nX),2)+STRZERO(DAY(DATE()-nX),2)
				dDataBase := DATE()-nX
				EXIT
			EndIf
		Next nX
		cDatFim := cDatIni
	EndIF

	cBcoCNAB  := aBancos[nPOS][1]//PADR(AllTrim( SuperGETMV( "BE_BCSICOB",, "756" )),TAMSX3("A6_COD")[1])
	cAgeCNAB  := PADR(Alltrim(aBancos[nPOS][10]),TAMSX3("A6_AGENCIA")[1])//PADR(AllTrim( SuperGETMV( "BE_AGSICOB",, "4108" )),TAMSX3("A6_AGENCIA")[1])
	cCtaCNAB  := PADR(Alltrim(aBancos[nPOS][7]),TAMSX3("A6_NUMCON")[1])//PADR(AllTrim( SuperGETMV( "BE_CCSICOB",, "84298" )),TAMSX3("A6_NUMCON")[1])
	cURL      := SuperGetMV("BE_URLSICO",.T.,"https://api.sicoob.com.br/cobranca-bancaria/v2")
	cCodClie  := SuperGetMV("BE_CLISICO",.T.,"e24ab947-b2b6-4c55-86fb-2662a014a63b")

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
		oJsonSicoob['valorJurosMora']                      := 10.00 // ver de onde pegamas essa informação
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
		If oResponse['resultado'][1]['status']['codigo'] == 200
			aDados[2] := cValtoChar(oResponse['resultado'][1]['boleto']['codigoBarras'])
			aDados[3] := cValtoChar(oResponse['resultado'][1]['boleto']['linhaDigitavel'])
			aBancos[nPOS][11] := cValtoChar(oResponse['resultado'][1]['boleto']['nossoNumero'])
			lRet := .T.
		Else
			Alert(cPostRet)
		EndIf

	ElseIf lExclui

		cPath  := "/boletos/baixa"
		nRecno := aDados[3]
		dbSelectArea( "SE1" )
		SE1->(DbGoTo(nRecno))
		oJsonSicoob :=  JsonObject():New()

		oJsonSicoob['numeroContrato']  := val(cCodConv)
		oJsonSicoob['modalidade']      := 1
		oJsonSicoob['nossoNumero']     := val(SE1->E1_NOSNUM)
		oJsonSicoob['seuNumero']       := Alltrim(SE1->E1_NUM)+Alltrim(SE1->E1_PARCELA)

		cBody := EncodeUTF8(oJsonSicoob:ToJson())
		cResponse := HTTPQuote( cURL+cPath, "PATCH", "", "["+cBody+"]", 120, aClone(aHeader), @cHeaderGet )

		oResponse := JsonObject():new()
		oResponse:fromJson(FwNoAccent(cResponse))
		If oResponse['resultado'][1]['status']['codigo'] == 200 .or. (oResponse['resultado'][1]['status']['codigo'] == 400 .and. "processo de baixa" $ oResponse['resultado'][1]['status']['mensagem'])
			FWAlertSuccess("Cancelamento da cobrança do título "+ oResponse['resultado'][1]['boleto']['seuNumero']+", realizado com sucesso!", "Retorno Sicoob-BEWS0002")
			lRet := .T.
			Return lRet
		Else
			FWAlertWarning("Falha ao cancelar cobrança!", "Retorno Sicoob-BEWS0002")
			Return lRet
		EndIf
	Else
		cPath     := "/boletos/solicitacoes/movimentacao"

		oJsonSicoob :=  JsonObject():New()
		oJsonSicoob['numeroContrato']                  := val(cCodConv)
		oJsonSicoob['tipoMovimento']                   := 5
		oJsonSicoob['dataInicial']                     := FWTimeStamp(5,ddatabase,Time())
		oJsonSicoob['dataFinal']                       := FWTimeStamp(5,ddatabase,Time())

		cBody := EncodeUTF8(oJsonSicoob:ToJson())
		cPostRet := HTTPSPost( cUrl + cPath, cCert, cKey, cPswCert, cPostParms, cBody, nTimeOut, aHeader, @cHeaderGet)

		oResponse := JsonObject():new()
		oResponse:fromJson(FwNoAccent(cPostRet))
		If valtype(oResponse['resultado']['codigoSolicitacao']) == "N"
			cParams := "numeroContrato=" + cCodConv +"&"
			cParams += "codigoSolicitacao=" + cValtoChart(oResponse['resultado']['codigoSolicitacao'])
			cPostRet := HTTPSGet( cUrl + cPath, cCert, cKey, cPswCert, cParams, nTimeOut, aHeader, @cHeaderGet)
			SLEEP( 20000 )
			oResp:= JsonObject():new()
			oResp:fromJson(FwNoAccent(cPostRet))
			If oResp['resultado']['quantidadeArquivo'] > 0
				cPath := "/boletos/movimentacao-download"
				For nZ := 1 to Len(oResp['resultado']['idArquivos'])
					_cParams := cParams+"&idArquivo="+cValtoChar(oResp['resultado']['idArquivos'][nZ])
					cPostRet := HTTPSGet( cUrl + cPath, cCert, cKey, cPswCert, _cParams, nTimeOut, aHeader, @cHeaderGet)
					oRespZip:= JsonObject():new()
					oRespZip:fromJson(FwNoAccent(cPostRet))
					If !Empty(oRespZip['resultado']['arquivo'])
						cNomeArq := substr(oRespZip['resultado']['nomeArquivo'],1,len(oRespZip['resultado']['nomeArquivo'])-4)
						cArquivo := cDir+cNomeArq+".zip"
						cDecode  := Decode64(oRespZip['resultado']['arquivo'])
						MemoWrite(cArquivo,cDecode)
						FUnzip( cArquivo, cDir)
						cJsonStr := decodeutf8(ReadFile(cDir+cNomeArq+".json"))
						oJson := JSonObject():New()
						if FwJSONDeserialize(cJsonStr,@oJson)
							ConOut( "Inicio baixa API Sicoob!")
							For nY := 1 to Len(oJson)
								nVlrJur := 0
								lLiq := oJson[nY]['MODALIDADE'] == 1
								cNosso := cValToChar(oJson[nY]['NUMEROTITULO'])
								nRecno := GetChave(cNosso)
								If lLiq .and. nRecno > 0
									dDatMov     := datavalida(StoD(strtran(substr(oJson[nY]['DATALIQUIDACAO'],1,10),'-','')))
									dDatCred    := datavalida(StoD(strtran(substr(oJson[nY]['DATAPREVISAOCREDITO'],1,10),'-','')))
									nValBx      := oJson[nY]['VALORTITULO']
									ntotal      += oJson[nY]['VALORTITULO']
									natual      += oJson[nY]['VALORLIQUIDO']
									If (oJson[nY]['VALORLIQUIDO'] - oJson[nY]['VALORTITULO']) > nVlrReg
										nVlrJur := (oJson[nY]['VALORLIQUIDO'] - oJson[nY]['VALORTITULO'])
										nTotJur += nVlrJur
									endIf
									If BE02GrBx(nRecno, nValBx, cBcoCNAB, cAgeCNAB, cCtaCNAB,dDatCred,dDatMov,nVlrJur)
										FWLogMsg("WARN", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("O titulo com o nosso numero "+cNosso+" foi baixado com sucesso!") , 0, 0)
										nVlrTar     += oJson[nY]['VALORTARIFAMOVIMENTO']
									Else
										FWLogMsg("WARN", "", "Erro", "BEWS0002", "", "", EncodeUTF8("Erro ao baixar titulo com o nosso numero "+cNosso+"!") , 0, 0)
									EndIf
								EndIf
								nRecno := 0
							Next nY

							if nVlrTar > 0
								if IncMov(cBcoCNAB,cAgeCNAB,cCtaCNAB,"20831", "P", , , nVlrTar, dDatCred, , , "Movimento tariafa gerado com sucesso!")
									FWLogMsg("WARN", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("Tarifa gerada com sucesso!") , 0, 0)
								EndIf
							EndIf

							ConOut( "Valor total baixa ="+Transform(ntotal,'@E 999,999,999.99'))
							ConOut( "Valor total Original ="+Transform(natual,'@E 999,999,999.99'))
							ConOut( "Valor total Original ="+Transform(nTotJur,'@E 999,999,999.99'))

						EndIf
					EndIf
				Next nZ
			EndIF
		Else
			Alert(FwJSONDeserialize(cPostRet,@oJson))
		EndIf
	EndIf

	dDataBase := dDatabkp
	RestArea(aAreaSicoob)
Return(lRet)


/*/{Protheus.doc} BE02GrBx
Baixa os títulos a receber
@type function
@version  
@author iglal
@since 8/14/2024
@param nRecnoSE1, numeric, param_description
@param nValBx, numeric, param_description
@param cBcoCNAB, character, param_description
@param cAgeCNAB, character, param_description
@param cCtaCNAB, character, param_description
@param dDatCred, date, param_description
@param dDatMov, date, param_description
@param nVlrJur, numeric, param_description
@return variant, return_description
/*/
Static Function BE02GrBx(nRecnoSE1, nValBx, cBcoCNAB, cAgeCNAB, cCtaCNAB,dDatCred,dDatMov,nVlrJur)

	Local aAreaSE1       := GetArea()
	Local lRet           :=  .F.
	Local aVetor         := {}
	Private lMsErroAuto  := .F.
	Private lMsHelpAuto  := .T.
	Private lMostraErro  := .F.
	Default nValBx       := 0
	Default nRecnoSE1    := 0

	lMsErroAuto := .F.
	dbSelectArea( "SE1" )
	SE1->(DbGoTo(nRecnoSE1))

	If SE1->E1_SALDO > 0

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
		AADD(aVetor,{"AUTHIST"	    	, OemToAnsi("BAIXA API Sicoob")	,Nil})
		AADD(aVetor,{"AUTBANCO"			, cBcoCNAB				,NIL}) //Banco
		AADD(aVetor,{"AUTAGENCIA"		, PADR(cAgeCNAB,TAMSX3("E1_AGEDEP")[1]),NIL}) //agencia
		AADD(aVetor,{"AUTCONTA"			, PADR(cCtaCNAB,TAMSX3("E1_CONTA")[1]),NIL}) //Conta
		if nVlrJur > 0
			AADD(aVetor,{"AUTJUROS"	    ,nVlrJur                ,Nil })
		EndIF
		AADD(aVetor,{"AUTVALREC"		, nValBx+nVlrJur		,NIL}) //Valor de pagamento

		MSExecAuto({|x,y| Fina070(x,y)},aVetor,3)

		//Em caso de erro na baixa desarma a transacao
		If lMsErroAuto
			lRet:= .F.
			Aadd(aDadosEr,{Alltrim(SE1->E1_PREFIXO),SE1->E1_NUM,SE1->E1_PARCELA,Alltrim(SE1->E1_NUMBCO),SE1->E1_CLIENTE +"/"+SE1->E1_LOJA+"-"+Alltrim(SE1->E1_NOMCLI),SE1->E1_EMISSAO,SE1->E1_VENCREA,nValBx,nVlrJur})
			If !IsBlind()
				MOSTRAERRO() // Sempre que o micro comeca a apitar esta ocorrendo um erro desta forma
			EndIf
		Else
			Aadd(aDadosBx,{Alltrim(SE1->E1_PREFIXO),SE1->E1_NUM,SE1->E1_PARCELA,Alltrim(SE1->E1_NUMBCO),SE1->E1_CLIENTE +"/"+SE1->E1_LOJA+"-"+Alltrim(SE1->E1_NOMCLI),SE1->E1_EMISSAO,SE1->E1_VENCREA,nValBx,nVlrJur,SE5->(RECNO())})
			lRet := .T.
		Endif
	Else
		Aadd(aDadosEr,{Alltrim(SE1->E1_PREFIXO),SE1->E1_NUM,SE1->E1_PARCELA,Alltrim(SE1->E1_NUMBCO),SE1->E1_CLIENTE +"/"+SE1->E1_LOJA+"-"+Alltrim(SE1->E1_NOMCLI),SE1->E1_EMISSAO,SE1->E1_VENCREA,nValBx,nVlrJur})
		lRet := .F.
	Endif
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
	Local cTMPSE1   := GetNextAlias()

	BeginSql Alias cTMPSE1
        SELECT
            R_E_C_N_O_
        FROM
            %Table:SE1% E1
        WHERE
            E1.E1_NUMBCO = %Exp:cNosso%
            AND D_E_L_E_T_ = ' '
	EndSql
	if (cTMPSE1)->(!Eof())
		nRet := (cTMPSE1)->(R_E_C_N_O_)
	EndIf
	(cTMPSE1)->(DbCloseArea())
Return(nRet)
