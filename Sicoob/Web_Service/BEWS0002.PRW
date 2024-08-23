/*//#########################################################################################
Projeto : Sicoob
Modulo  : module
Fonte   : BEWS0002
Objetivo: Integração EndPoints SICOOB
*///#########################################################################################

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

User Function BEWS0002(cOrigem,aDadosEmp,aDadosTit,aBancos,nPOS,aDatSacado,aBolText,aDados,dDtaBx,cDatIni,cDatFim)

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
	Local cCodClie        := ""
	Local cPath           := ""
	Local cToken          := ""
	Local aHeader         := {}
	Local cKey 	          := ""
	Local cCert           := ""
	Local cPostParms      := ""
	Local nTimeOut        := 120
	Local cPswCert        := ""
	Local cHeaderGet      := ""
	Local cPostRet        := ""
	Local lRet            := .F.
	Local nVlrTar         := 0
	Local ntotal          := 0
	Local natual          := 0
	Local nVlrJur         := 0
	Local nTotJur         := 0
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
	cCodClie  := SuperGetMV("BE_CLISICO",.T.,"e24ab947-b2b6-4c55-86fb-2662a014a63b")

	oToken := U_BEWS0001()
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
		oJsonSicoob['seuNumero']                           := aDadosTit[1]
		oJsonSicoob['identificacaoEmissaoBoleto']          := 2
		oJsonSicoob['identificacaoDistribuicaoBoleto']     := 2
		oJsonSicoob['valor']                               := aDadosTit[5]
		oJsonSicoob['dataVencimento']                      := FWTimeStamp(5,stod(aDadosTit[4]),Time())
		oJsonSicoob['dataLimitePagamento']                 := FWTimeStamp(5,stod(aDadosTit[4])+30,Time())
		oJsonSicoob['tipoDesconto']                        := 0
		oJsonSicoob['tipoMulta']                           := 0 //0 - Isento 1 - Valor Fixo 2 - Percentual
		//oJsonSicoob['dataMulta']                           := FWTimeStamp(5,stod(aDadosTit[4])+1,Time())
		//oJsonSicoob['valorMulta']                          := 0.33
		oJsonSicoob['tipoJurosMora']                       := 2 // 1 - Valor por dia 2 - Taxa Mensal 3 - Isento
		oJsonSicoob['dataJurosMora']                       := FWTimeStamp(5,stod(aDadosTit[4])+1,Time())
		oJsonSicoob['valorJurosMora']                      := aBancos[nPOS][7] // buscar na SEE
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
			aDados[13] := cValtoChar(oResponse['resultado'][1]['boleto']['nossoNumero'])
			aDados[38] := oResponse['resultado'][1]['boleto']['qrCode']
			lRet := .T.
		else
			Alert(cPostRet)
		endif

	elseif lExclui

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
		if oResponse['resultado'][1]['status']['codigo'] == 200 .or. (oResponse['resultado'][1]['status']['codigo'] == 400 .and. "processo de baixa" $ oResponse['resultado'][1]['status']['mensagem'])
			FWAlertSuccess("Cancelamento da cobrança do título "+ oResponse['resultado'][1]['boleto']['seuNumero']+", realizado com sucesso!", "Retorno Sicoob-BEWS0002")
			lRet := .T.
			Return lRet
		else
			FWAlertWarning("Falha ao cancelar cobrança!", "Retorno Sicoob-BEWS0002")
			Return lRet
		endif

	elseif lBaixa

		dDatabkp  := dDataBase
		dDataBase := dDtaBx
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
		if valtype(oResponse['resultado']['codigoSolicitacao']) == "N"
			cParams := "numeroContrato=" + cCodConv +"&"
			cParams += "codigoSolicitacao=" + cValtoChart(oResponse['resultado']['codigoSolicitacao'])
			cPostRet := HTTPSGet( cUrl + cPath, cCert, cKey, cPswCert, cParams, nTimeOut, aHeader, @cHeaderGet)
			SLEEP( 20000 )
			oResp:= JsonObject():new()
			oResp:fromJson(FwNoAccent(cPostRet))
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
						cJsonStr := decodeutf8(ReadFile(cDir+cNomeArq+".json"))
						oJson := JSonObject():New()
						if FwJSONDeserialize(cJsonStr,@oJson)
							FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("Inicio baixa API Sicoob!") , 0, 0)
							for nY := 1 to Len(oJson)
								nVlrJur := 0
								lLiq := oJson[nY]['MODALIDADE'] == 1
								cNosso := cValToChar(oJson[nY]['NUMEROTITULO'])
								nRecno := GetChave(cNosso)
								if lLiq .and. nRecno > 0
									dDatMov     := datavalida(StoD(strtran(substr(oJson[nY]['DATALIQUIDACAO'],1,10),'-','')))
									dDatCred    := datavalida(StoD(strtran(substr(oJson[nY]['DATAPREVISAOCREDITO'],1,10),'-','')))
									nValBx      := oJson[nY]['VALORTITULO']
									ntotal      += oJson[nY]['VALORTITULO']
									natual      += oJson[nY]['VALORLIQUIDO']
									if (oJson[nY]['VALORLIQUIDO'] - oJson[nY]['VALORTITULO']) > 0
										nVlrJur := (oJson[nY]['VALORLIQUIDO'] - oJson[nY]['VALORTITULO'])
										nTotJur += nVlrJur
									endif
									if BE02GrBx(nRecno, nValBx, cBcoCNAB, cAgeCNAB, cCtaCNAB,dDatCred,dDatMov,nVlrJur)
										FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("O titulo com o nosso numero "+cNosso+" foi baixado com sucesso!") , 0, 0)
										nVlrTar     += oJson[nY]['VALORTARifAMOVIMENTO']
									else
										FWLogMsg("ERROR", "", "Erro", "BEWS0002", "", "", EncodeUTF8("Erro ao baixar titulo com o nosso numero "+cNosso+"!") , 0, 0)
									endif
								endif
								nRecno := 0
							next nY

							if nVlrTar > 0
								if IncMov(cBcoCNAB,cAgeCNAB,cCtaCNAB,"20831", "P", , , nVlrTar, dDatCred, , , "Movimento tariafa gerado com sucesso!")
									FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("Tarifa gerada com sucesso!") , 0, 0)
								endif
							endif

							FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("Valor total baixa ="+Transform(ntotal ,'@E 999,999,999.99')) , 0, 0)
							FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("Valor total Original ="+Transform(natual ,'@E 999,999,999.99')) , 0, 0)
							FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("Valor total Original ="+Transform(nTotJur,'@E 999,999,999.99')) , 0, 0)
						endif
					endif
				next nZ
			endif
		else
			Alert(FwJSONDeserialize(cPostRet,@oJson))
		endif
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

	if SE1->E1_SALDO > 0

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
		AADD(aVetor,{"AUTBANCO"			, cBcoCNAB				,NIL}) //Banco
		AADD(aVetor,{"AUTAGENCIA"		, PADR(cAgeCNAB,TAMSX3("E1_AGEDEP")[1]),NIL}) //agencia
		AADD(aVetor,{"AUTCONTA"			, PADR(cCtaCNAB,TAMSX3("E1_CONTA")[1]),NIL}) //Conta
		if nVlrJur > 0
			AADD(aVetor,{"AUTJUROS"	    ,nVlrJur                ,Nil })
		endif
		AADD(aVetor,{"AUTVALREC"		, nValBx+nVlrJur		,NIL}) //Valor de pagamento

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
	EndSql
	if (cTMPSE1)->(!Eof())
		nRet := (cTMPSE1)->(R_E_C_N_O_)
	endif
	(cTMPSE1)->(DbCloseArea())
Return(nRet)


/*/{Protheus.doc} ReadFile
Leitura arquivo 
@type function
@version  
@author Igor Guimarães
@since 8/22/2024
@param cFile, character, param_description
@return variant, return_description
/*/
Static Function ReadFile(cFile)

	Local cBuffer := ''
	Local nH , nTam
	nH := Fopen(cFile)
	if nH != -1
		nTam := fSeek(nH,0,2)
		fSeek(nH,0)
		cBuffer := space(nTam)
		fRead(nH,@cBuffer,nTam)
		fClose(nH)
	else
		MsgStop("Falha na abertura do arquivo ["+cFile+"]","FERROR "+cValToChar(Ferror()))
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

	Local aFina100   := {}
	Local nOpc       := 0
	Local cRecPag    := ""
	Local lRet       := .T.

	Default cMoedaSM2  := padr("M1",TamSx3("E5_MOEDA")[1])
	Default nTaxa       := 0
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

	aFina100 := { {"E5_DATA"   , dDataLanc                 , Nil},;
		{"E5_VENCTO" , dDataLanc                 , Nil},;
		{"E5_MOEDA"  , cMoedaSM2                 , Nil},;
		{"E5_VALOR"  , nValorLanc                , Nil},;
		{"E5_NATUREZ", cNatureza                 , Nil},;
		{"E5_BANCO"  , cBanco                    , Nil},;
		{"E5_AGENCIA", cAgenc                    , Nil},;
		{"E5_CONTA"  , cConta                    , Nil},;
		{"E5_TXMOEDA", nTaxa                     , Nil},;
		{"E5_RECPAG" , cRecPag                   , Nil},;
		{"E5_HISTOR" , 'TARifA BANCARIA SICOOB'       , Nil}} //"Lanc entre naturezas"

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
