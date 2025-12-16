/*//#########################################################################################
Projeto : Sicoob
Modulo  : module
Fonte   : BEWS0002
Objetivo: Integração EndPoints SICOOB
*///#########################################################################################
#Include "TopConn.ch"
#include "protheus.ch"
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "RPTDEF.CH"
#INCLUDE "PRTOPDEF.ch"
#Include 'TbiConn.CH'
#INCLUDE "FWPrintSetup.ch"
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
	Local cKey            := ""
	Local cCert           := ""
	Local cPostParms      := ""
	Local nTimeOut        := 200
	Local cPswCert        := ""
	Local cHeaderGet      := ""
	Local cPostRet        := ""
	Local lRet            := .F.
	local nVlrBio         := 0
	local nVlrFup         := 0
	local nVlrChk         := 0
	local cCtaBio         := ""
	local cCtaFup         := ""
	local cCtaChk         := ""
	Local ntotal          := 0
	Local natual          := 0
	Local nVlrJur         := 0
	Local nTotJur         := 0
	Local cNNomArq        := ""
	Local bError          := .F.
	Local mError          := "Erro na liberação do arquivo pelo banco, tente mais tarde."
	Local cPdf            := ""
	Local oFile           As Object
	local aMensagens      := {}
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
	Default cNossoNum     := ""
	//Default cCodClie      := 'e227419d-ce16-43c0-ac2e-a64cea1bd6d5'

	if !lLogin
		RpcSetEnv("01","01","Admin")
	endif

	cNossoNum := STRTRAN(alltrim(cNossoNum),"-","")

	lInclui   := cOrigem == "GER"
	lAlter    := cOrigem == "ALT"
	lExclui   := cOrigem == "EXC"
	lDetalh   := cOrigem == "DET"
	lBaixa    := cOrigem == "BAI"
	lAltLim   := cOrigem == "ALTLIM"
	lSegVia   := cOrigem == "SEGVIA"
	cCodConv  := AllTrim( aBancos[nPOS][8])
	cBcoCNAB  := aBancos[nPOS][1]//PADR(AllTrim( SuperGETMV( "BE_BCSICOB",, "756" )),TAMSX3("A6_COD")[1])
	cAgeCNAB  := PADR(Alltrim(aBancos[nPOS][10]),TAMSX3("A6_AGENCIA")[1])//PADR(AllTrim( SuperGETMV( "BE_AGSICOB",, "4108" )),TAMSX3("A6_AGENCIA")[1])
	cCtaCNAB  := PADR(Alltrim(aBancos[nPOS][7]),TAMSX3("A6_NUMCON")[1])//PADR(AllTrim( SuperGETMV( "BE_CCSICOB",, "84298" )),TAMSX3("A6_NUMCON")[1])
	cKey      := SuperGetMV("BE_CHVKEY",.T.,"\certs\000002_key.pem")
	cCert     := SuperGetMV("BE_CHVCER",.T.,"\certs\000002_cert.pem")
	cPswCert  := GETMV("BE_PSWSICO")
	//cURL      := SuperGetMV("BE_URLSICO",.T.,"https://api.sicoob.com.br/cobranca-bancaria/v2")
	cURL      := SuperGetMV("BE_URLSICO",.T.,"https://api.sicoob.com.br/cobranca-bancaria/v3")


	oToken := U_BEWS0001(cCodClie)
	cToken := oToken['token_type']+space(1)+oToken['access_token']

	Aadd(aHeader, 'Authorization: ' + cToken )
	Aadd(aHeader,'Content-Type: application/json')
	Aadd(aHeader,'Charset: UTF-8')
	Aadd(aHeader,'client_id: '+cCodClie)

	if lInclui
		dDataEmissao :=  FormataData(dDataBase)
		dDataVencimento := FormataData(stod(aDadosTit[4]))
		dDataLimitePagamento := FormataData(stod(aDadosTit[4])+aBancos[nPOS][17])
		dDataMulta := FormataData (stod(aDadosTit[4])+1)
		dDataJurosMora := FormataData (stod(aDadosTit[4])+1)

		oJsonSicoob :=  JsonObject():New()
		oJsonSicoob['numeroCliente']                      := cCodConv
		oJsonSicoob['codigoModalidade']                          := 1
		oJsonSicoob['numeroContaCorrente']                 := val(cCtaCNAB)
		oJsonSicoob['codigoEspecieDocumento']                    := "DM"
		oJsonSicoob['dataEmissao']                         := dDataEmissao
		//      oJsonSicoob['nossoNumero']                         := cNossoNum
		oJsonSicoob['seuNumero']                           := aDadosTit[1]
		oJsonSicoob['identificacaoEmissaoBoleto']          := 2
		oJsonSicoob['identificacaoDistribuicaoBoleto']     := 2
		oJsonSicoob['valor']                               := aDadosTit[5]
		oJsonSicoob['dataVencimento']                      := dDataVencimento
		oJsonSicoob['dataLimitePagamento']                 := dDataLimitePagamento
		oJsonSicoob['tipoDesconto']                        := 0
		oJsonSicoob['tipoMulta']                           := 2 //0 - Isento 1 - Valor Fixo 2 - Percentual
		oJsonSicoob['dataMulta']                           := dDataMulta
		oJsonSicoob['valorMulta']                          := aBancos[nPOS][15] // buscar na SEE
		oJsonSicoob['tipoJurosMora']                       := 2 // 1 - Valor por dia 2 - Taxa Mensal 3 - Isento
		oJsonSicoob['dataJurosMora']                       := dDataJurosMora
		oJsonSicoob['valorJurosMora']                      := aBancos[nPOS][15] // buscar na SEE
		oJsonSicoob['numeroParcela']                       := 1
		oJsonSicoob['codigoNegativacao']                   := 3
		oJsonSicoob['numeroDiasNegativacao']               := 60
		oJsonSicoob['codigoProtesto']                      := 3
		oJsonSicoob['numeroDiasProtesto']                  := 30
		oJsonSicoob['gerarPdf']                            := .F.
		oJsonSicoob['aceite']                              := .T.
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

		// Inicializa o array de mensagens de instrução
		oJsonSicoob['mensagensInstrucao'] := {}

        /** Mensagem 2 e 3 sempre vão retornar apenas uma mensagem ******/
		IIF(!Empty(aDados[39]), Aadd(aMensagens,aDados[39]),) // Msg 01
		IIF(!Empty(aDados[40]), Aadd(aMensagens,aDados[40]),) // Msg 01
        /****************************************************************/


		IIF(!Empty(aDados[41]), Aadd(aMensagens,aDados[41]),) // Msg 02
		IIF(!Empty(aDados[42]), Aadd(aMensagens,aDados[42]),) // Msg 03
		IIF(!Empty(aDados[43]), Aadd(aMensagens,aDados[43]),) // Msg 04

		// Saber se posso adicionar uma mensagens adicional
		// Máximo permitido pelo Sicoob é 5 mensagens

		IF Len(aMensagens) < 4
			IIF(!Empty(aDados[29]), Aadd(aMensagens,aDados[29]),) // Msg 04 / Msg Adicional
		ENDIF

		// A pedido do Financeiro essa mensagem sempre deverá ser a última
		IIF(!Empty(aDados[28]), Aadd(aMensagens,aDados[28]),) // Msg 05

		// Adicionando as mensagens diretamente no array
		oJsonSicoob['mensagensInstrucao'] := aMensagens


		cPath  := "/boletos"

		cBody := EncodeUTF8(oJsonSicoob:ToJson())
		cPostRet := HTTPSPost( cUrl + cPath, cCert, cKey, cPswCert, cPostParms, cBody, nTimeOut, aHeader, @cHeaderGet)

		oResponse := JsonObject():new()
		oResponse:fromJson(FwNoAccent(cPostRet))

		if oResponse['resultado']:hasProperty('nossoNumero')
			aDados[2]  := cValtoChar(oResponse['resultado']['codigoBarras'])
			aDados[3]  := cValtoChar(oResponse['resultado']['linhaDigitavel'])
			aDados[13] := substr(padl(cValtoChar(oResponse['resultado']['nossoNumero']),8,"0"),1,7)+"-"+right(cValtoChar(oResponse['resultado']['nossoNumero']),1)
			aDados[38] := oResponse['resultado']['qrCode']
			lRet := .T.
		else
			cMsg := '<font color="#0F0F00" size="4">Falha ao tentar registrar boleto </font>'
			cMsg += '<br>Pagador:' + Alltrim(aDatSacado[1])
			cMsg += '<br>Valor:' + cValToChar(aDadosTit[5])
			cMsg += '<font color="#AD2121" size="4">Tente novamente mais tarde!</font>'

			FWAlertWarning("Falha ao Registrar Boleto " + cMsg , "Retorno Sicoob - BEWS0002")
		endif

	elseif lAlter

		nRecno := aDadosTit[9]
		oJsonSicoob :=  JsonObject():New()
		oJsonSicoob['numeroCliente']                            := cCodConv
		oJsonSicoob['codigoModalidade']                         := 1
		oJsonSicoob['prorrogacaoVencimento']                    := JsonObject():new()
		oJsonSicoob['prorrogacaoVencimento']['dataVencimento']  := FormataDAta(aDadosTit[4])


		cPath  := "/boletos/"
		cBody := EncodeUTF8(oJsonSicoob:ToJson())
		cResponse := HTTPSQuote( cURL+cPath + cNossoNum, cCert, cKey, cPswCert , "PATCH", "", cBody, 120, aClone(aHeader), @cHeaderGet )

		oResponse := JsonObject():new()
		oResponse:fromJson(FwNoAccent(cResponse))

		if oResponse:hasProperty('mensagens')
			cMensagem := EncodeUTF8(oResponse['mensagens'][1]['mensagem'])
			lRet := .F.
		elseif oResponse:hasProperty('httpCode')
			cMensagem := "Título não encontrando no banco."
			lRet := .F.
		else
			cMensagem := ""
			lRet := .T.
		endif
		if len(cMensagem)<>0
			cMsg := '<font color="#0F0F00" size="4">Alteração da data de vencimento  do título '+ cNossoNum +'!</font>'
			cMsg += '<br>'
			cMsg += '<font color="#AD2121" size="4">'+ cValToChar(cMensagem) +'!</font>'
			FWAlertWarning(cMsg, "Retorno Sicoob-BEWS0002")
		endif


		//consultando novamente o boleto para atualizar os dados.
		if lRet
			cPath  := "/boletos/segunda-via"
			cResponse := HTTPSGet(  cUrl + cPath + '?numeroCliente='+ cValtoChar(cCodConv) + '&codigoModalidade=1&nossoNumero=' +  cValtoChar(cNossoNum) +  '&numeroContratoCobranca=' + '284410', cCert, cKey, cPswCert, "", nTimeOut, aHeader, @cHeaderGet)
			oResponse:= JsonObject():new()
			oResponse:fromJson(FwNoAccent(cResponse))

			dbSelectArea( "SE1" )
			SE1->(DbGoTo(nRecno))

			aDados[2]  := cValtoChar(oResponse['resultado']['codigoBarras'])
			aDados[3]  := cValtoChar(oResponse['resultado']['linhaDigitavel'])
			aDados[38] := cValtoChar(oResponse['resultado']['qrCode'])

			RecLock("SE1",.F.)
			SE1->E1_XQRCODE := cValtoChar(oResponse['resultado']['qrCode'])
			SE1->E1_CODBAR  := cValtoChar(oResponse['resultado']['codigoBarras'])
			SE1->E1_CODDIG  := cValtoChar(oResponse['resultado']['linhaDigitavel'])
			SE1->(MsUnlock())

			cMsg := '<font color="#0F0F00" size="4">Alteração realizada com sucesso!</font>'
			cMsg += '<br>'
			cMsg += '<font color="#AD2121" size="4">'+ EncodeUTF8(oResponse['resultado']['dataVencimento'])  +'</font>'

			FWAlertSuccess(cMsg, "Retorno Sicoob-BEWS0002")
			FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", "Data Vencimento Alterada: " + EncodeUTF8(oResponse['resultado']['dataVencimento']) , 0, 0)
			lRet := .T.
		endif
		freeObj(oResponse)

	elseif lAltLim

		oJsonSicoob :=  JsonObject():New()
		oJsonSicoob['numeroCliente']                      := cCodConv
		oJsonSicoob['codigoModalidade']                          := 1
		oJsonSicoob['nossoNumero']                         := cNossoNum
		oJsonSicoob['dataLimitePagamento']                 := FWTimeStamp(5,stod(aDadosTit[4])+aBancos[nPOS][17],Time())


		cPath  := "/boletos/prorrogacoes/data-limite-pagamento"
		cBody := EncodeUTF8(oJsonSicoob:ToJson())
		cResponse := HTTPQuote( cURL+cPath, "PATCH", "", "["+cBody+"]", 120, aClone(aHeader), @cHeaderGet )
		oResponse := JsonObject():new()
		oResponse:fromJson(FwNoAccent(cResponse))
		if oResponse['resultado'][1]['status']['codigo'] == 200 .or. (oResponse['resultado'][1]['status']['codigo'] == 400 )
			freeObj(oJsonSicoob)
			IF oResponse['resultado'][1]['status']['codigo']  == 400
				FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", "Data limite não alterada, Nosso Número:  " +cNossoNum +"  "+ EncodeUTF8(oResponse['resultado'][1]['status']['mensagem']) , 0, 0)
			ELSEIF oResponse['resultado'][1]['status']['codigo']  == 200
				FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", "Data limite alterada, Nosso Número:  " +cNossoNum +"  "+EncodeUTF8(oResponse['resultado'][1]['prorrogacao']['dataLimitePagamento']) , 0, 0)
			ENDIF

		else
			FWAlertWarning("Falha ao alterar data limite! "+ oResponse['resultado'][1]['status']['mensagem'], "Retorno Sicoob-BEWS0002")
		endif
		lRet := .T.
		freeObj(oResponse)

	elseif lExclui
		cNossoNum := STRTRAN(alltrim(SE1->E1_NOSNUM),"-","")
		cPath  := "/boletos/"
		nRecno := aDados[3]
		dbSelectArea( "SE1" )
		SE1->(DbGoTo(nRecno))
		oJsonSicoob :=  JsonObject():New()
		oJsonSicoob['numeroCliente']  := val(cCodConv)
		oJsonSicoob['codigoModalidade']      := 1

		cBody := EncodeUTF8(oJsonSicoob:ToJson())
		cResponse := HTTPSPost( cUrl + cPath + cValtoChar(val(cNossoNum)) + '/baixar', cCert, cKey, cPswCert, cPostParms, cBody, 120 , aHeader, @cHeaderGet)
		oResponse := JsonObject():new()
		oResponse:fromJson(FwNoAccent(cResponse))

		if oResponse:hasProperty('mensagens')
			if oResponse['mensagens'][1]:hasProperty('mensagem')
				if oResponse['mensagens'][1]['codigo']=='5002'
					cMsg := '<font color="#0F0F00" size="4">Falha no cancelamento do título '+ cValtoChar(val(strtran(SE1->E1_NOSNUM,"-",""))) +'!</font>'
					cMsg += '<br>'
					cMsg += '<font color="#AD2121" size="4">'+	oResponse['mensagens'][1]['mensagem'] +'!</font>'
					FWAlertWarning(cMsg, "Retorno Sicoob-BEWS0002")
					lRet := .F.
				endif
			endif
		else
			cMsg := '<font color="#0F0F00" size="4">Cancelamento da cobrança do título '+ cValtoChar(val(strtran(SE1->E1_NOSNUM,"-",""))) +',  realizado com sucesso!</font>'
			cMsg += '<br>'
			cMsg += '<font color="#21df21ff" size="4"></font>'
			FWAlertSucess(cMsg, "Retorno Sicoob-BEWS0002")
			lRet := .T.

		endif


	elseif lBaixa

		cNNomArq  := "liqui_"+cDatIni+"_"+Alltrim(cAgeCNAB)+"_"+Alltrim(cCtaCNAB)
		dDatabkp  := dDataBase
		dDataBase := dDtaBx
		dDataNova:= substr(FormDate(dDataBase),7,4) + "-" + substr(FormDate(dDataBase),4,2) + "-" + substr(FormDate(dDataBase),1,2)
		cPath     := "/boletos/movimentacoes"
		oFile     := FWFileWriter():New("\TMP\"+cNNomArq+".json", .T.)
		If !oFile:Exists()
			oJsonSicoob :=  JsonObject():New()
			oJsonSicoob['numeroCliente']                  := val(cCodConv)
			oJsonSicoob['tipoMovimento']                   := 5
			oJsonSicoob['dataInicial']                     := dDataNova
			oJsonSicoob['dataFinal']                       := dDataNova

			cBody := EncodeUTF8(oJsonSicoob:ToJson())
			cPostRet := HTTPSPost( cUrl + cPath, cCert, cKey, cPswCert, cPostParms, cBody, nTimeOut, aHeader, @cHeaderGet)
			oResponse := JsonObject():new()
			oResponse:fromJson(FwNoAccent(cPostRet))
			//Pausa o processamento por 5 segundos
			sleep( 5000 )
			if valtype(oResponse) =='J'
				if valtype(oResponse['resultado']['codigoSolicitacao']) == "N"
					cParams := "numeroCliente=" + cCodConv +"&"
					cParams += "codigoSolicitacao=" + cValtoChart(oResponse['resultado']['codigoSolicitacao'])
					cPostRet := HTTPSGet( cUrl + cPath, cCert, cKey, cPswCert, cParams, nTimeOut, aHeader, @cHeaderGet)
					oResp:= JsonObject():new()
					oResp:fromJson(FwNoAccent(cPostRet))

					if !valtype(oResp['mensagens']) =="A"
						cPath := "/boletos/movimentacoes/download"
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
							else
								bError := .T.
							endif
						next nZ
					Else
						bError := .T.
					EndIf
				else
					bError := .T.
				endif
			else
				bError := .T.
			endif
		endif

		oFile:Close()
		cJsonStr := decodeutf8(ReadFile(cDir+cNNomArq+".json", cDatFim, mError))
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
			if cValToChar(oJson[nY]['numeroTitulo'])=='181448'
				Alert('doi')
			endif
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
		FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("Valor total baixa ="+Transform(ntotal ,'@E 999,999,999.99')) , 0, 0)
		FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("Valor total Original ="+Transform(natual ,'@E 999,999,999.99')) , 0, 0)
		FWLogMsg("INFO", "", "Sucesso", "BEWS0002", "", "", EncodeUTF8("Valor total Original ="+Transform(nTotJur,'@E 999,999,999.99')) , 0, 0)


		dDataBase := dDatabkp
	elseif lSegVia

		cPath  := "/boletos/segunda-via"
		cParams := "numeroCliente=" + cCodConv +"&"
		cParams += "codigoModalidade=1&"
		cParams += "nossoNumero="+cNossoNum+"&"
		cParams += "gerarPdf=true"
		cPostRet := HTTPSGet( cUrl + cPath, cCert, cKey, cPswCert, cParams, nTimeOut, aHeader, @cHeaderGet)

		IF !Empty(cPostRet)
			oResp:= JsonObject():new()
			oResp:fromJson(FwNoAccent(cPostRet))

			cPdf := oResp['resultado']['pdfBoleto']
			lRet := .T.
			freeObj(oResp)
			Return cPdf
		ELSE
			cPdf := "Boleto jah foi pago ou registrado com erro!"
			Return cPdf
		ENDIF

	endif
	if bError
		cMsgErr := "<br>Infelizmente, a baixa referente ao dia   <b>" + DTOC(STOD(cDatFim)) + "</b> apresentou um erro. "
		mError := cMsgErr + "<br> End Point: " + cPath + "<br>"
		if valtype(oResponse) =='J'
			mError  += "<br> Mensagem: " + (oResponse['resultado']['mensagem']) + "<br>"
		else
			mError  += "<br>Retorno em branco, aquarde a próxima execução <br>"
		end if
		U_EnviaEmail("Erro na Baixa Automática", cMsgErr, "alesssandro.magno@bioextratus.com.br", "", "")
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
	Local cFunName       := FunName()
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
		AADD(aVetor,{"E1_PREFIXO"       , SE1->E1_PREFIXO       ,Nil})
		AADD(aVetor,{"E1_NUM"           , SE1->E1_NUM           ,Nil})
		AADD(aVetor,{"E1_PARCELA"       , SE1->E1_PARCELA       ,Nil})
		AADD(aVetor,{"E1_TIPO"          , SE1->E1_TIPO          ,Nil})
		AADD(aVetor,{"E1_CLIENTE"       , SE1->E1_CLIENTE       ,Nil})
		AADD(aVetor,{"E1_LOJA"          , SE1->E1_LOJA          ,Nil})
		AADD(aVetor,{"E1_MOEDA"         , SE1->E1_MOEDA         ,Nil})
		AADD(aVetor,{"AUTMOTBX"         , "NOR"                 ,Nil})
		AADD(aVetor,{"AUTDTBAIXA"       , dDatMov               ,Nil})
		AADD(aVetor,{"AUTDTCREDITO"     , dDatCred              ,Nil})
		AADD(aVetor,{"AUTHIST"          , OemToAnsi("Baixa API Sicoob") ,Nil})
		AADD(aVetor,{"AUTBANCO"         , SE1->E1_PORTADO       ,NIL}) //Banco
		AADD(aVetor,{"AUTAGENCIA"       , SE1->E1_AGEDEP        ,NIL}) //agencia
		AADD(aVetor,{"AUTCONTA"         , SE1->E1_CONTA         ,NIL}) //Conta
		if nVlrJur > 0
			AADD(aVetor,{"AUTJUROS"     ,nVlrJur                ,Nil })
		endif
		AADD(aVetor,{"AUTVALREC"        , nValBx+nVlrJur        ,NIL}) //Valor de pagamento
		AADD( aVetor, { "AUTMULTA"      , nMulta                        , Nil } )

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
Static Function ReadFile(cFile, cDatFim, mError)

	Local cBuffer := ''
	Local nH , nTam
	local cParaErro:=  GetMv("MV_XXWFFIN")
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
		cMsgErr += "<br>" + mError + "<br>"
		cMsgErr += "Nome do Arquivo: "+ cFile + "<br><br>"
		if cDatFim == DTOS(DataValida(cDatFim))
			U_BIOPADEM(cParaErro, "[BAIXAS AUTOMÁTICAS] - Erro na Baixa Automática: ", cMsgErr, "" , , )
		end if//        MsgStop("Falha na abertura do arquivo ["+cFile+"]","FERROR "+cValToChar(Ferror()))
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
		{"E5_CONTA"  , cConta                    , Nil},;
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

Static Function FormataData(cData)
	local nRet := ''
	nRet := substr(FormDate(cData),7,4) + "-" + substr(FormDate(cData),4,2) + "-" + substr(FormDate(cData),1,2)
return nRet

Static Function AcertaAcento(cMensagem)
	// String original com caracteres especiais
	cString := cMensagem
	// Substituindo os caracteres especiais
	cString := StrTran(cString, "­", "")
	cString := StrTran(cString, "¡", "á")
	cString := StrTran(cString, "A", "Á")
	// Exibindo a string corrigida

return cString
