//============================================================================//
// Autor    | Luciana Rodrigues                                               //
//----------------------------------------------------------------------------//
// Data     | 01/01/2014                                                      //
//----------------------------------------------------------------------------//
// Descricao| Rotina para geração e Impressão de Boletos do Sicoob			  //
//          | Boleto Pac/Fuprom		                                          //
//----------------------------------------------------------------------------//
// Partida  | Menu do Programa		                                          //
//============================================================================//

#include "rwmake.ch"
#Include "TopConn.ch"
#include "protheus.ch"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "RPTDEF.CH"
#Include "ParmType.ch"
#INCLUDE "TBICONN.CH"
#INCLUDE 'FWMVCDEF.CH'
#DEFINE CRLF Chr(13) + Chr(10)

/*/{Protheus.doc} BIOFIN06
Geração de Boletos PAC/FUPROM - Banco Sicoob
@author Luciana Rodrigues
@since 01/01/2014
@version 11.5
@history 20/01/2017, Ângelo Barros, Não exibe títulos com E1_XXGRBOL = '2' - Chamado nº. 23268. 
@history 01/02/2018, Ângelo Barros, Retirar a pergunta BIOFIN06 e chumbar os parâmetros bancários - Chamado nº. 26229.
@history 16/02/2017, Ângelo Barros, Esconder o botão Cancelar Boleto no menu Outras Ações - Chamado nº.26538.
@history 28/12/2018, Ângelo Barros, Boletos PAC para BB e FUPROM para o SICOOB - Chamado nº.29156
@history 28/12/2018, Ângelo Barros, Separar títulos PAC (BB) dos títulos FUPROM  - Chamado nº.29272
@history 09/07/2019, Ângelo Barros, Informar parcelas na linha digitável / adequar o layout - Chamado nº. 30631.
@type function
@example Rotina para geração e impressão de boletos.
@example Usa as funções do fonte: BIOBOLFUN.PRW
@example Usa GRUPO DE PERGUNTAS : BIOFIN06
@see\\192.168.101.38\documentação info comercial\PROTHEUS DISTRIBUIDOR\MIT044\MIT044 - (SE1) - Especificação de personalização - Boletos.docx

/*/
User Function BIOFIN06(cTpBol)

	private cDataInicio := '20151001'
	private cTipo		:= Alltrim(cTpBol)
	Private oMark				//Para controle da seleção (check)
	Private aBancos		:= {}	//Array usado em todas as funções que conterá dados do banco selecionado
	Private aDados[36]			//Array usado para receber os dados do boleto atual
	Private cTitulos			//Titulos que foram selecionados
	Private cMarc    	:= ""	//Titulos marcados

	// FUPROM - Bio Extratus
	Private cNoPrntFBE	:= "E1_XXGRBOL <>'2' .AND. E1_PREFIXO = 'FUP' .AND. E1_XXBOIMP <> 'S'.AND.  E1_TIPO == 'BOL' .AND. E1_SALDO > 0 .AND. E1_EMISSAO >= '" + cDataInicio + "' .AND. E1_XXTPDIS <> 'C' "
	Private cTodosFBE	:= "E1_XXGRBOL <>'2' .AND. E1_PREFIXO = 'FUP' .AND. E1_TIPO == 'BOL' .AND. E1_SALDO > 0 .AND. E1_EMISSAO >= '" + cDataInicio + "' .AND. E1_XXTPDIS <> 'C' "
	Private cImpFBE		:= "E1_XXGRBOL <>'2' .AND. E1_PREFIXO = 'FUP' .AND. E1_XXBOIMP == 'S'.AND.  E1_TIPO == 'BOL' .AND. E1_SALDO > 0 .AND. ALLTRIM(E1_IDCNAB) =='' .AND. E1_EMISSAO>= '" + cDataInicio + "' .AND. E1_XXTPDIS <> 'C' "

	// FUPROM - Chikas
	Private cNoPrntFCH	:= "E1_XXGRBOL <>'2' .AND. E1_PREFIXO = 'FUP' .AND. E1_XXBOIMP <> 'S'.AND.  E1_TIPO == 'BOL' .AND. E1_SALDO > 0 .AND. E1_EMISSAO >= '" + cDataInicio + "' .AND. E1_XXTPDIS == 'C' "
	Private cTodosFCH	:= "E1_XXGRBOL <>'2' .AND. E1_PREFIXO = 'FUP' .AND. E1_TIPO == 'BOL' .AND. E1_SALDO > 0 .AND. E1_EMISSAO >= '" + cDataInicio + "' .AND. E1_XXTPDIS == 'C' "
	Private cImpFCH		:= "E1_XXGRBOL <>'2' .AND. E1_PREFIXO = 'FUP' .AND. E1_XXBOIMP == 'S'.AND.  E1_TIPO == 'BOL' .AND. E1_SALDO > 0 .AND. ALLTRIM(E1_IDCNAB) =='' .AND. E1_EMISSAO>= '" + cDataInicio + "' .AND. E1_XXTPDIS == 'C' "

	// PAC - Bio Extratus
	Private cNoPrntPBE	:= "E1_XXGRBOL <>'2' .AND. E1_PREFIXO = 'PAC' .AND. E1_VALOR<>'1.00' .AND. E1_XXBOIMP <> 'S'.AND.  E1_TIPO == 'BOL' .AND. E1_SALDO > 0 .AND. E1_EMISSAO >= '" + cDataInicio + "' .AND. E1_XXTPDIS <> 'C' "
	Private cTodosPBE	:= "E1_XXGRBOL <>'2' .AND. E1_PREFIXO = 'PAC' .AND. E1_VALOR<>'1.00'.AND.E1_TIPO == 'BOL' .AND. E1_SALDO > 0 .AND. E1_EMISSAO >= '" + cDataInicio + "' .AND. E1_XXTPDIS <> 'C' "
	Private cImpPBE		:= "E1_XXGRBOL <>'2' .AND. E1_PREFIXO = 'PAC' .AND. E1_VALOR<>'1.00' .AND.E1_XXBOIMP == 'S'.AND.  E1_TIPO == 'BOL' .AND. E1_SALDO > 0 .AND. ALLTRIM(E1_IDCNAB) =='' .AND. E1_EMISSAO>= '" + cDataInicio + "' .AND. E1_XXTPDIS <> 'C' "

	// PAC - Chikas
	Private cNoPrntPCH	:= "E1_XXGRBOL <>'2' .AND. E1_PREFIXO = 'PAC' .AND. E1_VALOR<>'1.00' .AND. E1_XXBOIMP <> 'S'.AND.  E1_TIPO == 'BOL' .AND. E1_SALDO > 0 .AND. E1_EMISSAO >= '" + cDataInicio + "' .AND. E1_XXTPDIS == 'C' "
	Private cTodosPCH 	:= "E1_XXGRBOL <>'2' .AND. E1_PREFIXO = 'PAC' .AND. E1_VALOR<>'1.00'.AND.E1_TIPO == 'BOL' .AND. E1_SALDO > 0 .AND. E1_EMISSAO >= '" + cDataInicio + "' .AND. E1_XXTPDIS == 'C' "
	Private cImpPCH		:= "E1_XXGRBOL <>'2' .AND. E1_PREFIXO = 'PAC' .AND. E1_VALOR<>'1.00' .AND.E1_XXBOIMP == 'S'.AND.  E1_TIPO == 'BOL' .AND. E1_SALDO > 0 .AND. ALLTRIM(E1_IDCNAB) =='' .AND. E1_EMISSAO>= '" + cDataInicio + "' .AND. E1_XXTPDIS == 'C' "


	Private aRotina	:= MenuDef()
	private aaux 		:= {}

	//Instancia a classe com objeto de browse com marcação
	oMark := FWMarkBrowse():New()

	//Definição da tabela a ser utilizada
	oMark:SetAlias("SE1")

	//Define o título do browse de marcação
	oMark:SetDescription("BOLETOS " + SubSTR(cTpBol, 1,3) + IIF( LEN(cTpBol) > 3, ' CHIKAS', ' BIO EXTRATUS'))

	// Habilida o uso de Filtro
	oMark:oBrowse:SetDBFFilter(.T.)
	oMark:oBrowse:SetUseFilter(.T.)

	//Define o campo de marcação
	oMark:SetFieldMark('E1_OK')

	//Define a legenda

	oMark:AddLegend("E1_XXBOIMP <>  'S' .AND. ALLTRIM(E1_IDCNAB) =='' .AND. ALLTRIM(E1_NUMBOR) == '' ", "GREEN"	,  "Não Impresso")
	oMark:AddLegend("E1_XXBOIMP ==  'S' .AND. ALLTRIM(E1_IDCNAB) =='' .AND. ALLTRIM(E1_NUMBOR) <> '' ", "RED"		,  "Não enviados p/ o Banco")
	oMark:AddLegend("E1_XXBOIMP ==  'S' .AND. ALLTRIM(E1_IDCNAB) <>'' .AND. ALLTRIM(E1_NUMBOR) <> '' ", "BLACK"	,  "Enviados p/ o Banco")

	//Define os títulos que estão marcados
	bAfterMark := { || markBol()}
	oMark:SetAfterMark(bAfterMark)

	// Filtra apenas Não Impressos
	U_F6NoImp(cTipo)

	oMark:Activate()
	cMarc := ''

Return Nil


//Função para definição do menu
Static Function MenuDef()

	Local aRotina := {}

	ADD OPTION aRotina TITLE 'Gerar Boletos'    ACTION 'U_GERA()'  	OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Cancelar Boletos' ACTION 'U_CANC()'  	OPERATION 5 ACCESS 0

	ADD OPTION aRotina TITLE 'Todos'   			ACTION "U_F6Todos( cTipo )"	OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Não Impresso' 	ACTION "U_F6NoImp( cTipo )"	OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Impressos'		ACTION "U_F6Impres(cTipo )"	OPERATION 3 ACCESS 0

Return aRotina

//Função para selecionar os títulos da janela do FWMarkBrowse
Static Function markBol()

	Local cMarca   := oMark:Mark()

	If oMark:IsMark (cMarca)
		cMarc +=alltrim(STR(SE1->(RECNO())))  + ","
	else

		if Len(cMarc) > 0
			cMarc  := strtran(cMarc, alltrim(STR(SE1->(RECNO()))) + ",","")          //RETIRA O MARCADO
		endif

	endif

Return

// Inverte a seleção
User Function ALLMARK1()
	oMark:SetInvert()
Return Nil

User Function F6NoImp(cTipo)

	Local cFiltro := ""

	DO CASE
	CASE cTipo == 'FUP'
		cFiltro := cNoPrntFBE
	CASE cTipo == 'FUPCHK'
		cFiltro := cNoPrntFCH
	CASE cTipo == 'PAC'
		cFiltro := cNoPrntPBE
	CASE cTipo == 'PACCHK'
		cFiltro := cNoPrntPCH
	END CASE

	cMarc := ""
	oMark:CleanFilter()
	oMark:SetFilterDefault(cFiltro)
	oMark:Refresh()

Return Nil

// Todos os boletos FUPROM
User Function F6TODOS(cTipo)

	Local cFiltro := ""

	DO CASE
	CASE cTipo == 'FUP'
		cFiltro := cTodosFBE
	CASE cTipo == 'FUPCHK'
		cFiltro := cTodosFCH
	CASE cTipo == 'PAC'
		cFiltro := cTodosPBE
	CASE cTipo == 'PACCHK'
		cFiltro := cTodosPCH
	END CASE

	cMarc := ""
	oMark:CleanFilter()
	oMark:SetFilterDefault(cFiltro)
	oMark:Refresh()

Return Nil

User Function F6Impres(cTipo )

	Local cFiltro := ""

	DO CASE
	CASE cTipo == 'FUP'
		cFiltro := cImpFBE
	CASE cTipo == 'FUPCHK'
		cFiltro := cImpFCH
	CASE cTipo == 'PAC'
		cFiltro := cImpPBE
	CASE cTipo == 'PACCHK'
		cFiltro := cImpPCH
	END CASE

	cMarc := ""
	oMark:CleanFilter()
	oMark:SetFilterDefault(cFiltro)
	oMark:Refresh()
Return Nil

//Função para processar os boletos
User Function GERA()

	Private cBanco   := ""
	Private cAgencia := ""
	Private cConta   := ""

	// PAC - Bio Extratus
	IF cTipo == 'PAC'
		cBanco   := GetMV("MV_XXPACBA")
		cAgencia := Padr(GetMV("MV_XXPACAG"), TamSX3("EE_AGENCIA")[1])
		cConta   := Padr(GetMV("MV_XXPACCC"), TamSX3("EE_CONTA"	 )[1])

		// FUPROM - Bio Extratus
	ELSEIF cTipo == 'FUP'
		cBanco   := GetMV("MV_XXFUPBA")
		cAgencia := Padr(GetMV("MV_XXFUPAG"), TamSX3("EE_AGENCIA")[1])
		cConta   := Padr(GetMV("MV_XXFUPCC"), TamSX3("EE_CONTA"	 )[1])

		// PAC - Chikas
	ELSEIF cTipo == 'PACCHK'
		cBanco   := GetMV("MV_XXPCHBA")
		cAgencia := Padr(GetMV("MV_XXPCHAG"), TamSX3("EE_AGENCIA")[1])
		cConta   := Padr(GetMV("MV_XXPCHCC"), TamSX3("EE_CONTA"	)[1])

		// FUPROM - Chikas
	ELSEIF cTipo == 'FUPCHK'
		cBanco   := GetMV("MV_XXFCHBA")
		cAgencia := Padr(GetMV("MV_XXFCHAG"), TamSX3("EE_AGENCIA")[1])
		cConta   := Padr(GetMV("MV_XXFCHCC"), TamSX3("EE_CONTA")[1])
	ENDIF

	setBanc()   //Seta o array de bancos
	nPOS := checkBanc(alltrim(cBanco))

	IF ! MsgYesNo("<h4>Tem certeza que deseja gerar o(s) boleto(s) selecionado(s) para: </h4>" ;
			+ "<ul>  <li><b>Banco:</b> " 	+ cBanco 	;
			+		"<li><b>Agência:</b> "	+ cAgencia 	;
			+ 		"<li><b>Conta:</b> "	+ cConta	+ "? </ul>",;
			"Boleto " + SE1->E1_PREFIXO +  IIF(SE1->E1_XXTPDIS <> 'C', ' BIO EXTRATUS!', 'CHIKAS!'), "ATENÇÃO!")
		return .F.
	endif

	//Tratando os códigos de retorno
	If Len(cMarc) > 0
		cMarc := SUBSTR(cMarc,1,Len(cMarc)-1) //Retira a virgula
	Else

		cMarc := ""

	endif

	If len(cMarc) == 0
		MsgStop("Selecione algum título para geração dos boletos!", "ATENCAO!")
		return
	Else

		cTitulos := cMarc

	endif

	//Gera consulta temporária dos títulos selecionados
	If Empty(alltrim(cBanco))
		MsgAlert("Erro 03 - Não foi possível determinar para qual banco o boleto será gerado! Entre em contato com o Administrador do Sistema.","ATENCAO!")
		return
	endif

	//Procura se o banco selecionado está no array de bancos com boletos desenvolvidos e retorna os dados do banco
	setBanc()   //Seta o array de bancos
	nPOS := checkBanc(alltrim(cBanco))

	if (nPOS == 0)
		MsgAlert("04 - O sistema não está configurado para trabalhar com esse banco, informe outro banco!")
		return
	endif

	//Executando a consulta dos itens selecionados
	cQuery := " SELECT  "
	cQuery += "    SE1.R_E_C_N_O_ SE1RECNO, SE1.* "				+ CRLF
	cQuery += " FROM "      + RetSqlName("SE1") +  " SE1 "  		+ CRLF
	cQuery += "     WHERE SE1.R_E_C_N_O_ IN (" + cTitulos + ")"	+ CRLF
	cQuery += " ORDER BY E1_CLIENTE, E1_NUM "                     + CRLF

	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	EndIf

	TCQUERY cQuery NEW ALIAS "QRY"

	//Buscando parâmetros de banco  e atualizando o array de bancos
	dbSelectArea("SEE")
	dbSetOrder(1)
	dbSeek( xFilial("SEE") + cBanco    + cAgencia   + cConta   +  '001',     .T.)

	If SEE->(Eof())
		MsgStop("As configurações de banco que você selecionou não foram encontradas na tabela de parâmetros de banco (SEE) - ";
			+ CRLF + " Entre em contato com administrador do sistema! ", "ATENCAO")
		SEE->(dbCloseArea())
		return
	endif

	//tratando parâmetros do banco
	nDvAgencia      	:=  alltrim(SEE->EE_DVAGE)
	NDvConta        	:=  alltrim(SEE->EE_DVCTA)
	cCodced		  	:=  alltrim(cConta) + NdvConta
	cCodEmp         	:=  alltrim(SEE->EE_CODEMP)
	cFaixaAtu       	:=  alltrim(SEE->EE_FAXATU)
	cFaixaFim       	:=  alltrim(SEE->EE_FAXFIM)
	cCarteira       	:=  alltrim(SEE->EE_XXCARTE)
	cMens1          	:=  alltrim(SEE->EE_XXMENS1)
	cMens2          	:=  alltrim(SEE->EE_XXMENS2)
	cMens3          	:=  alltrim(SEE->EE_XXMENS3)
	cJuros          	:=  SEE->EE_XXTXJUR
	cJurDia         	:=  SEE->EE_XXTXJDI
	SEE->(dbCloseArea())

	//Atualizando vetor de dados do banco
	aBancos[nPOS][5]  := nDvAgencia
	aBancos[nPOS][6]  := NDvConta
	aBancos[nPOS][7]  := cCodced
	aBancos[nPOS][8]  := cCodEmp
	aBancos[nPOS][9]  := cConta
	aBancos[nPOS][10] := cAgencia
	aBancos[nPOS][12] := cCarteira
	aBancos[nPOS][13] := cFaixaFim

	oPrn := TMSPrinter():New()

	bPulou := .F.

	While QRY->(!Eof())

		//se esse título for de outro banco ele não irá imprimir
		If !Empty(alltrim(QRY->E1_PORTADO))

			IF alltrim(QRY->E1_PORTADO) <> alltrim(cBanco) .or. alltrim(QRY->E1_AGEDEP) <> alltrim(cAgencia) .or. alltrim(QRY->E1_CONTA) <> alltrim(cConta)
				MsgStop("Esse título - " + QRY->E1_NUM + "  já foi impresso para outro banco, não poderá ser impresso para o banco escolhido! "  + CRLF + ;
					"Escolha o parâmetro do banco corretamente!" + chr(13) + chr(10) + ;
					"Esse boleto não será impresso!", "ATENCAO!")
				QRY->(dbSkip())   // pula o boleto
				Loop
			endif

		endif

		//Obtendo Nosso Número
		If ! Empty(AllTrim(QRY->E1_NUMBCO)) .and. QRY->E1_XXBOIMP == 'S'
			cNossoNum := Alltrim(QRY->E1_NUMBCO)  //Ja foi impresso atribui o mesmo nosso numero
			bPulou    := .T.
		Else

			bPulou    := .F.

			If (cBanco == '237')                  //Bradesco usa a carteira para montar o nosso numero
				cCodEmp := cCarteira

			endif
			cNossoNum  := U_MONTANUM (cBanco, alltrim(cCodEmp), cFaixaAtu, cFaixaFim, aBancos[nPOS])

			If cNossoNum == "ERRO1" .or. Empty(cNossoNum)
				Alert("Verifique o campo código da empresa na tabela de parâmetros bancários. (SEE)")
				return
			endif

			If cNossoNum == "ERRO2"
				Alert("O campo nosso numero está acima da faixa permitida, SERÁ ABORTADO, favor rever a faixa, verifique tabela SEE.")
				return
			endif

		endif

		aBancos[nPOS][11] := cNossoNum

		//Verificando Abatimento dos títulos
		nAbatim	:= 0

		//Tratando os juros
		njuros := 0

		If QRY->E1_VALJUR > 0 .and. QRY->E1_PORCJUR > 0
			nJuros	:= Round(QRY->E1_SALDO * (QRY->E1_PORCJUR/100),2)
		endif

		njuros := ALLTRIM(transf(njuros,"@E 999,999.99"))

		//Atualiza a linha digitável, codigo de barras
		aAux := array(3)
		aAux := U_CALCBOL(cBanco, QRY->E1_VENCREA, QRY->E1_SALDO, QRY->E1_DECRESC, nAbatim, QRY->E1_ACRESC,  nPOS, aBancos, QRY->E1_PARCELA )

		//Montando o array com dados do título para o arry de Dados do boleto
		//Linha  A do Boleto
		aDados[1] := aBancos[nPOS][3]                           // Arquivo de logotipo bmp na pasta SYSTEM
		aDados[2] := aAux[1][1]                                 // Código de Barras
		aDados[3] := aAux[1][2]                                 // Linha Digitável

		If (len(aAux[1][1]) <> 44)
			Alert("Código de barras com tamanho inválido - verifique parâmetros bancários na tabela (SEE)")
			return
		endif

		oPrn:StartPage()

		//Buscando os dados para montagem do array
		//Buscando dados do cliente
		dbSelectArea("SA1")
		dbSetOrder(1)  // A1_FILIAL   +A1_COD          +A1_LOJA
		dbSeek(         xFilial("SA1")+QRY->E1_CLIENTE +QRY->E1_LOJA, .T.)

		cNomeCli :=  alltrim(SA1->A1_NOME)
		cCGCCli  :=  If(SA1->A1_TIPO=="F",TRansform(SA1->A1_CGC, "@R 999.999.999-99"),TRansform(SA1->A1_CGC, "@R 99.999.999/9999-99"))
		cSacado  :=  cNomeCli + "   " + " CPF/CPNJ: " + cCGCCli
		cEndSac  :=  ALLTRIM(SA1->A1_END) + "," + ALLTRIM(SA1->A1_BAIRRO)
		cEndSac1 :=  TRANSFORM(SA1->A1_CEP,"@R 99999-999") + " - " + ALLTRIM(SA1->A1_MUN) + " - " + SA1->A1_EST
		SA1->(dbCloseArea())

		//Buscando dados do cedente   - busca da tabela de empresas SM0
		cNomeCed := SUBS (SM0->M0_NOMECOM,1,35) +  "  CNPJ: " + TRANSFORM(SM0->M0_CGC, "@R 99.999.999/9999-99")
		cEndCed := alltrim(SM0->M0_ENDCOB) + ' , ' + alltrim(SM0->M0_BAIRCOB) + ' , ' + alltrim(SM0->M0_CIDCOB) + ' - ' + alltrim(SM0->M0_ESTCOB) + ', Cep: ' + TRansform(SM0->M0_CEPCOB, "@R 99999-999")

		//Linha B do Boleto
		if cBanco == '341'
			aDados[4] := 'Até o vencimento pague preferencialmente no Itaú. Após o vencimento pague somente no Itaú.'            // Local de pagamento
		endif

		if cBanco == '756'
			aDados[4] := 'Pague Preferencialmente no SICOOB'  // Local de pagamento
		Else
			aDados[4] := 'Pagável em qualquer Banco até o vencimento'  // Local de pagamento
		endif

		if cBanco == '237'
			aDados[4] := 'Pagável Preferencialmente na rede Bradesco  ou no Bradesco Expresso'  // Local de pagamento
		endif

		aDados[5] := substr(QRY->E1_VENCREA,7,2)+"/"+substr(QRY->E1_VENCREA,5,2)+"/"+substr(QRY->E1_VENCREA,1,4)    //Vencimento

		//Linha C do Boleto
		aDados[6] :=  cNomeCed                                     //Nome do Cedente
		aDados[7] :=  aBancos[nPOS][10] + "/" + aBancos[nPOS][8]   //Agencia / Codigo Convênio

		//Linhda D do Boleto
		aDados[8] := substr(QRY->E1_EMISSAO,7,2)+"/"+substr(QRY->E1_EMISSAO,5,2)+"/"+substr(QRY->E1_EMISSAO,1,4)	//Data de Emissao

		//20/07/2015 - Alessandro Tratando o número do documento para colocar / Parcela
		if (alltrim(QRY->E1_PARCELA)=='')
			aDados[9] := QRY->E1_PREFIXO + QRY->E1_NUM + QRY->E1_PARCELA + QRY->E1_TIPO          //Numero do documento
		else
			aDados[9] := QRY->E1_PREFIXO + QRY->E1_NUM + "/" +  QRY->E1_PARCELA + QRY->E1_TIPO   //Numero do documento
		endif

		IF cBanco == '001' .or. cBanco == '237'
			aDados[10]:= 'DM'	//Especie - tipo de documento que originou o boleto (ex: DM, DS, NP) //VERIFICAR
		endif

		IF cBanco == '341'
			aDados[10]:= 'DMI'	//Especie - tipo de documento que originou o boleto (ex: DM, DS, NP) //VERIFICAR
		endif

		IF cBanco == '756'
			aDados[10]:= 'DV'	//Especie - tipo de documento que originou o boleto (ex: DM, DS, NP) //VERIFICAR
		endif

		IF cBanco == '756'
			aDados[11]:= "S"                                //Aceite
		ELSE
			aDados[11]:= "N"                                //Aceite
		ENDIF

		aDados[12]:= DTOC(dDatabase)                   //Data da impressão do boleto
		aDados[13]:= aBancos[nPOS][11]                 //Nosso Numero

		//Linha  E do Boleto
		aDados[14]:= cCarteira                         //Carteira
		aDados[15]:= "R$"                              //Moeda/espécie
		aDados[16]:= ""                                //Quantidade de moeda variável
		aDados[17]:= TRANSF(aAux[1][3],"@E 999,999.99")//Valor do Título    (calculado - descrescimos + acrescimentos - abatimentos)

		//Linha F do Boleto
		aDados[18]:=  ""                               //Instruções  //Verificar
		aDados[19]:=  ""                               //Desconto / Abatimento            //Não preencher

		//Linha G do Boleto
		aDados[20]:=  ""                              //Juros / Multa                    //Não preencher

		//Linha H do Boleto
		aDados[21]:=  aAux[1][3]                      //Valor Cobrado            			//Não preencher

		//Linha I do Boleto
		aDados[22]:= cSacado                          //Sacado (Nome, CNPJ)
		aDados[23]:= cEndSac                          //Endereço
		aDados[24]:= cEndSac1                         //CEP - CIDADE - MUNICIPIO - ESTADO
		aDados[25]:= cNomeCli                         //Sacado
		aDados[26]:= cEndCed                          //Endereço do Cedente

		//Tratando as mensagem  da SEE
		aDados[28]:= cMens1                           //Mensagem 1
		aDados[29]:= cMens2                           //Mensagem 2
		aDados[30]:= cMens3                           //Mensagem 3

		//Tratando Juros / Desconto /Multa - Mensagens
		IF cJuros > 0
			xValJurMes := ROUND((cJuros/100),2)        //juros Mes
			aDados[31] := xValJurMes                   //Valor dos Juros
		ENDIF

		If cJurDia > 0
			xValJurDIa := (cJurDia/100)                //Juros dia
			aDados[32] := xValJurDIa                   //Valor diário da Multa
		endif

		aDados[33]   := QRY->E1_DESCFIN/100         //Valor do Desconto
		aDados[34]   := QRY->E1_DECRESC             //Valor do Desconto COM ncc
		aDados[35]   := 0  							// VALOR DO NCC

		//VERIFICANDO DIFERENÇA ENTRE SALDO E VALOR, SE TIVER, HOUVE UMA COMPENSAÇÃO
		if (QRY->E1_SALDO <> QRY->E1_VALOR)

			cQuerySC5 := "	SELECT E5_DOCUMEN, E5_VALOR  				" + CRLF
			cQuerySC5 += "	FROM " + RetSqlName("SE1") + " SE1 			" + CRLF
			cQuerySC5 += "	INNER JOIN " + RetSqlName("SE5") + " SE5 	" + CRLF
			cQuerySC5 += "		ON  SE1.E1_FILIAL	= SE5.E5_FILIAL		" + CRLF
			cQuerySC5 += " 		AND E5_PREFIXO 	= E1_PREFIXO 			" + CRLF
			cQuerySC5 += "		AND E5_NUMERO	= E1_NUM 				" + CRLF
			cQuerySC5 += "		AND E5_PARCELA 	= E1_PARCELA  			" + CRLF
			cQuerySC5 += " WHERE SE1.E1_FILIAL = '" + xFilial("SE1") + "'"+ CRLF
			cQuerySC5 += " 		AND E1_PREFIXO='" + QRY->E1_PREFIXO + " '"+ CRLF
			cQuerySC5 += "		AND E1_NUM='" + QRY->E1_NUM + " ' 		" + CRLF
			cQuerySC5 += "		AND E1_PARCELA='" + QRY->E1_PARCELA + " '"+ CRLF
			cQuerySC5 += "		AND SE1.D_E_L_E_T_ = '' 				" + CRLF
			cQuerySC5 += "		AND SE5.D_E_L_E_T_ = '' 				" + CRLF

			If Select('SE5QRY') <> 0
				SE5QRY->(DbCloseArea())

			endif
			TCQUERY cQuerySC5  NEW ALIAS 'SE5QRY'

			if SE5QRY->(EOF())
				Alert("05 - ATENÇÃO: Há uma diferença de valor e saldo do título, favor verificar com o financeiro: Número:" + QRY->E1_NUM)
				return .F.
			else

				aDados[35] := 0
				aDados[36] := ""

				While SE5QRY->(!Eof())

					aDados[35]   += SE5QRY->E5_VALOR// VALOR DO NCC
					aaux := {}
					aaux := STRTOKARR(SE5QRY->E5_DOCUMEN, " ")
					aDados[36]   += " - " + SUBSTR(aaux[2],1,9)     // AS LISTAS DAS NOTAS FISCAIS
					SE5QRY->(DbSkip())

				End Do

			endif

		endif

		//Atualiza campos
		cChave :=	QRY->E1_CLIENTE+QRY->E1_LOJA+QRY->E1_PREFIXO+QRY->E1_NUM+QRY->E1_PARCELA+QRY->E1_TIPO
		atuaCampos(cChave,aBancos[nPOS], bPulou)

		//Pegando novo sequencial
		//Buscando parâmetros de banco  e atualizando o array de bancos

		dbSelectArea("SEE")
		dbSetOrder(1)
		dbSeek(xFilial("SEE") + aBancos[nPOS][1]   + aBancos[nPOS][10]   + aBancos[nPOS][9]   +  '001',     .T.)
		cFaixaAtu         := SEE->EE_FAXATU
		aBancos[nPOS][14] := cFaixaAtu          //Contador do sequencial

		SEE->(dbCloseArea())

		//Chamando o método de impressão passando o array de Dados
		printBolet(aDados, aBancos, nPOS, oPrn)

		QRY->(DbSkip())

		oPrn:EndPage()

	End

	oPrn:Preview()
	cMarc := ""
	//oMark:MarkRec(.F.)
	cMarc:=''
	// Filtra apenas Não Impressos
	U_F6NoImp(cTipo)
Return Nil

//----------------------------------------------------------------------------------------------------------------------------------------------------------------
//Gera a classe de impressao do boleto
Static Function printBolet(aDados, aBancos, nPOS, oPrn)

	local I := ""

	//Variaveis de Fontes a serem utilizadas para impressao dos boletos
	oFntTim18N  := TFont():New( "Times New Roman"   ,,18,,.t.,,,,,.f. )
	oFntTim16N  := TFont():New( "Times New Roman"   ,,16,,.t.,,,,,.f. )
	oFontAri06  := TFont():New( "Arial"             ,,06,,.f.,,,,,.f. )
	oFontAri08N := TFont():New( "Arial"             ,,08,,.t.,,,,,.f. )

	If cbanco == '341'
		cAgCodCed := alltrim(aBancos[nPOS][10])  +  "/" + alltrim(aBancos[nPOS][9]) + ;
			iif(Empty(aBancos[nPOS][6]),"","-" + aBancos[nPOS][6])
	Else

		If cbanco == '756'
			cAgCodCed := alltrim(aBancos[nPOS][10])  +  "/" + aBancos[nPOS][8]
		Else
			cAgCodCed := alltrim(aBancos[nPOS][10])	+ iif(Empty(aBancos[nPOS][5]),"","-" ;
				+ aBancos[nPOS][5]) + "/" 	+ alltrim(aBancos[nPOS][9]);
				+ iif(Empty(aBancos[nPOS][6]),"","-" + aBancos[nPOS][6])
		endif

	endif

//-----------------------------------------------------  RECIBO DO SACADO E FICHA COMPENSAÇÃO ----------------------------------------------------------------------------------
// Monta linhas horizontais  

	nAjust2	:= -1600	// Recibo Sacado
	nAnt    := nAjust2

	For I := 1 To 2         // 1 - Para recibo do sacado e 2 para Ficha de Compensação

		oPrn:Line(2220+nAjust2, 0050, 2220+nAjust2, 2380)
		oPrn:Line(2290+nAjust2, 0050, 2290+nAjust2, 2380)

		nAjust2 += 50
		oPrn:Line(2360+nAjust2, 0050, 2360+nAjust2, 2380)
		oPrn:Line(2430+nAjust2, 0050, 2430+nAjust2, 2380)
		oPrn:Line(2500+nAjust2, 0050, 2500+nAjust2, 2380)
		oPrn:Line(2845+nAjust2, 0050, 2845+nAjust2, 2380)
		oPrn:Line(3050+nAjust2, 0050, 3050+nAjust2, 2380)
		oPrn:Line(2570+nAjust2, 1720, 2570+nAjust2, 2380)
		oPrn:Line(2640+nAjust2, 1720, 2640+nAjust2, 2380)
		oPrn:Line(2710+nAjust2, 1720, 2710+nAjust2, 2380)
		oPrn:Line(2780+nAjust2, 1720, 2780+nAjust2, 2380)

		nAjust2 := nAnt

		// Monta linha verticais
		oPrn:Line(2135+nAjust2, 0620, 2215+nAjust2, 0620)
		oPrn:Line(2135+nAjust2, 0830, 2215+nAjust2, 0830)
		oPrn:Line(2220+nAjust2, 1720, 2895+nAjust2, 1720)

		nAjust2 += 50
		oPrn:Line(2360+nAjust2, 0500, 2500+nAjust2, 0500)
		oPrn:Line(2360+nAjust2, 0900, 2500+nAjust2, 0900)
		oPrn:Line(2360+nAjust2, 1100, 2430+nAjust2, 1100)
		oPrn:Line(2360+nAjust2, 1400, 2500+nAjust2, 1400)
		oPrn:Line(2430+nAjust2, 0700, 2500+nAjust2, 0700)
		oPrn:Line(2170+nAjust2, 0050, 3050+nAjust2, 0050)
		oPrn:Line(2170+nAjust2, 2380, 3050+nAjust2, 2380)

		nAjust2 := nAnt

		//Logotipo
		IF FILE(aBancos[nPOS,3])
			oPrn:SayBitmap( 2140+nAjust2, 0050, aBancos[nPOS,3],560,70 )
		ELSE
			oPrn:Say( 2150+nAjust2, 0050, aBancos[nPOS,2],oFntTim18N,100)
		ENDIF

		oPrn:Say( 2150+nAjust2, 0640, aBancos[nPOS,4], oFntTim18N,100)             //codigo do banco
		oPrn:Say( 2155+nAjust2, 0870, aDados[3]      , oFntTim16N, 100)            //linha digitavel - somente na ficha de compensação
		oPrn:Say( 2225+nAjust2, 0070, "Local de Pagamento "    ,oFontAri06,100)
		oPrn:Say( 2225+nAjust2, 1730, "Vencimento "            ,oFontAri06,100)
		oPrn:Say( 2245+nAjust2, 0090, aDados[4], oFontAri08N,100)


		oPrn:Say( 2295+nAjust2, 0070, "Beneficiário "              ,oFontAri06,100)
		oPrn:Say( 2295+nAjust2, 1730, "Agência/Codigo Cedente "    ,oFontAri06,100)

		oPrn:Say( 2320+nAjust2, 0090, aDados[6],  oFontAri08N,100)             //Nome do Cedente
		oPrn:Say( 2365+nAjust2, 0090, aDados[26], oFontAri08N,100)             //Endereço do Cedente
		oPrn:Say( 2250+nAjust2, 2250, aDados[5],  oFontAri08N,500, ,NIL , 1 )  //Data Vencimento
		oPrn:Say( 2365+nAjust2, 2250, cAgCodCed,  oFontAri08N,500, ,NIL , 1 )  //Agencia / Cod Ced

		nAjust2 += 50

		oPrn:Say( 2365+nAjust2, 0070, "Data Documento "        ,oFontAri06,100)
		oPrn:Say( 2365+nAjust2, 0510, "Nº. Documento "         ,oFontAri06,100)
		oPrn:Say( 2365+nAjust2, 0910, "Especie Doc. "          ,oFontAri06,100)
		oPrn:Say( 2365+nAjust2, 1110, "Aceite "                ,oFontAri06,100)
		oPrn:Say( 2365+nAjust2, 1410, "Data do Processamento " ,oFontAri06,100)
		oPrn:Say( 2365+nAjust2, 1730, "Nosso Numero "          ,oFontAri06,100)

		oPrn:Say( 2390+nAjust2, 0090, aDados[8], oFontAri08N,100  )     //Data do documento
		oPrn:Say( 2390+nAjust2, 0540, aDados[9] , oFontAri08N,100  )    //Numero documento

		oPrn:Say( 2390+nAjust2, 0970, aDados[10], oFontAri08N,100) 		//Especie
		oPrn:Say( 2390+nAjust2, 1230, aDados[11], oFontAri08N,100)		//Aceite

		cDtProces := DToC(dDatabase)
		oPrn:Say( 2390+nAjust2, 1440, cDtProces , oFontAri08N, 100			) //Data do processamento
		oPrn:Say( 2390+nAjust2, 2250, aDados[13], oFontAri08N, 500, ,NIL , 1) //nosso numero

		oPrn:Say( 2435+nAjust2, 0070, "Uso do Banco "          	,oFontAri06, 100)
		oPrn:Say( 2435+nAjust2, 0510, "Carteira "			   	,oFontAri06, 100)
		oPrn:Say( 2435+nAjust2, 0710, "Especie "             	,oFontAri06, 100)
		oPrn:Say( 2435+nAjust2, 0910, "Quantidade "           	,oFontAri06, 100)
		oPrn:Say( 2435+nAjust2, 1410, "Valor "                 	,oFontAri06, 100)
		oPrn:Say( 2435+nAjust2, 1730, "Valor do Documento "    	,oFontAri06, 100)

		oPrn:Say( 2460+nAjust2, 0540, aDados[14]     			, oFontAri08N, 100)            // Carteira
		oPrn:Say( 2460+nAjust2, 0715, "R$"                      , oFontAri08N, 100)
		oPrn:Say( 2460+nAjust2, 2250, aDados[17]                , oFontAri08N, 500, ,NIL , 1 ) // Valor
		oPrn:Say( 2505+nAjust2, 0070, "Instruções: "            , oFontAri06 , 100)
		oPrn:Say( 2505+nAjust2, 1730, "(-) Desconto/Abatimento" , oFontAri06 , 100)

		//Tratando as mensagens
		//Tratando Multa
		if aDados[31] <> 0 .and. aDados[31] <> NIL
			nValor    := aDados[21] * aDados[31]    //Valor * valor juros
			auxJur    := TRANSF(nValor,"@E 999,999.99")
			oPrn:Say (2545+nAjust2, 0090, "MULTA DE     R$ " + auxJur +   "   APÓS O VENCIMENTO." ,oFontAri08N,100)//  Mensagem Juros
		endif

		//Tratando Juros
		If aDados[32] <> 0  .and. aDados[32] <> NIL
			nValor    := (aDados[21] * aDados[32])/30    //Valor * valor juros dia
			auxMulta  := TRANSF(nValor,"@E 999,999.99")
			oPrn:Say (2595+nAjust2, 0090, "APÓS VENCIMENTO JUROS DE " + auxMulta + " AO DIA", oFontAri08N, 100)            //   Mensagem Multa
		EndIf

		//Tratando desconto
		if aDados[33] <> 0   .and. aDados[33] <> NIL
			nValor    :=  aDados[21] * aDados[33]     //Valor * % desconto
			auxDesc   := TRANSF(nValor,"@E 999,999.99")
			oPrn:Say (2645+nAjust2, 0090, "DESCONTO DE   R$ " + auxDesc + "    P/ PAGAMENTO ATÉ O VENCIMENTO", oFontAri08N, 100)       //  Mensagem Desconto
		endif

		//Tratando desconto no Financeiro
		if aDados[34] <> 0   .and. aDados[34] <> NIL
			nValor    :=  aDados[34]     //Valor * % desconto
			auxDesc   := TRANSF(nValor,"@E 999,999.99")
			oPrn:Say (2645+nAjust2, 0090, "CONCEDER ABATIMENTO DE R$ " + auxDesc + "", oFontAri08N, 100)       //  Mensagem Desconto
		endif

		//Tratando desconto na por NCC
		if aDados[35] <> 0   .and. aDados[35] <> NIL
			nValor    :=  aDados[35]     //Valor * % desconto
			auxDesc   := TRANSF(nValor,"@E 999,999.99")
			oPrn:Say (2645+nAjust2, 0090, "JÁ FOI DESCONTADO O VALOR DE R$ " + auxDesc + "    ,  REFERENTE NF(s): " + aDados[36], oFontAri08N, 100)       //  Mensagem Desconto NCC
		endif

		//Tratar as mensagens
		if ! Empty(aDados[28])
			oPrn:Say( 2695+nAjust2, 0090, aDados[28] ,oFontAri08N, 100)//Mensagens 1
		endif
		if ! Empty(aDados[29])
			oPrn:Say( 2745+nAjust2, 0090, aDados[29] ,oFontAri08N, 100)//Mensagens 2
		endif
		if ! Empty(aDados[30])
			oPrn:Say( 2795+nAjust2, 0090, aDados[30] ,oFontAri08N, 100) //Mensagens 3
		endif

		//---------------------------------------------------------------------------------------------------------------------------------------------------------
		oPrn:Say( 2575+nAjust2, 1730, "(-) Outras deduções "    , oFontAri06 , 100)
		oPrn:Say( 2645+nAjust2, 1730, "(+) Mora/Multa/Juros "   , oFontAri06 , 100)
		oPrn:Say( 2715+nAjust2, 1730, "(+) Outros Acréscimos "  , oFontAri06 , 100)
		oPrn:Say( 2785+nAjust2, 1730, "(=) Valor Cobrado "      , oFontAri06 , 100)

		oPrn:Say( 2850+nAjust2, 0070, "Pagador"                  , oFontAri06 , 100)
		oPrn:Say( 2885+nAjust2, 0090, aDados[22]                , oFontAri08N, 100)
		oPrn:Say( 2925+nAjust2, 0090, aDados[23]                , oFontAri08N, 100)
		oPrn:Say( 2965+nAjust2, 0090, aDados[24]                , oFontAri08N, 100)

		oPrn:Say( 3010+nAjust2, 0070, "Sacador/Avalista "       , oFontAri06 , 100)
		oPrn:Say( 3050+nAjust2, 1900, "Autenticação Mecânica"   , oFontAri06,  100) //13


		MSBAR("INT25" ,26.4 , 1.0 ,aDados[2],oPrn,.F.,NIL,.T.,0.0295,1.3,.F.,NIL,NIL,.F.)     //impressora

		nAjust2 := -100
		nAnt    := nAjust2
	Next I

Return

//------------------------------------------------------------------------------------------------------------------------------------------------------------------
//Verifica se o banco selecionado tem o boleto desenvolvido e retorna a posicao do banco no array de bancos
Static Function checkBanc(cBanco)
	Local nPOS := 0
	nPOS	:= ASCAN(aBancos,{|x| x[1]==cBanco})
Return nPos

//Alimenta o vetor de bancos que já foram implementados 
Static Function setBanc()
	// DEFINE PARÂMETROS DE CADA BANCO POSSÍVEL (9)
	// Vide documentação

	AADD(aBancos, { "001","BANCO DO BRASIL", "001.bmp"    , "001-9",,,,,,,,"",,,})    //Banco do Brasil
	AADD(aBancos, { "237","BRADESCO",        "237.bmp"    , "237-2",,,,,,,,"",,,})    //Bradesco
	AADD(aBancos, { "341","BANCO ITAÚ S.A ", "341.bmp"    , "341-7",,,,,,,,"",,,})    //Itau
	AADD(aBancos, { "756","SICOOB",          "756.bmp"    , "756-0",,,,,,,,"",,,})    //Sicoob
	AADD(aBancos, { "104","CAIXA",           "104.bmp"    , "104-0",,,,,,,,"",,,})    //Caixa
Return

//----------------------------------------------------------------------------------------------------------------------------------------------------------------
//Atualiza os campos após a geração do boleto
Static Function atuaCampos(cChave, aBancos, bPulou)


	//Abre o título atual para atualizações e verificações
	dbSelectArea("SE1")
	SE1->(dbSetOrder(2))
	DBSeek(XFILIAL("SE1")+cChave, .T.)                                 //QRY->E1_CLIENTE+QRY->E1_LOJA+QRY->E1_PREFIXO+QRY->E1_NUM+QRY->E1_PARCELA+QRY->E1_TIPO

	//Verifica se o título já está em algum borderô
	If (Empty(SE1->E1_NUMBOR))
		//Cria e busca o numero do próximo borderô para esse título

		//cNumBor := BuscaBord(aBancos[1], aBancos[10] , aBancos[9], cChave)
		cNumBor := BuscaBord(cBanco, cAgencia ,cConta, cChave)
	Else
		//Ja estava em um Borderô
		cNumBor := SE1->E1_NUMBOR
	endif

	//Atualiza SE1

	RecLock("SE1",.F.)

	Replace SE1->E1_NUMBCO   with aBancos[11]                           //nosso numero
	Replace SE1->E1_NOSNUM   with aBancos[11]                           //nosso numero
	Replace SE1->E1_MOVIMEN	 with ddatabase                             //Data movimentação
	Replace SE1->E1_PORTADO	 with aBancos[1]                            //codigo banco
	Replace SE1->E1_AGEDEP 	 with aBancos[10]                           //agencia sem DV
	Replace SE1->E1_CONTA  	 with aBancos[9]                            //conta sem DV
	Replace SE1->E1_SITUACA	 with "1"                                   //Situação do Título - 0=Carteira;1=Cob.Simples;2=Descontada;3=Caucionada;4=Vinculada;5=Advogado;6=Judicial
	Replace SE1->E1_XXBOIMP  with "S"                                   //Coloca como ja impresso
	Replace SE1->E1_NUMBOR   with cNumBor                               //Numero Borderô
	Replace SE1->E1_DATABOR  with dDatabase                             //Dt de criação do Borderô
	Replace SE1->E1_OK       with ""                                    //Para retirar a seleção do campo assim que é impresso

	If cBanco == '756'
//		Replace SE1->E1_IDCNAB      with Substr(aBancos[11],1,7)                                   //Para retirar a seleção do campo assim que é impresso
	endif

	MsUnLock()
	SE1->(dbCloseArea())

	//Atualiza SEE
	//Tratar faixa final de numeração
	//Buscando parâmetros de banco  e atualizando o array de bancos
	If bPulou == .F.

		dbSelectArea("SEE")
		dbSetOrder(1)
		dbSeek(xFilial("SEE") + aBancos[1]   + aBancos[10]   + aBancos[9]   +  '001',     .T.)

		RecLock("SEE",.F.)

		If cBanco <> '756'
			cFxAtu :=  StrZero((1 + Val(SUBSTR(SEE->EE_FAXATU,1, 12))),12)
		Else
			cFxAtu :=  StrZero((1 + Val(SUBSTR(SEE->EE_FAXATU,1, 7))),7)
		endif

		Replace SEE->EE_FAXATU   with cFxAtu //faixa atual
		SEE->(dbCloseArea())

	endif

Return

//----------------------------------------------------------------------------------------------------------------------------------------------------------------
//Cria  borderô 
Static Function BuscaBord(cBanco, cAgencia, cConta, cChave)

	//Verifica se há algum borderô em aberto para a data atual
	DbSelectAreA("SEA")
	// DbSetOrdeR(3) //indice personalizado para boletos - EA_FILIAL+EA_PORTADO+EA_AGEDEP+EA_NUMCON+EA_CART+EA_DATABOR
	DbOrderNickName("SEAXXIND")
	DbSeek(xFilial("SEA") + cBanco + cAgencia  + cConta + "R" + dtos(ddatabase))          //HÁ ALGUM BORDERÔ DESSE BANCO NO DIA ATUAL?

	cNumBor := ""

	While SEA->(!Eof())                                     ;
			.and. SEA->EA_FILIAL  == xFilial("SEA");
			.and. SEA->EA_PORTADO == cBanco        ;
			.and. SEA->EA_AGEDEP  == cAgencia      ;
			.and. SEA->EA_NUMCON  == cConta        ;
			.and. SEA->EA_CART    == "R"           ;
			.and. SEA->EA_DATABOR == dDatabase

		//Se ainda não foi transferido poderá usar o mesmo número pois ainda está em aberto
		If SEA->EA_TRANSF <> "S"
			cNumBor	:= SEA->EA_NUMBOR
		EndIf

		SEA->(DbSkip())

	End Do

	//Se não encontrou nenhum titulo na SEA busca o último borderô o parametro e atualiza o parametro de contagem do borderô  e cria o borderô na SEA
	If Empty(cNumBor)

		cNumBor := Soma1(GetMV("MV_XXBO756"),6)
		cNumBor := Replicate("0",6-Len(Alltrim(cNumBor)))+Alltrim(cNumBor)

		While !MayIUseCode("SE1"+xFilial("SE1")+cNumBor)  //verifica se esta na memoria, sendo usado
			// busca o proximo numero disponivel
			cNumBor := Soma1(cNumBor)
		EndDo

		//SÓ ATUALIZA QUANDO O TITULO NAO ESTÁ NO BORDERÔ
		SETMV("MV_XXBO756",cNumBor)

	EndIf

	SEA->(DbCloseArea())

	//Cria o borderô na SEA
	//-------------------------------------------- Inclui registro na tabela SEA (Titulos enviados a bancos)---------------------------------------
	dbSelectArea("SE1")
	SE1->(dbSetOrder(2))
	DBSeek(XFILIAL("SE1")+cChave, .T.)                                 //QRY->E1_CLIENTE+QRY->E1_LOJA+QRY->E1_PREFIXO+QRY->E1_NUM+QRY->E1_PARCELA+QRY->E1_TIPO


	dbSelectArea("SEA")
	dbSetOrder(1) //Verifica se o título existe na SEA
	dbSeek(XFILIAL("SEA")+cNumBor+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO)

	IF !FOUND()  // Se não encontrou - cria o borderô na tabela SEA
//  			Alert('07 - Criando novo Borderô.')
		RecLock("SEA",.T.)
		Replace SEA->EA_FILIAL		with XFILIAL("SEA")
		Replace SEA->EA_PREFIXO		with SE1->E1_PREFIXO
		Replace SEA->EA_NUM			with SE1->E1_NUM
		Replace SEA->EA_PARCELA		with SE1->E1_PARCELA
		Replace SEA->EA_PORTADO		with cBanco
		Replace SEA->EA_AGEDEP		with cAgencia
		Replace SEA->EA_NUMBOR		with cNumBor
		Replace SEA->EA_DATABOR		with Date()
		Replace SEA->EA_TIPO	    with SE1->E1_TIPO
		Replace SEA->EA_CART		with "R"
		Replace SEA->EA_NUMCON		with cConta
		Replace SEA->EA_SITUACA		with "1"
		Replace SEA->EA_SITUANT		with "0"
		Replace SEA->EA_FILORIG 		with SE1->E1_FILIAL
		MsUnLock()
	endif
	SEA->(DbCloseArea())


Return cNumBor

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//Função para cancelamento dos títulos selecionados
User Function CANC()


	//Busca os títulos selecionados para cancelamento
	//Tratando os códigos de retorno
	If Len(cMarc) > 0
		If  SUBSTR(cMarc,len(cMarc),Len(cMarc)-1) == ","
			cMarc := SUBSTR(cMarc,1,Len(cMarc)-1) //Retira a virgula
		endif
	Else
		cMarc := ""
	endif


	If len(cMarc) == 0
		MsgStop("Selecione o boleto que deseja cancelar!", "ATENCAO!")
		return

	Else
		cTitulos := cMarc
	endif

	IF ! MsgYesNo("Tem certeza que deseja cancelar esse título? ", "Atenção") //YESNO
		return
	endif

	//Realizando a consulta dos títulos selecionados
	cQuery := " SELECT                                           "
	cQuery += "    SE1.R_E_C_N_O_ SE1RECNO, SE1.*                "
	cQuery += " FROM "      + RetSqlName("SE1") +  " SE1         "  																		 	+ CRLF
	cQuery += "     WHERE SE1.R_E_C_N_O_ IN (" + cTitulos + ")   "																			+ CRLF
	cQuery += " ORDER BY E1_NUM"                                                                                                   	+ CRLF

	If Select("QRY1") <> 0
		QRY1->(DbCloseArea())
	EndIf

	TCQUERY cQuery NEW ALIAS "QRY1"

	While QRY1->(!Eof())

		//Verificando se o título já foi transferido  - somente para títulos impressos
		If ( !Empty(QRY1->E1_NUMBOR))

			dbSelectArea("SEA")
			dbSetOrder(1) //Verifica se o título existe na SEA
			dbSeek(XFILIAL("SEA") + QRY1->E1_NUMBOR + QRY1->E1_PREFIXO + QRY1->E1_NUM + QRY1->E1_PARCELA + QRY1->E1_TIPO, .T.)

			IF SEA->EA_TRANSF <> "S"
				//Não foi enviado ao banco irá cancelar o título
				//Cancelando na SEA - colocando o registro como cancelado
				RecLock("SEA",.F.)
				dbDelete()
				MsUnLock()

				//Atualizando os campos do título
				dbSelectArea("SE1")
				SE1->(dbSetOrder(2))
				DBSeek(XFILIAL("SE1") + QRY1->E1_CLIENTE + QRY1->E1_LOJA + QRY1->E1_PREFIXO + QRY1->E1_NUM + QRY1->E1_PARCELA + QRY1->E1_TIPO, .T.)

				RecLock("SE1",.F.)

				Replace SE1->E1_NUMBCO   with ""                           //nosso numero
				Replace SE1->E1_NOSNUM   with ""                           //nosso numero
				Replace SE1->E1_PORTADO	 with ""                           //codigo banco
				Replace SE1->E1_AGEDEP 	 with ""                           //agencia sem DV
				Replace SE1->E1_CONTA  	 with ""                           //conta sem DV
				Replace SE1->E1_SITUACA	 with "0"                          //Situação do Título - 0=Carteira;1=Cob.Simples;2=Descontada;3=Caucionada;4=Vinculada;5=Advogado;6=Judicial
				Replace SE1->E1_XXBOIMP  with "N"                          //Coloca como ja impresso
				Replace SE1->E1_NUMBOR   with ""                           //Numero Borderô
				Replace SE1->E1_DATABOR  with CTOD("//")                   //Data do Borderô
				Replace SE1->E1_MOVIMEN  with CTOD("//")                   //Data da movimentação
				Replace SE1->E1_OK       with ""                           //Limpa a marca da seleção
				Replace SE1->E1_IDCNAB   with ""                           //ID CNAB

				MsUnLock()
				SE1->(dbCloseArea())

			Else
				Alert("O Título " + QRY1->E1_NUM + " Parcela: " + QRY1->E1_PARCELA  + " não pode ser cancelado pois já foi enviado o arquivo de remessa para o banco!")
				SEA->(dbCloseArea())
				QRY1->(dbSkip())
				Loop
			endif

			SEA->(dbCloseArea())

			//Ainda não gerou borderô ou cancelou titulo do borderô - poderá excluir
		Else
			dbSelectArea("SE1")
			SE1->(dbSetOrder(2))
			DBSeek(XFILIAL("SE1") + QRY1->E1_CLIENTE + QRY1->E1_LOJA + QRY1->E1_PREFIXO + QRY1->E1_NUM + QRY1->E1_PARCELA + QRY1->E1_TIPO, .T.)

			RecLock("SE1",.F.)

			Replace SE1->E1_NUMBCO   with ""                           //nosso numero
			Replace SE1->E1_NOSNUM   with ""                           //nosso numero
			Replace SE1->E1_PORTADO	 with ""                           //codigo banco
			Replace SE1->E1_AGEDEP 	 with ""                           //agencia sem DV
			Replace SE1->E1_CONTA  	 with ""                           //conta sem DV
			Replace SE1->E1_SITUACA	 with "0"                          //Situação do Título - 0=Carteira;1=Cob.Simples;2=Descontada;3=Caucionada;4=Vinculada;5=Advogado;6=Judicial
			Replace SE1->E1_XXBOIMP  with "N"                          //Coloca como ja impresso
			Replace SE1->E1_NUMBOR   with ""                           //Numero Borderô
			Replace SE1->E1_DATABOR  with CTOD("//")                   //Data do Borderô
			Replace SE1->E1_MOVIMEN  with CTOD("//")                   //Data da movimentação
			Replace SE1->E1_OK       with ""                           //Limpa a marca da seleção
			Replace SE1->E1_IDCNAB   with ""                           //ID CNAB

			MsUnLock()
			SE1->(dbCloseArea())

		endif

		QRY1->(dbSkip())

	End Do

	cMarc := ""
	oMark:MarkRec(.F.)
	//  oMark:Refresh()

	// Filtra apenas Não Impressos
	U_F6NoImp(cTipo)

Return
