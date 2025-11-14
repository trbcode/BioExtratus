
#Include "TopConn.ch"
#include "totvs.ch"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
/*/{Protheus.doc} F040ALT
O ponto de entrada F040ALT valida os dados da altera��o apos a confirma��o da mesma.

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
	Local cCodClie    := "e24ab947-b2b6-4c55-86fb-2662a014a63b" // o ideal � criar um campo na tabela SEE para guardar o Id_client
	Local nVlrAbat    := SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",1,,SE1->E1_CLIENTE,SE1->E1_LOJA)
	Local nValorReal  := (SE1->E1_SALDO-nVlrAbat+ SE1->E1_ACRESC - SE1->E1_DECRESC)
	Local cFilePrint  := ""
	Local cArqBs64    := ""
	Local nI
	Local lEspera 	 := .t.
	Local cPath 	   := GetTempPath() + "totvsprinter\"
	Local oBancoBB    as object
	Local oPrn        as object
	Local lSucess 		:= .F.

	if NOLDVENREA <> M->E1_VENCREA

		if SE1->E1_PORTADO == "001" //Banco do Brasil
			U_IntegBB(@oBancoBB, cBcoCNAB, cAgeCNAB, cCtaCNAB)

			lSucess := oBancoBB:alteraboletos(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,M->E1_VENCREA)
			IF lSucess
				lSucess := oBancoBB:consultaBoleto(Alltrim(SE1->E1_NUMBCO))
				IF lSucess
					cFilePrint := "BOL_" + Alltrim(SE1->E1_PREFIXO)+"_" + Alltrim(SE1->E1_NUM) + Alltrim(SE1->E1_PARCELA) + Alltrim(SE1->E1_TIPO)  + "_" + AllTrim(SE1->E1_CLIENTE) + "_" + AllTrim(SE1->E1_LOJA)
					oPrn := FWMSPrinter():New(cFilePrint + ".PDF",IMP_PDF,.T.,,.T.)
					oPrn:SetViewPDF(.F.)
					oBancoBB:imprimeboletos(SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA, SE1->E1_TIPO, oPrn)
					oPrn:Print()
					lEspera := u_ChecaFile( cPath + cFilePrint + ".pdf")

					while lEspera
						sleep(500)
						nI++
						lEspera := u_ChecaFile( cPath + cFilePrint + ".pdf")
						if nI > 60
							lEspera := .F.
						endif
					enddo

					if nI <= 60
						cArqBs64 := U_FileTo64(cPath + cFilePrint + ".pdf")
						SE1->(DbSetorder(1))
						SE1->(DbSeek( xFilial("SE1") + (cTMPSE1)->E1_PREFIXO + (cTMPSE1)->E1_NUM + (cTMPSE1)->E1_PARCELA + (cTMPSE1)->E1_TIPO ))
						RecLock("SE1",.F.)
						Replace SE1->E1_XXBOIMP  with "S"
						SE1->(DbUnlock())
					endif
					FwFreeObj(oPrn)
				ENDIF
			ENDIF

		elseif SE1->E1_PORTADO == "756" //Sicoob

			AADD(aBancos, { "756","SICOOB","756.bmp","756-0",,,,,,,,"",,,,})    //Sicoob
			//Buscando par�metros de banco  e atualizando o array de bancos
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

			aDadosTit   := {AllTrim(SE1->E1_NUM)+AllTrim(SE1->E1_PARCELA)   ,;  // [1] N�mero do t�tulo
			SE1->E1_EMISSAO                                                 ,;  // [2] Data da emiss�o do t�tulo
			dDataBase                                                       ,;  // [3] Data da emiss�o do boleto
			M->E1_VENCREA                                                 ,;  // [4] Data do vencimento
			nValorReal                                                      ,;  // [5] Valor do t�tulo
			STRTRAN(alltrim(SE1->E1_NOSNUM),"-","")                         ,;  // [6] Nosso n�mero (Ver f�rmula para calculo)
			SE1->E1_PREFIXO                                                 ,;  // [7] Prefixo da NF
			SE1->E1_TIPO                                                    ,;  // [8] Tipo do Titulo
			SE1->(Recno()) }                                                   // [9] Recno                                                    // [8] Tipo do Titulo


			IF U_BEWS0002("ALT",,aDadosTit,aBancos,nPOS,,,@aDados,,,,cCodClie,STRTRAN(alltrim(SE1->E1_NOSNUM),"-",""))

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
				aDados[7] :=  aBancos[nPOS][10] + "/" + aBancos[nPOS][8]   //Agencia / Codigo Conv�nio
				aDados[8] := substr(dtos(SE1->E1_EMISSAO),7,2)+"/"+substr(dtos(SE1->E1_EMISSAO),5,2)+"/"+substr(dtos(SE1->E1_EMISSAO),1,4)	//Data de Emissao
				aDados[9] := SE1->E1_IDCNAB
				aDados[10]:= 'DM' 	//Especie - tipo de documento que originou o boleto (ex: DM, DS, NP) //VERIFICAR
				aDados[11]:= "S"
				aDados[12]:= DTOC(dDatabase)
				aDados[13] := Alltrim(SE1->E1_NOSNUM)
				aDados[14]:= aBancos[nPOS][12]
				aDados[15]:= "REAL"                             //Moeda/esp�cie
				aDados[16]:= ""                                 //Quantidade de moeda vari�vel
				aDados[17]:= TRANSF(nValorReal,"@E 999,999.99")	//Valor do T�tulo    (calculado - descrescimos + acrescimentos - abatimentos)
				aDados[13] := Alltrim(SE1->E1_NOSNUM)
				aDados[18]:=  ""                                //Instru��es  //Verificar
				aDados[19]:=  ""                                //Desconto / Abatimento		//N�o preencher

				//Linha G do Boleto
				aDados[20]:=  ""                                //Juros / Multa             //N�o preencher

				//Linha H do Boleto
				aDados[21]:=  nValorReal                       //Valor Cobrado              //N�o preencher

				//Linha I do Boleto
				aDados[22]:= cSacado                          //Sacado (Nome, CNPJ)
				aDados[23]:= cEndSac                          //Endere�o
				aDados[24]:= cEndSac1                         //CEP - CIDADE - MUNICIPIO - ESTADO
				aDados[25]:= cNomeCli                         //Sacado
				aDados[26]:= cEndCed                          //Endere�o do Cedente

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
					aDados[32] := xValJurDIa				//Valor di�rio da Multa
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
