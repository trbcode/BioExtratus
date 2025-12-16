
#Include "TopConn.ch"
#include "protheus.ch"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
/*/{Protheus.doc} F040ALT
O ponto de entrada F040ALT valida os dados da alteraï¿½ï¿½o apos a confirmaï¿½ï¿½o da mesma.

@type function
@version  
@author iglal
@since 10/2/2024
@return variant, return_description
/*/
user function FA040ALT()

	Local lRet        := .T.
	Local aBancos     := {}
	Local aDados[38]            //Array usado para receber os dados do boleto atual
	Local aDadosTit   := {}
	Local cBcoCNAB    := SE1->E1_PORTADO
	Local cAgeCNAB    := SE1->E1_AGEDEP
	Local cCtaCNAB    := SE1->E1_CONTA
	Local nPOS        := 1
	Local cIDClient   := "" // o ideal ï¿½ criar um campo na tabela SEE para guardar o Id_client 0735841c-a2c7-411d-96e3-5361c5090d77
	//Local cMsg        := ""
	Local nVlrAbat    := SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",1,,SE1->E1_CLIENTE,SE1->E1_LOJA)
	Local nValorReal  := (SE1->E1_SALDO-nVlrAbat+ SE1->E1_ACRESC - SE1->E1_DECRESC)
	Local cFilePrint  := ""
	Local oBancoBB    as object
	Local oPrn        as object
	Local lSucess 		:= .F.
	Local dVencRea    := M->E1_VENCREA
	Local cIndNovaDataVenc := "S"

	if NOLDVENREA <> M->E1_VENCREA

		if SE1->E1_PORTADO == "001" //Banco do Brasil
			U_IntegBB(@oBancoBB, cBcoCNAB, cAgeCNAB, cCtaCNAB)

			lSucess := oBancoBB:alteraboletos(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO, cIndNovaDataVenc, dVencRea)
			IF lSucess
				lSucess := oBancoBB:consultaBoleto(Alltrim(SE1->E1_NUMBCO))
				IF lSucess
					FwAlertSuccess("Título Alterado com sucesso!", "F040ALT - BB")
					FwFreeObj(oPrn)
				ENDIF
			ELSE
				IF AttIsMemberOf(oBancoBB:cResult,"errors")
					FwAlertError("Erro ao alterar o título: " + DecodeUTF8(oBancoBB:CRESULT:ERRORS[1]['MESSAGE']), "F040ALT - BB")
				ELSE
					FwAlertError("Erro ao alterar o título no Banco do Brasil.", "F040ALT - BB")
				ENDIF
				//cMsg := '<font color="#0F0F00" size="3">Deseja continuar a alteração do título mesmo sem sucesso na alteração no Banco do Brasil?</font>'
				//cMsg += '<br><br>'
				//cMsg += '<font color="#AD2121" size="4">Falha na alteração do título!</font>'
				//if FWAlertYesNo(cMsg, "F040ALT - Atenção!")
				//	lRet := .T.
				//else
				//	lRet := .F.
				//endif
				lRet := .F.
			ENDIF
		elseif SE1->E1_PORTADO == "756" //Sicoob

			cIDClient := u_getIdClientSicoob(alltrim(cBcoCNAB), alltrim(cAgeCNAB), alltrim(cCtaCNAB))

			AADD(aBancos, { "756","SICOOB","756.bmp","756-0",,,,,,,,"",,,,})    //Sicoob
			//Buscando parï¿½metros de banco  e atualizando o array de bancos
			dbSelectArea("SEE")
			dbSetOrder(1)   // EE_FILIAL  	+ EE_CODIGO + EE_AGENCIA + EE_CONTA +   EE_SUBCTA
			dbSeek( XFILIAL("SEE")	+ cBcoCNAB    + cAgeCNAB   + cCtaCNAB   +  '001',     .T.)

			nDvAgencia      	:=  alltrim(SEE->EE_DVAGE)
			NDvConta        	:=  alltrim(SEE->EE_DVCTA)
			cCodced		  		:=  alltrim(cCtaCNAB) + NdvConta
			cCodEmp         	:=  alltrim(SEE->EE_CODEMP)
			cFaixaAtu       	:=  alltrim(SEE->EE_FAXATU)
			cFaixaFim       	:=  alltrim(SEE->EE_FAXFIM)
			cCarteira       	:=  alltrim(SEE->EE_XXCARTE)
			cMens1          	:=  alltrim(SEE->EE_XXMENS1)
			cJuros          	:=  SEE->EE_XXTXJUR
			cJurDia         	:=  SEE->EE_XXTXJDI

			aBancos[nPOS][5]	:=  alltrim(SEE->EE_DVAGE)
			aBancos[nPOS][6]    :=  alltrim(SEE->EE_DVCTA)
			aBancos[nPOS][7]    :=  alltrim(cCtaCNAB) + alltrim(SEE->EE_DVCTA)
			aBancos[nPOS][8]    :=  alltrim(SEE->EE_CODEMP)
			aBancos[nPOS][9]    :=  cCtaCNAB
			aBancos[nPOS][10]   :=  cAgeCNAB
			aBancos[nPOS][12]   :=  alltrim(SEE->EE_XXCARTE)
			aBancos[nPOS][13]   :=  alltrim(SEE->EE_FAXFIM)
			aBancos[nPOS][15]   :=  SEE->EE_XXTXJUR
			aBancos[nPOS][16]   :=  SEE->EE_XXTXJDI
			SEE->(DbCloseArea())

			aDadosTit   := {AllTrim(SE1->E1_NUM)+AllTrim(SE1->E1_PARCELA)   ,;  // [1] Nï¿½mero do tï¿½tulo
			SE1->E1_EMISSAO                                                 ,;  // [2] Data da emissï¿½o do tï¿½tulo
			dDataBase                                                       ,;  // [3] Data da emissï¿½o do boleto
			M->E1_VENCREA                                                 ,;  // [4] Data do vencimento
			nValorReal                                                      ,;  // [5] Valor do tï¿½tulo
			STRTRAN(alltrim(SE1->E1_NOSNUM),"-","")                         ,;  // [6] Nosso nï¿½mero (Ver fï¿½rmula para calculo)
			SE1->E1_PREFIXO                                                 ,;  // [7] Prefixo da NF
			SE1->E1_TIPO                                                    ,;  // [8] Tipo do Titulo
			SE1->(Recno()) }                                                   // [9] Recno                                                    // [8] Tipo do Titulo


			IF U_BEWS0002("ALT",,aDadosTit,aBancos,nPOS,,,@aDados,,,,cIDClient,STRTRAN(alltrim(SE1->E1_NOSNUM),"-",""))

				dbSelectArea("SA1")
				dbSetOrder(1)  // A1_FILIAL   +A1_COD          +A1_LOJA
				dbSeek(  xFilial("SA1")+SE1->E1_CLIENTE +SE1->E1_LOJA, .T.)

				cNomeCli :=  alltrim(SA1->A1_NOME)
				cCGCCli  :=  If(SA1->A1_TIPO=="F",Transform(SA1->A1_CGC, "@R 999.999.999-99"),Transform(SA1->A1_CGC, "@R 99.999.999/9999-99"))
				cSacado  :=  cNomeCli + "   " + " CPF/CPNJ: " + cCGCCli
				cEndSac  :=  ALLTRIM(SA1->A1_END) + "," + ALLTRIM(SA1->A1_BAIRRO)
				cEndSac1 :=  TRANSFORM(SA1->A1_CEP,"@R 99999-999") + " - " + ALLTRIM(SA1->A1_MUN) + " - " + SA1->A1_EST

				//Buscando dados do cedente   - busca da tabela de empresas SM0
				cNomeCed	:= SUBS (SM0->M0_NOMECOM,1,35) +  "  CNPJ: " + TRANSFORM(SM0->M0_CGC, "@R 99.999.999/9999-99")
				cEndCed		:= alltrim(SM0->M0_ENDCOB) + ' , ' + alltrim(SM0->M0_BAIRCOB) + ' , ' + alltrim(SM0->M0_CIDCOB);
					+ ' - ' + alltrim(SM0->M0_ESTCOB) + ', Cep: ' + TRansform(SM0->M0_CEPCOB, "@R 99999-999")

				aDados[1] := aBancos[nPOS][3]
				aDados[4] := 'Pague preferencialmente no SICOOB.'  			// Local de pagamento
				aDados[5] := substr(dtos(M->E1_VENCREA),7,2)+"/"+substr(dtos(M->E1_VENCREA),5,2)+"/"+substr(dtos(M->E1_VENCREA),1,4)	//Vencimento
				aDados[6] :=  cNomeCed                                     //Nome do Cedente
				aDados[7] :=  aBancos[nPOS][10] + "/" + aBancos[nPOS][8]   //Agencia / Codigo Convï¿½nio
				aDados[8] := substr(dtos(SE1->E1_EMISSAO),7,2)+"/"+substr(dtos(SE1->E1_EMISSAO),5,2)+"/"+substr(dtos(SE1->E1_EMISSAO),1,4)	//Data de Emissao
				aDados[9] := SE1->E1_IDCNAB
				aDados[10]:= 'DM' 	//Especie - tipo de documento que originou o boleto (ex: DM, DS, NP) //VERIFICAR
				aDados[11]:= "S"
				aDados[12]:= DTOC(dDatabase)
				aDados[13] := Alltrim(SE1->E1_NOSNUM)
				aDados[14]:= aBancos[nPOS][12]
				aDados[15]:= "REAL"                             //Moeda/espï¿½cie
				aDados[16]:= ""                                 //Quantidade de moeda variï¿½vel
				aDados[17]:= TRANSF(nValorReal,"@E 999,999.99")	//Valor do Tï¿½tulo    (calculado - descrescimos + acrescimentos - abatimentos)
				aDados[13] := Alltrim(SE1->E1_NOSNUM)
				aDados[18]:=  ""                                //Instruï¿½ï¿½es  //Verificar
				aDados[19]:=  ""                                //Desconto / Abatimento		//Nï¿½o preencher

				//Linha G do Boleto
				aDados[20]:=  ""                                //Juros / Multa             //Nï¿½o preencher

				//Linha H do Boleto
				aDados[21]:=  nValorReal                       //Valor Cobrado              //Nï¿½o preencher

				//Linha I do Boleto
				aDados[22]:= cSacado                          //Sacado (Nome, CNPJ)
				aDados[23]:= cEndSac                          //Endereï¿½o
				aDados[24]:= cEndSac1                         //CEP - CIDADE - MUNICIPIO - ESTADO
				aDados[25]:= cNomeCli                         //Sacado
				aDados[26]:= cEndCed                          //Endereï¿½o do Cedente

				//Tratando as mensagem  da SEE
				aDados[28]:= cMens1                           //Mensagem 1

				// Informa dados da NF no boleto
				if (alltrim(SE1->E1_PARCELA)='')
					aDados[29] := "PAGAMENTO REFERENTE A " + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA + SE1->E1_TIPO          //Numero do documento
				else
					aDados[29] := "PAGAMENTO REFERENTE A " + SE1->E1_PREFIXO + SE1->E1_NUM + "/" +  SE1->E1_PARCELA + SE1->E1_TIPO   //Numero do documento
				endif

				aDados[30]:= ""
				//Tratando Juros / Desconto /Multa - Mensagens
				IF cJuros > 0
					xValJurMes := cJuros/100				//juros Mes
					aDados[31] := xValJurMes				//Valor dos Juros
				ENDIF

				If cJurDia > 0
					xValJurDIa := (cJurDia/100)				//Juros dia
					aDados[32] := xValJurDIa				//Valor diï¿½rio da Multa
				endif

				aDados[33]   := SE1->E1_DESCFIN/100			//Valor do Desconto
				aDados[34]   := SE1->E1_DECRESC				//Valor do Desconto COM ncc
				aDados[35]   := 0   						// VALOR DO NCC

				If EMPTY(cFilePrint)
					cFilePrint := "BOL_" + Alltrim(SE1->E1_PREFIXO)+"_" + Alltrim(SE1->E1_NUM) + Alltrim(SE1->E1_PARCELA) + Alltrim(SE1->E1_TIPO)  + "_" + AllTrim(SE1->E1_CLIENTE) + "_" + AllTrim(SE1->E1_LOJA)
				EndIf
				oPrn := FWMSPrinter():New(cFilePrint + ".PDF",IMP_PDF,.T.,,.T.)

				oPrn:StartPage()

				u_printBolet(aDados, aBancos, nPOS, oPrn,cBcoCNAB)

				oPrn:EndPage()
				oPrn:Preview()

			ELSE
				lRet := .F.
			EndIF
		endif
	endif
return lRet
