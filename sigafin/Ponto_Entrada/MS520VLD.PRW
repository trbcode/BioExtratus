/*//#########################################################################################
Project  : project
Module   : SIGAFAT
Source   : MS520VLD
Objective: Integra Exclusão com API BB
*///#########################################################################################

#INCLUDE 'TOTVS.CH'



/*/{Protheus.doc} MS520VLD

    Ponto de Entrada para validação da Exclusão do Documento de Saída. 

    @author		Ângelo Barros
    @since		28/06/2017
    @version	MP11.5
    @history	28/06/2017, Ângelo Barros, Notificar o usuário quando o boleta já tiver sido impresso. Chamado nº 24527
    @history 	23/01/2018, Ângelo Barros, Atualiza a situação do Pedido de Venda no SIBE	- Chamado nº. 26162.
    @history 	31/01/2018, Ângelo Barros, Atualiza tambem a tabela pedidosvenda_produto	- Chamado nº. 26162.
    @history    07/02/2020, Maria Luisa Arcanjo, Incluir URL do Sian - Chamado nº 32201 
    @history 	10/05/2021, Emily Ferreira de Brito, Atualizar campo C7_XXENTSI após retorno de uma nota ser excluído - Chamado n. 34916
    @history 	03/06/2024, Igor Guimarães,
    @link		http://tdn.totvs.com/display/public/PROT/MS520VLD
    @type 		function
    @author  Igor Guimarães
    @example Example
    @param   [Parameter_Name],Parameter_type,Parameter_Description
    @return  booleam
    @table   Tables
    @since   25-08-2021
/*/
User Function MS520VLD()

	Local cSituacao     := "A"
	Local cRetSIAN	    := ""
	Local cMsgErr	    := ""
	Local cPara		    := GetMV("MV_XXSBPRT")
	Local cAssunto	    := "[PROTHEUS] Erro ao atualizar SIAN - " + GetEnvServer()
	Local cTitulo	    := "<center>Pedido não atualizado no SIAN!<center>"
	Local aAreaSD2      := SD2->(GetArea())
	Local aAreaSC7      := SC7->(GetArea())
	Local aAreaSD1      := SD1->(GetArea())
	Local aAreaSE1      := SE1->(GetArea())
	Local lRet          := .T.
	Local cNosso        :=""
	Local cCodBco       := ""
	Local cCodAge       := ""
	Local cCodCta       := ""
	Local cSerie        := Padr(SF2->F2_SERIE,TAMSX3("F2_SERIE")[1])
	Local cNumTit       := Padr(SF2->F2_DOC,TAMSX3("F2_DOC")[1])
	Local cChaveSE1     := cSerie + cNumTit
	Local aDados        := {}
	private oBancoBB    as Object
	If SM0->M0_CODIGO == "01" .AND. AllTrim(SM0->M0_CODFIL) == '01'
		// Verfica se o Boleto dessa NF já foi impresso ou enviado ao banco.
		U_BIOFAT21(SF2->F2_PREFIXO, SF2->F2_DUPL)

		// Atualiza o status do Pedido no SIBE.
		MsgRun("Estamos atualizando o status do pedido no SIBE...",;
			"Aguarde..." , {|| U_BIOFAT20( "" /*cPedido*/, SF2->F2_DOC, SF2->F2_SERIE, cSituacao, "" /*dEmissao*/, /*cPedSIBE*/, /*cClassif*/) })

		// Move o XML do Pedido para a pasta do FTP do SIAN (Chamado)
		IF SC5->C5_XXTIPOP == 'A' .AND. SC5->C5_XXFINA <> '7'

			cRetSIAN := HTTPGET("https://192.168.101.2/middlewares/rotinas/pedidosvenda/PedidosAneethun?args[]=" + Alltrim(SC5->C5_NUM) + "&args[]=2")

			// Erro ao tentar atualizar SIAN
			IF AT("ERRO!", UPPER(cRetSIAN) ) > 0

				// Comunica usuario
				MsgAlert(cRetSIAN, "SIAN | PEDIDO " +  Alltrim(SC5->C5_NUM) )

				// Envia e-mail para inform·tica com cÛpia para usu·rio.
				cMsgErr := "<br>Não foi possÌvel atualizar o pedido <b>" + SC5->C5_NUM + " </b> no SIAN. "
				cMsgErr	+= " Segue os dados para an·lise:<br><br>"
				cMsgErr	+= "<ul>"
				cMsgErr	+= "<li> <b>Usuário:</b> " + RetCodUsr() + " - " + UsrRetName(RetCodUsr()) 	+ "</li>"
				cMsgErr	+= "<li> <b>Computador:</b> " + GetClientIP() + " - " + GetRmtInfo()[1]		+ "</li>"
				cMsgErr	+= "<li> <b>Rotina:</b> " + FunName() + " \ " + ProcName(1) 				+ "</li>"
				cMsgErr	+= "<li> <b>Pedido:</b> " + SC5->C5_NUM 									+ "</li>"
				cMsgErr	+= "<li> <b>Nota Fiscal:</b> " + SC5->C5_SERIE + SC5->C5_NOTA				+ "</li>"
				cMsgErr	+= "<li> <b>Cliente:</b> " + SC5->C5_CLIENT + " - " + ALLTRIM(SC5->C5_NOME) + "</li>"
				cMsgErr	+= "<li> <b>Erro:</b> " + cRetSIAN 											+ "</li>"
				cMsgErr	+= "</ul>"
				U_BIOPADEM(cPara,cAssunto, cMsgErr, cTitulo, /*cLink*/, /*cTxtLink*/, UsrRetMail(RetCodUsr()) )

			ENDIF
		ENDIF

		// Alteração do campo C7_XXENTSI quando o retorno de uma nota é excluido -> adiciona quantidade retornada novamente
		IF ( U_TESMovEst(SD2->D2_TES) .AND. SD2->D2_NFORI <> '' )
			U_BIOFAT32(SC5->C5_NUM, "A")
		ENDIF
	ENDIF

	dbSelectArea("SE1")
	dbSetOrder(1)
	if dbSeek(xFilial("SE1")+cChaveSE1)
		While !Eof() .and. cChaveSE1 == SE1->E1_PREFIXO + SE1->E1_NUM
			aDados := {}
			cNosso  := Alltrim(SE1->E1_NUMBCO)
			cCodBco := Alltrim(SE1->E1_PORTADO)
			cCodAge := Alltrim(SE1->E1_AGEDEP)
			cCodCta := Alltrim(SE1->E1_CONTA)

			if Empty(cNosso)
				SE1->(DBSkip())
				LOOP
			EndIf

			Aadd(aDados,"")
			Aadd(aDados,"")
			Aadd(aDados,cNosso)

			If cCodBco == "756"
				cCodClie := u_getIdClientSicoob(alltrim(cCodBco), alltrim(cCodAge), alltrim(cCodCta))
				lRet := U_BEWS0002("EXC",,,,,,aDados, , , , cCodClie)//sicoob
			elseif cCodBco == "001"
				U_IntegBB(@oBancoBB,cCodBco, cCodAge, cCodCta)
				lRet := oBancoBB:excluiBoletos(Alltrim(cNosso))
				FwFreeObj(oBancoBB)
			EndIf
			SE1->(DBSkip())
		EndDo
	EndIF

	If lRet
		MsgInfo("Boleto Excluido no banco com sucesso!","MS520VLD")
	Else
		MsgInfo("Boleto não Excluido no banco!","MS520VLD")
	EndIf

	RestArea(aAreaSD2)
	RestArea(aAreaSD1)
	RestArea(aAreaSC7)
	RestArea(aAreaSE1)
Return(lRet)
