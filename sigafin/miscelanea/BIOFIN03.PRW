//============================================================================//
// Autor    | Luciana Rodrigues                                               //
//----------------------------------------------------------------------------//
// Data     | 01/01/2014                                                      //
//----------------------------------------------------------------------------//
// Descricao| Rotina para geração e Impressão de Boletos do Banco do Brasil   //
//          | Boleto Bio Extratus	                                          //
//----------------------------------------------------------------------------//
// Partida  | Menu do Programa		                                          //
//============================================================================//

#Include "TopConn.ch"
#include "totvs.ch"
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "RPTDEF.CH"


/*/{Protheus.doc} BIOFIN03
Geração de Boletos
@author Luciana Rodrigues
@since 01/01/2014
@version 11.5
@history 15/03/2016, Ângelo Barros, Substituir "Cedente" por"Beneficiário" e "Sacado" por "Pagador" - Chamado nº.20781
@history 20/01/2017, Ângelo Barros, Não exibe títulos com E1_XXGRBOL = '2' - Chamado nº. 23268.
@history 20/01/2018, Ângelo Barros, Não pergunta para qual banco deverá ser gerado o boleto - Chamado nº. 25362.
@history 08/02/2018, Ângelo Barros, Informar parcelas na linha digitável / adequar o layout - Chamado nº. 26504
@history 08/02/2018, Ângelo Barros, Impressão do Boleto na Transportadora (banco / layout) - Chamado nº.26449.
@history 16/02/2018, Ângelo Barros, Esconder o botão Cancelar Boleto no menu Outras Ações - Chamado nº.26538.
@history 12/03/2018, Ângelo Barros, Notificar o cancelamento de boletos ao financeiro - Chamado nº. 26755. 
@history 21/05/2018, Ângelo Barros, Considerar parcela '01' ao consultar NCC - Chamado nº.27358.
@history 14/11/2018, Ângelo Barros, Informa o tipo de NCC (Negociação Esp. ou Avaria) - Chamado nº. 27805.
@history 16/12/2019, Ângelo Barros, Mensagem em boletos com NCC - Chamado nº. 31857.
@history 14/02/2020, Ângelo Barros, Cancelamento de Boletos - Chamado nº 32100.
@history 20/20/2020, Ângelo Barros, Ordenar boletos pelo número da NF  - Chamado nº 32361.
@type function
@example Rotina para geração e impressão de boletos.
@example Usa as funções do fonte: BIOBOLFUN.PRW
@example Usa GRUPO DE PERGUNTAS : BIOFIN03
@see \\192.168.101.5\protheus\Manuais de Usuário\PROTHEUS 010 - Boleto e CNAB BB\Manual do Usuário - Boleto BioExtratus.pdf
/*/
User Function BIOFIN03(cTpBol)

	Private cCodBco		:= "756"
	Private cCodAge		:= "4108"
	Private cCodCta		:= "8429"
	Private cNomeBco		:= "SICOOB CREDIMEP"
	Private oCodBco, oCodAge, oCodCta, oNomeBco, oPanel
	Private oFont25		:= TFont():New("arial",,25,,.F.,,,,,.F.,.F.)
	Private oFont20		:= TFont():New("arial",,20,,.F.,,,,,.F.,.F.)
	Private aBcosApt := {}
	Private cDataInicio := '20240918'
	Private aRelBco 	:= {} //Array com os bancos disponíveis
	Private oMark	              //Para controle da seleção (check)
	Private cTipo		:= Alltrim(cTpBol)
	Private aBancos   	:= {}     //Array usado em todas as funções que conterá dados do banco selecionado
	Private aDados[43]            //Array usado para receber os dados do boleto atual
	Private cTitulos              //Titulos que foram selecionados
	Private cMarc    	:= ""     //Titulos marcados
	Private aRotina  	:= MenuDef()
	Private lLogin      := Type("cEmpAnt") != "U"
	Private cNoPrint := ""
	private CTdos := ""
	private cCodClie := ""
	private oDlg1 as Object
	private oSize  as Object
	private cBanco   := ""
	private cAgencia := ""
	private cConta   := ""

	If !lLogin
		RpcSetEnv("01","01","Admin")
	EndIf

	if empty(aRelBco)
		GetBancos()
		cBanco   := cCodBco
		cAgencia := Padr(cCodAge, TamSX3("EE_AGENCIA")[1])
		cConta   := Padr(cCodCta, TamSX3("EE_CONTA"	 )[1])

		cNoPrint := "E1_XXGRBOL <>'2' .AND. E1_NATUREZ <> '1020003'.AND. E1_XXBOIMP <> 'S' .AND. E1_TIPO = 'NF'	.AND. E1_SALDO > 0 .AND. E1_EMISSAO >= '" + cDataInicio + "'"
		cTodos	 := "E1_NATUREZ <> '1020003'.AND. E1_TIPO = 'NF'.AND. E1_SALDO > 0 .AND. E1_EMISSAO >= '" + cDataInicio + "'"
		cFilBB   := "E1_XXGRBOL <>'2' .AND. E1_PORTADO == '001' .AND. E1_TIPO = 'NF'.AND. E1_SALDO > 0 .AND. E1_EMISSAO >= '" + cDataInicio + "'"
	endif

	if empty(aRelBco)
		if alltrim(cTipo) ==''
			cTipo := 'BIO'
		endif
		IF cTipo == 'BIO'
			cBanco   := "756"
			cAgencia := "4108 "
			cConta   := "8429      "
			cCodClie := "e227419d-ce16-43c0-ac2e-a64cea1bd6d5"
			cNoPrint := "E1_XXGRBOL <>'2' .AND. E1_NATUREZ <> '1020003'.AND. E1_XXBOIMP <> 'S' .AND. E1_TIPO = 'NF'	.AND. E1_SALDO > 0 .AND. E1_EMISSAO >= '" + cDataInicio + "'"
			cTodos	 := "E1_NATUREZ <> '1020003'.AND. E1_TIPO = 'NF'.AND. E1_SALDO > 0 .AND. E1_EMISSAO >= '" + cDataInicio + "'"
		ELSEIF cTipo == 'FUP'
			cBanco   := GetMV("MV_XXFUPBA")
			cAgencia := Padr(GetMV("MV_XXFUPAG"), TamSX3("EE_AGENCIA")[1])
			cConta   := Padr(GetMV("MV_XXFUPCC"), TamSX3("EE_CONTA"	 )[1])
			cCodClie := "5ed00c38-279b-4979-aa91-f8d0cf003b40"
			cNoPrint := "E1_XXGRBOL <>'2' .AND. E1_PREFIXO = 'FUP' .AND. E1_XXBOIMP <> 'S'.AND.  E1_TIPO == 'BOL' .AND. E1_SALDO > 0 .AND. E1_EMISSAO >= '" + cDataInicio + "' .AND. E1_XXTPDIS <> 'C' "
			cTodos	 := "E1_XXGRBOL <>'2' .AND. E1_PREFIXO = 'FUP' .AND. E1_TIPO == 'BOL' .AND. E1_SALDO > 0 .AND. E1_EMISSAO >= '" + cDataInicio + "' .AND. E1_XXTPDIS <> 'C' "

		ELSEIF cTipo == 'FUPCHK'
			cBanco   := GetMV("MV_XXFCHBA")
			cAgencia := Padr(GetMV("MV_XXFCHAG"), TamSX3("EE_AGENCIA")[1])
			cConta   := Padr(GetMV("MV_XXFCHCC"), TamSX3("EE_CONTA")[1])
			cCodClie := "fa7c41d6-6b16-4c3e-9a14-df89f799ff7d"
			cNoPrint := "E1_XXGRBOL <>'2' .AND. E1_PREFIXO = 'FUP' .AND. E1_XXBOIMP <> 'S'.AND.  E1_TIPO == 'BOL' .AND. E1_SALDO > 0 .AND. E1_EMISSAO >= '" + cDataInicio + "' .AND. E1_XXTPDIS == 'C' "
			cTodos	 := "E1_XXGRBOL <>'2' .AND. E1_PREFIXO = 'FUP' .AND. E1_TIPO == 'BOL' .AND. E1_SALDO > 0 .AND. E1_EMISSAO >= '" + cDataInicio + "' .AND. E1_XXTPDIS == 'C' "
		ENDIF
	endif
	//Defino o tamanho dos componentes através do método FwDefSize(), amarrando ao objeto oDlg
	oSize := FwDefSize():New(.T.)

	oSize:lLateral := .F.
	oSize:lProp	:= .T. // Proporcional

	oSize:AddObject( "LABEL" ,  100, 02, .T., .T. ) // Totalmente dimensionavel
	oSize:AddObject( "SELECT",  100, 98, .T., .T. ) // Totalmente dimensionavel

	oSize:Process() // Dispara os calculos

	a1stRow := {oSize:GetDimension("LABEL","LININI"),;
		oSize:GetDimension("LABEL","COLINI"),;
		oSize:GetDimension("LABEL","LINEND"),;
		oSize:GetDimension("LABEL","COLEND")}

	a2ndRow := {oSize:GetDimension("SELECT","LININI"),;
		oSize:GetDimension("SELECT","COLINI"),;
		oSize:GetDimension("SELECT","XSIZE"),;
		oSize:GetDimension("SELECT","YSIZE")}

	DEFINE MSDIALOG oDlg1 TITLE "Baixa em Lote" FROM oSize:aWindSize[1],oSize:aWindSize[2] TO oSize:aWindSize[3],oSize:aWindSize[4] OF oMainWnd PIXEL  //"Baixa em Lote"

	@ a1stRow[1], a1stRow[2] + 005 Say "Banco:" FONT oFont25 PIXEL Of oDlg1
	@ a1stRow[1]-3, a1stRow[2] + 040 MSCOMBOBOX oCodBco VAR cCodBco ITEMS aRelBco SIZE 030, 20 FONT oFont20 PIXEL Of oDlg1 Valid setBanco()
	@ a1stRow[1], a1stRow[2] + 120 Say "Agência:" FONT oFont25 PIXEL Of oDlg1
	@ a1stRow[1]+3, a1stRow[2] + 170 Say oCodAge VAR cCodAge Picture PesqPict("SEE","EE_AGENCIA") SIZE 50,10 FONT oFont20 PIXEL of oDlg1
	@ a1stRow[1], a1stRow[2] + 230 Say "Conta:" FONT oFont25 PIXEL Of oDlg1
	@ a1stRow[1]+3, a1stRow[2] + 270 Say oCodCta VAR cCodCta Picture PesqPict("SEE","EE_CONTA") SIZE 70,10 FONT oFont20 PIXEL of oDlg1
	@ a1stRow[1], a1stRow[2] + 340 Say "Nome:" FONT oFont25 PIXEL Of oDlg1
	@ a1stRow[1]+3, a1stRow[2] + 380 Say oNomeBco VAR cNomeBco Picture PesqPict("SA6","A6_NOME") SIZE 250,10 FONT oFont20 PIXEL of oDlg1

	oPanel := TPanel():New(a2ndRow[1]+10,a2ndRow[2],'',oDlg1,, .T., .T.,, ,a2ndRow[3],a2ndRow[4])

	//MsgInfo("00 - ESSA É A NOVA TELA DE REGISTRO DE BOLETOS!", "ATENCAO!")
	//Instancia a classe com objeto de browse com marcação
	oMark := FWMarkBrowse():New()

	//Definição da tabela a ser utilizada
	oMark:SetAlias("SE1")

	//Define o título do browse de marcação
	oMark:SetDescription("Boletos Bio Extratus")

	// Habilida o uso de Filtro
	oMark:oBrowse:SetDBFFilter(.T.)
	oMark:oBrowse:SetUseFilter(.T.)

	//Define o campo de marcação
	oMark:SetFieldMark('E1_OK')
	oMark:SetOwner(oPanel)
	//Define a legenda
	oMark:AddLegend("ALLTRIM(E1_XXBOIMP) <>  'S' .AND. ALLTRIM(E1_NOSNUM)=='' ", "GREEN"	,  "Não Impresso")
	oMark:AddLegend("ALLTRIM(E1_XXBOIMP) ==  'S' .AND. ALLTRIM(E1_NOSNUM)<>'' ", "BLACK"	,  "Impresso e Enviado ao Banco")

	//Define os títulos que estão marcados
	bAfterMark := { || markBol()}
	oMark:SetAfterMark(bAfterMark)

	//Define o filtro de aplicação para pegar os títulos que estão em aberto
	U_NOPRINT()

	oMark:Activate()

	ACTIVATE MSDIALOG oDlg1 ON INIT EnchoiceBar(oDlg1,{|| lRet := .T., If(.T. , oDlg1:End(),lRet := .F.)},{|| oDlg1:End()}) CENTERED
	cMarc := ''



Return Nil

//-------------------------------------------------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
description
//Função para definição do menu
@type function
@version  
@author Igor Guimarães
@since 8/16/2024
@return variant, return_description
/*/
Static Function MenuDef()

	Local aRotina := {}
	Local aSubMnu := {}


	ADD OPTION aRotina TITLE 'Verificar NCC'   	ACTION 'U_VerNCC()'     OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Enviar ao Banco'   	ACTION 'U_BOLGERA( cBanco,  cAgencia, cConta, cCodClie, .F.  )'    OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Imprimir e Enviar ao Banco'   	ACTION 'U_BOLGERA( cBanco,  cAgencia, cConta, cCodClie, .T.   )'    OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Cancelar Boletos'	ACTION 'U_BOLCANC( cCodClie )'    OPERATION 1 ACCESS 0
	ADD OPTION aRotina TITLE 'Compensar NCC'    ACTION 'FINA330()'      OPERATION 6 ACCESS 0
	ADD OPTION aRotina TITLE 'Imprime Boleto BB'	ACTION 'U_ImpBolBB(4)'   OPERATION 1 ACCESS 0// */

	ADD OPTION aRotina TITLE "Visualizações" ACTION aSubMnu OPERATION 9 ACCESS 0

	ADD OPTION aSubMnu TITLE 'Todos'        	ACTION 'U_BOLTODOS()'   OPERATION 3 ACCESS 0
	ADD OPTION aSubMnu TITLE 'Não enviados ao Banco'	ACTION 'U_NOPRINT()'     OPERATION 3 ACCESS 0
	ADD OPTION aSubMnu TITLE 'Banco do Brasil'	ACTION 'U_FILTBB()'   OPERATION 1 ACCESS 0
Return aRotina
//---------------------------------------------------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} markBol
description
//Função para selecionar os títulos da janela do FWMarkBrowse
@type function
@version  
@author Igor Guimarães
@since 8/16/2024
@return variant, return_description
/*/
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
/*/{Protheus.doc} ALLMARK
description
@type function
@version  
@author Igor Guimarães
@since 8/16/2024
@return variant, return_description
/*/
User Function ALLMARK()
	oMark:SetInvert()
Return Nil

//--------------------------------------------------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} BOLTODOS
description
//Busca todos os boletos que ja foram impressos e não impressos
@type function
@version  
@author Igor Guimarães
@since 8/16/2024
@return variant, return_description
/*/
User Function BOLTODOS()
	cMarc := ""
	oMark:CleanFilter()
	oMark:SetFilterDefault(cTodos)
	oMark:Refresh()
Return Nil

/*/{Protheus.doc} NOPRINT
description
//Busca todos os boletos que ja foram não impressos
@type function
@version  
@author Igor Guimarães
@since 8/16/2024
@return variant, return_description
/*/
User Function NOPRINT()
	cMarc := ""
	oMark:CleanFilter()
	oMark:SetFilterDefault(cNoPrint)
	oMark:Refresh()
Return Nil

/*/{Protheus.doc} BOLGERA
description
//Função para processar os boletos
@type function
@version  
@author Igor Guimarães
@since 8/16/2024
@return variant, return_description
/*/
User Function BOLGERA(cBanco,  cAgencia, cConta, cCodClie, cPrint )

	local lRet       := .f.
	local nVlrAbat   := 0
	local aDadosEmp  := {}
	local aDadosTit  := {}
	local aDatSacado := {}
	local aBolText   := {"","",""}
	Local nDiasLim   := 180
	Local oResultado := JsonObject():New()
	Local auxMulta   :=""
	Local auxJur     :=""
	private cPerg2	:= "BIOFIN03"
	private cFilePrint := ""
	private oBancoBB as Object

	if cCodBco == "001"
		U_IntegBB(@oBancoBB,cCodBco, cCodAge, cCodCta)
	endif

	IF SE1->E1_XXBOIMP <> 'S' .AND. SM0->M0_CODIGO == '01'
		//Procura se o banco selecionado está no array de bancos com boletos desenvolvidos e retorna os dados do banco
		setBanc()   //Seta o array de bancos
		nPOS := checkBanc(alltrim(cBanco))
	ENDIF

	//Tratando os códigos de retorno
	If Len(cMarc) > 0
		cMarc := SUBSTR(cMarc,1,Len(cMarc)-1) //Retira a virgula
	Else
		cMarc := ""
	endif

	If len(cMarc) == 0
		ApMsgInfo("02 - Selecione algum título para geração dos boletos!")
		return
	Else
		cTitulos := cMarc
	endif

	//PADRONIZAÇÃO - PADRONIZANDO PARA UM BANCO SOMENTE
	IF ! MsgYesNo(" Tem certeza que deseja gerar o(s) boleto(s) selecionado(s) para: <br>" ;
			+ "<b>Banco:</b> " 	+ cBanco 	+ "<br>";
			+ "<b>Agência:</b> "+ cAgencia 	+ "<br>";
			+ "<b>Conta:</b> "	+ cConta	+ "? "	, "Atenção")
		return .F.
	endif

	//Gera consulta temporária dos títulos selecionados
	If Empty(alltrim(cBanco))
		MsgAlert("03 - Escolha o banco para qual deseja gerar os boletos!","STOP")
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
	cQuery += "    SE1.R_E_C_N_O_ SE1RECNO, SE1.* "
	cQuery += " FROM "      + RetSqlName("SE1") +  " SE1 "  	+ CRLF
	cQuery += "     WHERE SE1.R_E_C_N_O_ IN (" + cTitulos + ")"	+ CRLF
	cQuery += " ORDER BY E1_NUM, E1_PARCELA "       + CRLF

	If Select("QRY") <> 0
		QRY->(DbCloseArea())
	EndIf

	TCQUERY cQuery NEW ALIAS "QRY"

	//Buscando parâmetros de banco  e atualizando o array de bancos
	dbSelectArea("SEE")
	dbSetOrder(1)   // EE_FILIAL  	+ EE_CODIGO + EE_AGENCIA + EE_CONTA +   EE_SUBCTA
	dbSeek(         XFILIAL('SEE')	+ cBanco    + cAgencia   + cConta   +  '001',     .T.)

	If SEE->(Eof())
		Alert("As configurações de banco que você selecionou não foram encontradas na tabela de parâmetros de banco (SEE) - ";
			+ CRLF + " Entre em contato com administrador do sistema! ")
		SEE->(DbCloseArea())
		return
	endif

	//tratando parâmetros do banco
	nDvAgencia      	:=  alltrim(SEE->EE_DVAGE)
	NDvConta        	:=  alltrim(SEE->EE_DVCTA)
	cCodced		  		  :=  alltrim(cConta) + NdvConta
	cCodEmp         	:=  alltrim(SEE->EE_CODEMP)
	cFaixaAtu       	:=  alltrim(SEE->EE_FAXATU)
	cFaixaFim       	:=  alltrim(SEE->EE_FAXFIM)
	cCarteira       	:=  alltrim(SEE->EE_XXCARTE)
	cMens1          	:=  alltrim(SEE->EE_XXMENS1)
	cJuros          	:=  SEE->EE_XXTXJUR
	cJurDia         	:=  SEE->EE_XXTXJDI
	nDiasLim            := IIF( !EMPTY(SEE->EE_DIASREC), SEE->EE_DIASREC,  nDiasLim )
	SEE->(DbCloseArea())

	//Atualizando vetor de dados do banco
	aBancos[nPOS][5]	:= nDvAgencia
	aBancos[nPOS][6]  	:= NDvConta
	aBancos[nPOS][7] 	:= cCodced
	aBancos[nPOS][8]  	:= cCodEmp
	aBancos[nPOS][9] 	:= cConta
	aBancos[nPOS][10] 	:= cAgencia
	aBancos[nPOS][12] 	:= cCarteira
	aBancos[nPOS][13] 	:= cFaixaFim
	aBancos[nPOS][15] 	:= cJuros
	aBancos[nPOS][16] 	:= cJurDia
	aBancos[nPOS][17] 	:= nDiasLim


	If EMPTY(cFilePrint)
		cFilePrint := "BOL_" + Alltrim(QRY->E1_PREFIXO)+"_" + Alltrim(QRY->E1_NUM) + Alltrim(QRY->E1_PARCELA) + Alltrim(QRY->E1_TIPO)  + "_" + AllTrim(QRY->E1_CLIENTE) + "_" + AllTrim(QRY->E1_LOJA)
	EndIf

	oPrn := FWMSPrinter():New(cFilePrint + ".PDF",IMP_PDF,.T.,,.T.)

	bPulou := .F.

	aDadosEmp := {	Alltrim(SM0->M0_NOMECOM)                                               ,; //[1]Nome da Empresa
	Alltrim(SM0->M0_ENDCOB)                                                            ,; //[2]Endereço
	AllTrim(SM0->M0_BAIRCOB)+", "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB ,; //[3]Complemento
	"CEP: "+Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3)             ,; //[4]CEP
	"PABX/FAX: "+SM0->M0_TEL                                                  ,; //[5]Telefones
	"CNPJ: "+Subs(SM0->M0_CGC,1,2)+"."+Subs(SM0->M0_CGC,3,3)+"."+              ; //[6]
	Subs(SM0->M0_CGC,6,3)+"/"+Subs(SM0->M0_CGC,9,4)+"-"+                       ; //[6]
	Subs(SM0->M0_CGC,13,2)                                                    ,; //[6]CGC
	"I.E.: "+Subs(SM0->M0_INSC,1,3)+"."+Subs(SM0->M0_INSC,4,3)+"."+            ; //[7]
	Subs(SM0->M0_INSC,7,3)+"."+Subs(SM0->M0_INSC,10,3)                        }  //[7]I.E

	While QRY->(!Eof())

		//Buscando os dados para montagem do array
		//Buscando dados do cliente
		dbSelectArea("SA1")
		dbSetOrder(1)  // A1_FILIAL   +A1_COD          +A1_LOJA
		dbSeek(  xFilial("SA1")+QRY->E1_CLIENTE +QRY->E1_LOJA, .T.)

		cNomeCli :=  alltrim(SA1->A1_NOME)
		cCGCCli  :=  If(SA1->A1_TIPO=="F",Transform(SA1->A1_CGC, "@R 999.999.999-99"),Transform(SA1->A1_CGC, "@R 99.999.999/9999-99"))
		cSacado  :=  cNomeCli + "   " + " CPF/CPNJ: " + cCGCCli
		cEndSac  :=  ALLTRIM(SA1->A1_END) + "," + ALLTRIM(SA1->A1_BAIRRO)
		cEndSac1 :=  TRANSFORM(SA1->A1_CEP,"@R 99999-999") + " - " + ALLTRIM(SA1->A1_MUN) + " - " + SA1->A1_EST

		aDatSacado   := { cNomeCli                 ,;   	// [1]Razão Social
		AllTrim(QRY->E1_CLIENTE )+"-"+QRY->E1_LOJA ,;   	// [2]Código
		STRTRAN(AllTrim(SA1->A1_END),"-"," ")      ,;       // [3]Endereço
		AllTrim(SA1->A1_MUN)	                   ,;   	// [4]Cidade
		SA1->A1_EST	                               ,;   	// [5]Estado
		cvaltochar(val(SA1->A1_CEP))               ,;   	// [6]CEP
		SA1->A1_CGC								   ,;		// [7]CGC
		SA1->A1_PESSOA							   ,;       // [8]PESSOA
		STRTRAN(AllTrim(SA1->A1_BAIRRO),"-"," ")    }       // [9]BAIRRO


		SA1->(DbCloseArea())

		nVlrAbat    :=  SomaAbat(QRY->E1_PREFIXO,QRY->E1_NUM,QRY->E1_PARCELA,"R",1,,QRY->E1_CLIENTE,QRY->E1_LOJA)
		nValorReal  := (QRY->E1_SALDO-nVlrAbat+ QRY->E1_ACRESC - QRY->E1_DECRESC)

		aDadosTit	:= {AllTrim(QRY->E1_NUM)+AllTrim(QRY->E1_PARCELA)	,;  // [1] Número do título
		QRY->E1_EMISSAO                              	                ,;  // [2] Data da emissão do título
		dDataBase                    					                ,;  // [3] Data da emissão do boleto
		QRY->E1_VENCTO                               	                ,;  // [4] Data do vencimento
		nValorReal                	                                    ,;  // [5] Valor do título
		aDados[13]                             	                        ,;  // [6] Nosso número (Ver fórmula para calculo)
		QRY->E1_PREFIXO                               	                ,;  // [7] Prefixo da NF
		QRY->E1_TIPO}                                                       // [8] Tipo do Titulo

		//se esse título for de outro banco ele não irá imprimir
		If !Empty(alltrim(QRY->E1_PORTADO))

			IF alltrim(QRY->E1_PORTADO) <> alltrim(cBanco) .or. alltrim(QRY->E1_AGEDEP) <> alltrim(cAgencia) .or. alltrim(QRY->E1_CONTA) <> alltrim(cConta)
				Alert("Esse título - " + QRY->E1_NUM + "  já foi impresso para outro banco, não poderá ser impresso para o banco escolhido! "  + CRLF + ;
					"Escolha o parâmetro do banco corretamente!" + CRLF + ;
					"Esse boleto não será impresso!")
				QRY->(dbSkip())   // pula o boleto
				Loop
			endif
		endif


		//Tratando as mensagem  da SEE
		aDados[28]:= cMens1                     //Mensagem 1

		// Informa dados da NF no boleto
		if (alltrim(QRY->E1_PARCELA)='')
			aDados[29] := "PAGAMENTO REFERENTE A " + QRY->E1_PREFIXO + QRY->E1_NUM + QRY->E1_PARCELA + QRY->E1_TIPO          //Numero do documento
		else
			aDados[29] := "PAGAMENTO REFERENTE A " + QRY->E1_PREFIXO + QRY->E1_NUM + "/" +  QRY->E1_PARCELA + QRY->E1_TIPO   //Numero do documento
		endif

		//Tratando Juros / Desconto /Multa - Mensagens
		IF cJuros > 0
			xValJurMes := cJuros/100				//juros Mes
			aDados[31] := xValJurMes				//Valor dos Juros
		ENDIF

		If cJurDia > 0
			xValJurDIa := (cJurDia/100)				//Juros dia
			aDados[32] := xValJurDIa				//Valor diário da Multa
		endif

		aDados[33]   := QRY->E1_DESCFIN/100			//Valor do Desconto
		aDados[34]   := QRY->E1_DECRESC				//Valor do Desconto COM ncc
		aDados[35]   := 0   						// VALOR DO NCC

		//VERIFICANDO DIFERENÇA ENTRE SALDO E VALOR, SE TIVER, HOUVE UMA COMPENSAÇÃO
		if (QRY->E1_SALDO <> QRY->E1_VALOR)

			cQuerySC5 := " SELECT E5_DOCUMEN, E5_VALOR, E5_RECPAG, E5_TIPODOC  FROM " + RetSqlName("SE1") + "  "
			cQuerySC5 += " INNER JOIN " + RetSqlName("SE5") + "  ON  "
			cQuerySC5 += " E5_PREFIXO = E1_PREFIXO AND E5_NUMERO=E1_NUM AND E5_PARCELA = E1_PARCELA  "
			cQuerySC5 += " WHERE "
			cQuerySC5 += " E1_PREFIXO='" + QRY->E1_PREFIXO + " ' AND E1_NUM='" + QRY->E1_NUM + " ' AND E1_PARCELA='" + QRY->E1_PARCELA + " ' AND " + RetSqlName("SE5") + ".D_E_L_E_T_='' AND " + RetSqlName("SE1") + ".D_E_L_E_T_='' "

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

					if SE5QRY->E5_RECPAG='R'

						aDados[35]   += SE5QRY->E5_VALOR// VALOR DO NCC
						aDados[36] += " " + AllTrim(Str(Val(SUBSTR(SE5QRY->E5_DOCUMEN, 4, 9))))    // AS LISTAS DAS NOTAS FISCAIS

					else
						aDados[35]   -= SE5QRY->E5_VALOR// VALOR DO ESTORNO
					endif

					SE5QRY->(DbSkip())

				End Do
			endif
			SE5QRY->(DbCloseArea())
		endif

		//Tratando as mensagens

		//Tratando Multa

		aDados[21]:=  nValorReal                       //Valor Cobrado              //Não preencher
		if aDados[31] <> 0 .and. aDados[31] <> NIL
			nValor     := aDados[21] * aDados[31]    		//Valor * valor juros
			auxMulta   := TRANSF(nValor,"@E 999,999.99")
			aDados[39] := "MULTA DE R$" + Alltrim(auxMulta) + " APÓS O VENCIMENTO." 	//  Mensagem 2 Juros
		ELSE
			aDados[39] := ""
		endif

		//Tratando Juros por dia
		If aDados[32] <> 0  .and. aDados[32] <> NIL
			nValor  := (aDados[21] * aDados[32])/30		//Valor * valor juros dia
			auxJur  := TRANSF(nValor,"@E 999,999.99")
			aDados[40] := "APÓS VENCIMENTO JUROS DE R$" + Alltrim(auxJur) + " AO DIA."//   Mensagem  3 Multa
		ELSE
			aDados[40] := ""
		EndIf

		// Se existir juros e multa juntar as duas mensagens em apenas uma
		IF !EMPTY(auxMulta) .AND.  !EMPTY(auxJur)
			aDados[39] := "MULTA DE "+ Alltrim(auxMulta) +", JUROS DE R$" + Alltrim(auxJur) + " ad
			aDados[40] := ""
		ENDIF


		//Tratando desconto no Financeiro
		if aDados[34] <> 0   .and. aDados[34] <> NIL
			nValor    :=  aDados[34]     //Valor * % desconto
			auxDesc   := TRANSF(nValor,"@E 999,999.99")
			aDados[41] := "CONCEDER ABATIMENTO DE R$ " + auxDesc + ""      //  Mensagem 4 Desconto
		else
			aDados[41] := ""
		endif

		//Tratando desconto na por NCC
		if aDados[35] <> 0   .and. aDados[35] <> NIL
			nValor    :=  aDados[35]     //Valor * % desconto
			auxDesc   := TRANSF(nValor,"@E 999,999.99")
			aDados[42] := "JÁ FOI DESCONTADO O VALOR DE R$" + Alltrim(auxDesc) //  Mensagem 5 Desconto NCC
			aDados[43] := SubStr("NF(s): "+ Alltrim(aDados[36]), 1, 40) //Mensagem 5 Desconto NCC
		else
			aDados[42] := ""
			aDados[43] := ""
		endif

		//Integração para registrar a cobrança no Sicoob.
		IF cBanco== "756" .and. Empty(QRY->E1_XQRCODE)//sicoob
			//(cOrigem,aDadosEmp,aDadosTit,aBancos,nPOS,aDatSacado,aBolText,aDados,dDtaBx,cDatIni,cDatFim, cCodClie, cNossoNum)
			cNossoNum  := U_MONTANUM (cBanco, alltrim(cCodEmp), cFaixaAtu, cFaixaFim, aBancos[nPOS])
			lRet :=  U_BEWS0002("GER",aDadosEmp,aDadosTit,@aBancos,nPOS,aDatSacado,aBolText,@aDados, , , , cCodClie,cNossoNum)
			If !lRet
				MsgInfo("Boleto não registrado!","BEFINM01")
				return // igor - provisório até definir regra
			Endif
		ElseIf cBanco == "001" .and. Empty(QRY->E1_CODBAR) //bb

			if oBancoBB:registraboletos(QRY->E1_PREFIXO, QRY->E1_NUM, QRY->E1_PARCELA, QRY->E1_TIPO)
				cResult := oBancoBB:cResult
				FWJsonDeserialize(cResult,@oResultado)
				FWAlertSuccess("Processamento finalizado", "Integração Banco do Brasil")
			Else
				cResult := oBancoBB:cResult
				FWJsonDeserialize(cResult,@oResultado)
				FWAlertError("Erro ao registrar boleto no Banco do Brasil: ("+QRY->E1_PREFIXO+"-"+ QRY->E1_NUM +"/"+ QRY->E1_PARCELA +") - " + '', "Integração Banco do Brasil")
			Endif
			return
		Else
			aDados[2] := Alltrim(QRY->E1_CODBAR)
			aDados[3] := Alltrim(QRY->E1_CODDIG)
			aDados[38] := Alltrim(QRY->E1_XQRCODE)
			aDados[13] := Alltrim(QRY->E1_NOSNUM)
		Endif

		//Verificando Abatimento dos títulos
		nAbatim	:= 0

		//Tratando os juros
		njuros := 0

		If QRY->E1_VALJUR > 0 .and. QRY->E1_PORCJUR > 0
			nJuros	:= Round(QRY->E1_SALDO * (QRY->E1_PORCJUR/100),2)
		EndIf

		njuros := ALLTRIM(transf(njuros,"@E 999,999.99"))

		//Montando o array com dados do título para o arry de Dados do boleto
		//Linha  A do Boleto
		aDados[1] := aBancos[nPOS][3]                           // Arquivo de logotipo bmp na pasta SYSTEM

		oPrn:StartPage()

		//Buscando dados do cedente   - busca da tabela de empresas SM0
		cNomeCed	:= SUBS (SM0->M0_NOMECOM,1,35) +  "  CNPJ: " + TRANSFORM(SM0->M0_CGC, "@R 99.999.999/9999-99")
		cEndCed		:= alltrim(SM0->M0_ENDCOB) + ' , ' + alltrim(SM0->M0_BAIRCOB) + ' , ' + alltrim(SM0->M0_CIDCOB);
			+ ' - ' + alltrim(SM0->M0_ESTCOB) + ', Cep: ' + TRansform(SM0->M0_CEPCOB, "@R 99999-999")

		//Linha B do Boleto
		if cBanco == '341'
			aDados[4] := 'Até o vencimento pague preferencialmente no Itaú. Após o vencimento pague somente no Itaú.'	// Local de pagamento
		endif

		if cBanco == '756'
			aDados[4] := 'Pague preferencialmente no SICOOB.'  			// Local de pagamento
		Else
			aDados[4] := 'Pagável em qualquer Banco até o vencimento'	// Local de pagamento
		endif

		if cBanco == '237'
			aDados[4] := 'Pagável Preferencialmente na rede Bradesco  ou no Bradesco Expresso'  // Local de pagamento
		endif

		aDados[5] := substr(QRY->E1_VENCREA,7,2)+"/"+substr(QRY->E1_VENCREA,5,2)+"/"+substr(QRY->E1_VENCREA,1,4)	//Vencimento

		//Linha C do Boleto
		aDados[6] :=  cNomeCed                                     //Nome do Cedente
		aDados[7] :=  aBancos[nPOS][10] + "/" + aBancos[nPOS][8]   //Agencia / Codigo Convênio

		//Linhda D do Boleto
		aDados[8] := substr(QRY->E1_EMISSAO,7,2)+"/"+substr(QRY->E1_EMISSAO,5,2)+"/"+substr(QRY->E1_EMISSAO,1,4)	//Data de Emissao

		IF cBanco == '756'
			aDados[9] := QRY->E1_IDCNAB
		ELSEIF (alltrim(QRY->E1_PARCELA)='')
			aDados[9] := QRY->E1_PREFIXO + QRY->E1_NUM + QRY->E1_PARCELA + QRY->E1_TIPO          //Numero do documento
		ELSE
			aDados[9] := QRY->E1_PREFIXO + QRY->E1_NUM + "/" +  QRY->E1_PARCELA + QRY->E1_TIPO   //Numero do documento
		ENDIF

		IF cBanco == '001' .or. cBanco == '237'
			aDados[10]:= 'DM'	//Especie - tipo de documento que originou o boleto (ex: DM, DS, NP) //VERIFICAR
		endif

		IF cBanco == '341'
			aDados[10]:= 'DMI'	//Especie - tipo de documento que originou o boleto (ex: DM, DS, NP) //VERIFICAR
		endif

		IF cBanco == '756'
			aDados[10]:= 'DM' 	//Especie - tipo de documento que originou o boleto (ex: DM, DS, NP) //VERIFICAR

		endif

		IF cBanco == '756'
			aDados[11]:= "S"                                //Aceite
		ELSE
			aDados[11]:= "N"                                //Aceite
		ENDIF

		aDados[12]:= DTOC(dDatabase)                    //Data da impressão do boleto

		//Linha  E do Boleto
		aDados[14]:= cCarteira                          //Carteira
		aDados[15]:= "REAL"                             //Moeda/espécie
		aDados[16]:= ""                                 //Quantidade de moeda variável
		aDados[17]:= TRANSF(nValorReal,"@E 999,999.99")	//Valor do Título    (calculado - descrescimos + acrescimentos - abatimentos)

		//Linha F do Boleto
		aDados[18]:=  ""                                //Instruções  //Verificar
		aDados[19]:=  ""                                //Desconto / Abatimento		//Não preencher

		//Linha G do Boleto
		aDados[20]:=  ""                                //Juros / Multa             //Não preencher

		//Linha H do Boleto
		aDados[21]:=  nValorReal                       //Valor Cobrado              //Não preencher

		//Linha I do Boleto
		aDados[22]:= cSacado                          //Sacado (Nome, CNPJ)
		aDados[23]:= cEndSac                          //Endereço
		aDados[24]:= cEndSac1                         //CEP - CIDADE - MUNICIPIO - ESTADO
		aDados[25]:= cNomeCli                         //Sacado
		aDados[26]:= cEndCed                          //Endereço do Cedente
		aDados[30]:= ""   							 //Mensagem 3

		//Atualiza campos
		cChave :=	QRY->E1_CLIENTE+QRY->E1_LOJA+QRY->E1_PREFIXO+QRY->E1_NUM+QRY->E1_PARCELA+QRY->E1_TIPO

		If Empty(QRY->E1_XQRCODE)
			atuaCampos(cChave,aBancos[nPOS], bPulou)
		EndIf

		//Pegando novo sequencial
		//Buscando parâmetros de banco  e atualizando o array de bancos
		dbSelectArea("SEE")
		dbSetOrder(1)   // EE_FILIAL  + EE_CODIGO + EE_AGENCIA + EE_CONTA +   EE_SUBCTA
		dbSeek(         XFILIAL("SEE") + aBancos[nPOS][1]   + aBancos[nPOS][10]   + aBancos[nPOS][9]   +  '001',     .T.)

		cFaixaAtu         := SEE->EE_FAXATU
		aBancos[nPOS][14] := cFaixaAtu          //Contador do sequencial

		SEE->(DbCloseArea())

		//Chamando o método de impressão passando o array de Dados
		if cPrint
			u_printBolet(aDados, aBancos, nPOS, oPrn,cbanco)
		end if

		QRY->(DbSkip())
		oPrn:EndPage()
	End

	if cPrint
		oPrn:Preview()
	end if

	cMarc := ""
//oMark:MarkRec(.F.)
	cMarc:=''
	U_NOPRINT()

Return Nil

//----------------------------------------------------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} printBolet
description
//Gera a classe de impressao do boleto
@type function
@version  
@author BioExtratus
@since 8/16/2024
@param aDados, array, Dados do Título
@param aBancos, array, Dados do Banco
@param nPOS, numeric, posição do array 
@param oPrn, object, objeto de impressão
/*/
User Function printBolet(aDados, aBancos, nPOS, oPrn,cbanco)

	local I 	:=""
	local aArea := GetArea()

	//Variaveis de Fontes a serem utilizadas para impressao dos boletos
	oFntTim22N  := TFont():New( "Times New Roman"   ,,22,,.t.,,,,,.f. )
	oFntTim20N  := TFont():New( "Times New Roman"   ,,20,,.t.,,,,,.f. )
	oFontAri06  := TFont():New( "Arial"             ,,06,,.f.,,,,,.f. )
	oFontAri08  := TFont():New( "Arial"             ,,08,,.f.,,,,,.f. )
	oFontAri10N := TFont():New( "Arial"             ,,10,,.t.,,,,,.f. )

	If cbanco == '341'
		cAgCodCed := alltrim(aBancos[nPOS][10]) 	  +  "/" + alltrim(aBancos[nPOS][9]) + iif(Empty(aBancos[nPOS][6]),"","-" + aBancos[nPOS][6])
	Else
		If cbanco == '756'
			cAgCodCed := alltrim(aBancos[nPOS][10])  +  "/" + aBancos[nPOS][8]
		Else
			cAgCodCed := alltrim(aBancos[nPOS][10])+ iif(Empty(aBancos[nPOS][5]),"","-" + aBancos[nPOS][5]) + "/" + alltrim(aBancos[nPOS][9]) + iif(Empty(aBancos[nPOS][6]),"","-" + aBancos[nPOS][6])
		endif
	endif


	//-----------------------------------------------------  RECIBO DO SACADO E FICHA COMPENSAÇÃO ----------------------------------------------------------------------------------
	// Monta linhas horizontais
	nAjust2	:= -2000		// Recibo Sacado
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
			oPrn:Say( 2150+nAjust2, 0050, aBancos[nPOS,2],oFntTim22N,100)
		ENDIF

		oPrn:Say( 2185+nAjust2, 0640, aBancos[nPOS,4]			,oFntTim22N	,100)	//codigo do banco
		oPrn:Say( 2185+nAjust2, 0870, aDados[3]      			,oFntTim20N	,100)	//linha digitavel - somente na ficha de compensação
		oPrn:Say( 2235+nAjust2, 0070, "Local de Pagamento " 	,oFontAri08	,100)
		oPrn:Say( 2235+nAjust2, 1730, "Vencimento "        	 	,oFontAri08	,100)
		oPrn:Say( 2260+nAjust2, 0090, aDados[4]					,oFontAri10N,100)
		oPrn:Say( 2305+nAjust2, 0070, "Beneficiário "       	,oFontAri08	,100)
		oPrn:Say( 2305+nAjust2, 1730, "Agência/Codigo Beneficiario ",oFontAri08,100)
		oPrn:Say( 2330+nAjust2, 0090, aDados[6]					,oFontAri10N,100)              //Nome do Cedente
		oPrn:Say( 2375+nAjust2, 0090, aDados[26]				,oFontAri10N,100)              //Endereço do Cedente
		oPrn:Say( 2260+nAjust2, 2225, aDados[5]					,oFontAri10N,500, ,NIL , 1 )   //Data Vencimento
		oPrn:Say( 2375+nAjust2, 2215, cAgCodCed					,oFontAri10N,500, ,NIL , 1 )   //Agencia / Cod Ced

		nAjust2 += 50

		oPrn:Say( 2375+nAjust2, 0070, "Data Documento "        	,oFontAri08	,100)
		oPrn:Say( 2375+nAjust2, 0510, "Nº. Documento "         	,oFontAri08	,100)
		oPrn:Say( 2375+nAjust2, 0910, "Especie Doc. "          	,oFontAri08	,100)
		oPrn:Say( 2375+nAjust2, 1110, "Aceite "                	,oFontAri08	,100)
		oPrn:Say( 2375+nAjust2, 1410, "Data do Processamento " 	,oFontAri08	,100)
		oPrn:Say( 2375+nAjust2, 1730, "Nosso Numero "          	,oFontAri08	,100)
		oPrn:Say( 2400+nAjust2, 0090, aDados[8]					,oFontAri10N,100) //Data do documento
		oPrn:Say( 2400+nAjust2, 0540, aDados[9] 				,oFontAri10N,100) //Numero documento
		oPrn:Say( 2400+nAjust2, 0970, aDados[10]				,oFontAri10N,100) //Especie
		oPrn:Say( 2400+nAjust2, 1230, aDados[11]				,oFontAri10N,100) //Aceite

		cDtProces := DToC(dDatabase)
		oPrn:Say( 2400+nAjust2, 1440, cDtProces 				, oFontAri10N, 100)//Data do processamento
		oPrn:Say( 2400+nAjust2, 2250, aDados[13]				, oFontAri10N, 500, ,NIL , 1 )  //nosso numero
		oPrn:Say( 2445+nAjust2, 0070, "Uso do Banco "          	, oFontAri08 , 100)
		oPrn:Say( 2445+nAjust2, 0510, "Carteira "			   	, oFontAri08 , 100)
		oPrn:Say( 2445+nAjust2, 0710, "Especie "               	, oFontAri08 , 100)
		oPrn:Say( 2445+nAjust2, 0910, "Quantidade "           	, oFontAri08 , 100)
		oPrn:Say( 2445+nAjust2, 1410, "Valor "                 	, oFontAri08 , 100)
		oPrn:Say( 2445+nAjust2, 1730, "Valor do Documento "    	, oFontAri08 , 100)
		oPrn:Say( 2470+nAjust2, 0540, aDados[14]     			, oFontAri10N, 100)// Carteira
		oPrn:Say( 2470+nAjust2, 0715, aDados[15]                , oFontAri10N, 100)
		oPrn:Say( 2470+nAjust2, 2250, aDados[17]                , oFontAri10N, 500, ,NIL , 1 )  // Valor
		oPrn:Say( 2515+nAjust2, 0070, "Instruções: "            , oFontAri08 , 100)
		oPrn:Say( 2515+nAjust2, 1730, "(-) Desconto/Abatimento" , oFontAri08 , 100)

		//Tratando as mensagens

		//Tratando Multa
		if aDados[31] <> 0 .and. aDados[31] <> NIL
			nValor     := aDados[21] * aDados[31]    		//Valor * valor juros
			auxMulta   := TRANSF(nValor,"@E 999,999.99")
			oPrn:Say (2555+nAjust2, 0090, "MULTA DE R$ " + Alltrim(auxMulta) + " APÓS O VENCIMENTO." ,oFontAri10N,100)	//  Mensagem Juros
		endif

		//Tratando Juros por dia
		If aDados[32] <> 0  .and. aDados[32] <> NIL
			nValor  := (aDados[21] * aDados[32])/30		//Valor * valor juros dia
			auxJur  := TRANSF(nValor,"@E 999,999.99")
			oPrn:Say (2605+nAjust2, 0090, "APÓS VENCIMENTO JUROS DE R$" + Alltrim(auxJur) + " AO DIA", oFontAri10N, 100) //   Mensagem Multa
		EndIf

		//Tratando desconto
		if aDados[33] <> 0   .and. aDados[33] <> NIL
			nValor    :=  aDados[21] * aDados[33]     		//Valor * % desconto
			auxDesc   := TRANSF(nValor,"@E 999,999.99")
			oPrn:Say (2755+nAjust2, 0090, "DESCONTO DE R$ " + Alltrim(auxDesc) + " P/ PAGAMENTO ATÉ O VENCIMENTO", oFontAri10N, 100)//  Mensagem Desconto
		endif

		//Tratando desconto no Financeiro
		if aDados[34] <> 0   .and. aDados[34] <> NIL
			nValor    :=  aDados[34]     //Valor * % desconto
			auxDesc   := TRANSF(nValor,"@E 999,999.99")
			oPrn:Say (2755+nAjust2, 0090, "CONCEDER ABATIMENTO DE R$ " + auxDesc + "", oFontAri10N, 100)       //  Mensagem Desconto
		endif

		//Tratando desconto na por NCC
		if aDados[35] <> 0   .and. aDados[35] <> NIL
			nValor    :=  aDados[35]     //Valor * % desconto
			auxDesc   := TRANSF(nValor,"@E 999,999.99")
			oPrn:Say (2710+nAjust2, 0090, "JÁ FOI DESCONTADO O VALOR DE R$ " + Alltrim(auxDesc) , oFontAri10N, 100)//  Mensagem Desconto NCC
			oPrn:Say (2755+nAjust2, 0090, "REFERENTE NF(s): " + Alltrim(aDados[36]), oFontAri10N, 100)       	   //  Mensagem Desconto NCC
		endif

		//Tratar as mensagens
		if ! Empty(aDados[28])
			oPrn:Say( 2655+nAjust2, 0090, aDados[28] ,oFontAri10N, 100) //Mensagens 1
		endif

		//cortando estas mensagens e mudando de posição.
		if ! Empty(aDados[29])
			oPrn:Say( 2800+nAjust2, 0090, aDados[29] ,oFontAri10N, 100) //Mensagens 2
		endif

		//imprime QrCode
		If I == 2
			oPrn:QRCode(2805+nAjust2,1350,aDados[38], 80)
		EndIf

		//---------------------------------------------------------------------------------------------------------------------------------------------------------
		oPrn:Say( 2585+nAjust2, 1730, "(-) Outras deduções "    , oFontAri08 , 100)
		oPrn:Say( 2655+nAjust2, 1730, "(+) Mora/Multa/Juros "   , oFontAri08 , 100)
		oPrn:Say( 2725+nAjust2, 1730, "(+) Outros Acréscimos "  , oFontAri08 , 100)
		oPrn:Say( 2795+nAjust2, 1730, "(=) Valor Cobrado "      , oFontAri08 , 100)

		oPrn:Say( 2860+nAjust2, 0070, "Pagador"                  , oFontAri08 ,100)
		oPrn:Say( 2895+nAjust2, 0090, aDados[22]                , oFontAri10N, 100)
		oPrn:Say( 2935+nAjust2, 0090, aDados[23]                , oFontAri10N, 100)
		oPrn:Say( 2975+nAjust2, 0090, aDados[24]                , oFontAri10N, 100)

		oPrn:Say( 3020+nAjust2, 0070, "Sacador/Avalista "       , oFontAri08 , 100)
		oPrn:Say( 3065+nAjust2, 1900, "Autenticação Mecânica"   , oFontAri08,  100) //13

		oPrn:FWMSBAR("INT25" /*cTypeBar*/,52.3/*nRow*/ ,2.2/*nCol*/, aDados[2]/*cCode*/,oPrn/*oBolNota*/,.F./*lCheck*/,/*Color*/,.T./*lHorz*/,0.025/*nWidth*/,1.5/*nHeigth*/,.F./*lBanner*/,"Arial"/*cFont*/,NIL/*cMode*/,.F./*lPrint*/,2/*nPFWidth*/,2/*nPFHeigth*/,.F./*lCmtr2Pix*/)

		nAjust2 := -800
		nAnt    := nAjust2
	Next I

	RestArea(aArea)

Return

//------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} checkBanc
description
//Verifica se o banco selecionado tem o boleto desenvolvido e retorna a posicao do banco no array de bancos
@type function
@version  
@author Igor Guimarães
@since 8/16/2024
@param cBanco, character, param_description
@return variant, return_description
/*/
Static Function checkBanc(cBanco)

	Local nPOS := 0
	nPOS := ASCAN(aBancos,{|x| x[1]==cBanco})

Return nPos

/*/{Protheus.doc} setBanc
description
//Alimenta o vetor de bancos que já foram implementados 
@type function
@version  
@author Igor Guimarães
@since 8/16/2024
@return variant, return_description
/*/
Static Function setBanc()

	// DEFINE PARÂMETROS DE CADA BANCO POSSÍVEL (9)
	// Vide documentação

	AADD(aBancos, { "001","BANCO DO BRASIL", "001.bmp"    , "001-9",,,,,,,,"",,,,,})    //Banco do Brasil
	AADD(aBancos, { "237","BRADESCO",        "237.bmp"    , "237-2",,,,,,,,"",,,,,})    //Bradesco
	AADD(aBancos, { "341","BANCO ITAÚ S.A ", "341.bmp"    , "341-7",,,,,,,,"",,,,,})    //Itau
	AADD(aBancos, { "756","SICOOB",          "756.bmp"    , "756-0",,,,,,,,"",,,,,})    //Sicoob
	AADD(aBancos, { "104","CAIXA",           "104.bmp"    , "104-0",,,,,,,,"",,,,,})    //Caixa

Return

//----------------------------------------------------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} atuaCampos
description
//Atualiza os campos após a geração do boleto
@type function
@version  
@author Igor Guimarães
@since 8/16/2024
@param cChave, character, param_description
@param aBancos, array, param_description
@param bPulou, codeblock, param_description
@return variant, return_description
/*/
Static Function atuaCampos(cChave, aBancos, bPulou)

	//Abre o título atual para atualizações e verificações
	dbSelectArea("SE1")
	SE1->(dbSetOrder(2))
	DBSeek(XFILIAL("SE1")+cChave, .T.)

	//Verifica se o título já está em algum borderô
	If (Empty(SE1->E1_NUMBOR)) .and. aBancos[1] <> "756"

		//Cria e busca o numero do próximo borderô para esse título
		cNumBor := BuscaBord(cBanco, cAgencia ,cConta, cChave)

	Else
		//Ja estava em um Borderô
		cNumBor := SE1->E1_NUMBOR
	endif

	//Atualiza SE1
	RecLock("SE1",.F.)

	Replace SE1->E1_NUMBCO   with aDados[13]                    //nosso numero
	Replace SE1->E1_NOSNUM   with aDados[13]                    //nosso numero
	Replace SE1->E1_MOVIMEN	 with ddatabase                     //Data movimentação
	Replace SE1->E1_PORTADO	 with aBancos[1]                    //codigo banco
	Replace SE1->E1_AGEDEP 	 with aBancos[10]                   //agencia sem DV
	Replace SE1->E1_CONTA  	 with aBancos[9]                    //conta sem DV
	Replace SE1->E1_SITUACA	 with "1"                           //Situação do Título - 0=Carteira;1=Cob.Simples;2=Descontada;3=Caucionada;4=Vinculada;5=Advogado;6=Judicial
	Replace SE1->E1_XXBOIMP  with "S"                           //Coloca como ja impresso
	Replace SE1->E1_NUMBOR   with cNumBor                       //Numero Borderô
	Replace SE1->E1_DATABOR  with dDatabase                     //Dt de criação do Borderô
	Replace SE1->E1_OK       with ""                            //Para retirar a seleção do campo assim que é impresso
	Replace SE1->E1_XQRCODE  with aDados[38]                    //QRCode
	Replace SE1->E1_CODBAR   with aDados[2]                     // Código de Barra
	Replace SE1->E1_CODDIG   with aDados[3]                     // Linha Digitável

	MsUnLock()
	SE1->(DbCloseArea())

	//Atualiza SEE
	//Tratar faixa final de numeração
	//Buscando parâmetros de banco  e atualizando o array de bancos
	If bPulou == .F.

		dbSelectArea("SEE")
		dbSetOrder(1)
		dbSeek( xFilial("SEE") + aBancos[1] + aBancos[10] + aBancos[9]  +  '001',  .T.)

		RecLock("SEE",.F.)

		If cBanco <> '756'
			cFxAtu :=  StrZero((1 + Val(SUBSTR(SEE->EE_FAXATU,1, 12))),12)
		Else
			cFxAtu :=  StrZero((1 + Val(SUBSTR(SEE->EE_FAXATU,1, 7))),7)
		endif

		Replace SEE->EE_FAXATU   with cFxAtu   //faixa atual
		SEE->(DbCloseArea())

	endif

Return

//----------------------------------------------------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} BuscaBord
description
//Cria  borderô 
@type function
@version  
@author Igor Guimarães
@since 8/16/2024
@param cBanco, character, param_description
@param cAgencia, character, param_description
@param cConta, character, param_description
@param cChave, character, param_description
@return variant, return_description
/*/
Static Function BuscaBord(cBanco, cAgencia, cConta, cChave)

	//Verifica se há algum borderô em aberto para a data atual
	DbSelectAreA("SEA")
	DbOrderNickName("SEAXXIND")
	DbSeek(xFilial("SEA") + cBanco + cAgencia  + cConta + "R" + dtos(ddatabase)) //HÁ ALGUM BORDERÔ DESSE BANCO NO DIA ATUAL?

	cNumBor := ""

	While SEA->(!Eof())                    ;
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

		cNumBor := Soma1(GetMV("MV_NUMBORR"),6)
		cNumBor := Replicate("0",6-Len(Alltrim(cNumBor)))+Alltrim(cNumBor)

		While !MayIUseCode("SE1"+xFilial("SE1")+cNumBor)  //verifica se esta na memoria, sendo usado
			// busca o proximo numero disponivel
			cNumBor := Soma1(cNumBor)
		EndDo

		//SÓ ATUALIZA QUANDO O TITULO NAO ESTÁ NO BORDERÔ
		SETMV("MV_NUMBORR",cNumBor)

	EndIf

	SEA->(DbCloseArea())

	//Cria o borderô na SEA
	//-------------------------------------------- Inclui registro na tabela SEA (Titulos enviados a bancos)---------------------------------------
	dbSelectArea("SE1")
	SE1->(dbSetOrder(2))
	DBSeek(XFILIAL("SE1")+cChave, .T.)

	dbSelectArea("SEA")
	dbSetOrder(1) //Verifica se o título existe na SEA
	dbSeek(XFILIAL("SEA")+cNumBor+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO)

	IF ! FOUND()  // Se não encontrou - cria o borderô na tabela SEA

		RecLock("SEA",.T.)
		Replace SEA->EA_FILIAL		with XFILIAL("SEA")
		Replace SEA->EA_PREFIXO		with SE1->E1_PREFIXO
		Replace SEA->EA_NUM			with SE1->E1_NUM
		Replace SEA->EA_PARCELA		with SE1->E1_PARCELA
		Replace SEA->EA_PORTADO		with cBanco
		Replace SEA->EA_AGEDEP		with cAgencia
		Replace SEA->EA_NUMBOR		with cNumBor
		Replace SEA->EA_DATABOR		with dDataBase
		Replace SEA->EA_TIPO	    with SE1->E1_TIPO
		Replace SEA->EA_CART		with "R"
		Replace SEA->EA_NUMCON		with cConta
		Replace SEA->EA_SITUACA		with "1"
		Replace SEA->EA_SITUANT		with "0"
		Replace SEA->EA_FILORIG 	with SE1->E1_FILIAL
		MsUnLock()

	endif

	SEA->(DbCloseArea())

Return cNumBor

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} BOLCANC
description
//Função para cancelamento dos títulos selecionados
@type function
@version  
@author Igor Guimarães
@since 8/16/2024
@return variant, return_description
/*/
User Function BOLCANC(cCodClie)

	Local nX
	Local cMsgMail	:= ""
	Local aTitulos	:= {}
	Local aDados    := {}
	Local aBancos   := {}
	Local lRet      := .T.
	private oBancoBB as Object
	AADD(aBancos, { "756","SICOOB",          "756.bmp"    , "756-0",,,,,,,,"",,,,})
	//Busca os títulos selecionados para cancelamento
	If Len(cMarc) > 0

		If  SUBSTR(cMarc,len(cMarc),Len(cMarc)-1) == ","
			cTitulos := SUBSTR(cMarc,1,Len(cMarc)-1) //Retira a virgula
		Endif

	Else
		cMarc := ""
		MsgInfo("05 - Selecione os boletos que deseja cancelar!", "ATENCAO!")
		return
	endif

	// Abortar o cancelamento
	IF ! MsgYesNo( " Ao escolher esta opção, você deverá DESCARTAR os boletos impressos. Tem certeza que deseja cancelar este boleto?", "ATENÇÃO!")
		return
	endif

	//Realizando a consulta dos títulos selecionados
	cQuery := " SELECT                                          "	+ CRLF
	cQuery += "    SE1.R_E_C_N_O_ SE1RECNO, SE1.*               "	+ CRLF
	cQuery += " FROM "      + RetSqlName("SE1") +  " SE1        "	+ CRLF
	cQuery += " WHERE SE1.E1_FILIAL = '" + xFilial("SE1") + "'	" 	+ CRLF
	cQuery += "	  AND SE1.R_E_C_N_O_ IN (" + cTitulos + ")  	"	+ CRLF
	cQuery += " ORDER BY E1_NUM, E1_PARCELA						"	+ CRLF

	If Select("QRY1") <> 0
		QRY1->(DbCloseArea())
	EndIf

	TCQUERY cQuery NEW ALIAS "QRY1"

	While QRY1->(!Eof())
		aDados    := {}

		cUpd := "	UPDATE " + RetSqlName("SE1")
		cUpd += "	SET	E1_NUMBCO   = '',	" /* nosso numero	*/
		cUpd += "		E1_NOSNUM   = '',	" /* nosso numero	*/
		cUpd += "		E1_PORTADO	= '',	" /* codigo banco	*/
		cUpd += "		E1_AGEDEP 	= '',	" /* agencia sem DV	*/
		cUpd += "		E1_CONTA  	= '',	" /* conta sem DV	*/
		cUpd += "		E1_SITUACA	= '0',	" /* Situação do Título - 0=Carteira;1=Cob.Simples;2=Descontada;3=Caucionada;4=Vinculada;5=Advogado;6=Judicial*/
		cUpd += "		E1_XXBOIMP  = 'N',	" /* Coloca como ja impresso*/
		cUpd += "		E1_NUMBOR   = '',	" /* Numero Borderô	*/
		cUpd += "		E1_DATABOR  = '',	" /* Data do Borderô	*/
		cUpd += "		E1_MOVIMEN  = '',	" /* Data da movimentação	*/
		cUpd += "		E1_OK       = '',	" /* Limpa a marca da seleção	*/
		cUpd += "		E1_IDCNAB   = '', 	" /* ID CNAB */
		cUpd += "		E1_XQRCODE   = '' 	" /* QRCODE */
		cUpd += "	WHERE E1_FILIAL = '" + xFilial("SE1") 		+ "'"
		cUpd += "		AND E1_CLIENTE = '" + QRY1->E1_CLIENTE	+ "'"
		cUpd += "		AND E1_LOJA = '" 	+ QRY1->E1_LOJA 	+ "'"
		cUpd += "		AND E1_PREFIXO ='"	+ QRY1->E1_PREFIXO	+ "'"
		cUpd += "		AND E1_NUM = '"		+ QRY1->E1_NUM 		+ "'"
		cUpd += "		AND E1_PARCELA = '" + QRY1->E1_PARCELA	+ "'"
		cUpd += "		AND E1_TIPO = '" 	+ QRY1->E1_TIPO		+ "'"
		cUpd += "		AND D_E_L_E_T_=  '' "
//Buscando parâmetros de banco  e atualizando o array de bancos
		dbSelectArea("SEE")
		dbSetOrder(1)   // EE_FILIAL  	+ EE_CODIGO + EE_AGENCIA + EE_CONTA +   EE_SUBCTA
		dbSeek(         XFILIAL("SEE")	+ QRY1->E1_PORTADO    + QRY1->E1_AGEDEP   + QRY1->E1_CONTA   +  '001',     .T.)
		cBanco   := QRY1->E1_PORTADO
		cAgencia := QRY1->E1_AGEDEP
		cConta   := QRY1->E1_CONTA
		//tratando parâmetros do banco
		nDvAgencia      	:=  alltrim(SEE->EE_DVAGE)
		NDvConta        	:=  alltrim(SEE->EE_DVCTA)
		cCodced		  		:=  alltrim(QRY1->E1_CONTA) + NdvConta
		cCodEmp         	:=  alltrim(SEE->EE_CODEMP)
		cFaixaAtu       	:=  alltrim(SEE->EE_FAXATU)
		cFaixaFim       	:=  alltrim(SEE->EE_FAXFIM)
		cCarteira       	:=  alltrim(SEE->EE_XXCARTE)
		cMens1          	:=  alltrim(SEE->EE_XXMENS1)
		cJuros          	:=  SEE->EE_XXTXJUR
		cJurDia         	:=  SEE->EE_XXTXJDI
		SEE->(DbCloseArea())

		//Atualizando vetor de dados do banco
		aBancos[1][5]	:= nDvAgencia
		aBancos[1][6]  	:= NDvConta
		aBancos[1][7] 	:= cCodced
		aBancos[1][8]  	:= cCodEmp
		aBancos[1][9] 	:= cConta
		aBancos[1][10] 	:= cAgencia
		aBancos[1][12] 	:= cCarteira
		aBancos[1][13] 	:= cFaixaFim

		Aadd(aDados,"")
		Aadd(aDados,"")
		Aadd(aDados,QRY1->SE1RECNO)
		//Verificando se o título já foi transferido  - somente para títulos impressos
		If ! Empty(QRY1->E1_NUMBOR)

			dbSelectArea("SEA")
			dbSetOrder(1) //Verifica se o título existe na SEA
			IF dbSeek(XFILIAL("SEA") + QRY1->E1_NUMBOR + QRY1->E1_PREFIXO + QRY1->E1_NUM + QRY1->E1_PARCELA + QRY1->E1_TIPO, .T.)

				//Não foi enviado ao banco irá cancelar o título
				IF SEA->EA_TRANSF <> "S"

					//Cancelando na SEA - colocando o registro como cancelado
					RecLock("SEA",.F.)
					dbDelete()
					MsUnLock()

					IF QRY1->E1_PORTADO == "756"//sicoob
						lRet := U_BEWS0002("EXC",,,aBancos,1,,,aDados, , , , cCodClie)
						If !lRet
							MsgStop("09 - Erro ao cancelar boleto " + QRY1->E1_NUM + " Parcela: " + QRY1->E1_PARCELA  + " junto ao SICOOB . Comunique a Equipe Protheus!", "ATENCAO!")
						EndIf
					EndIf

					// Cancelamento na SE1
					If TcSqlExec(cUpd) < 0
						MsgStop("06 - Erro ao cancelar boleto " + QRY1->E1_NUM + " Parcela: " + QRY1->E1_PARCELA  + ". Comunique a Equipe Protheus!", "ATENCAO!")
					ELSE
						aadd(aTitulos, {SE1->E1_NUM, SE1->E1_NOSNUM, SE1->E1_CLIENTE, SE1->E1_NOMCLI })
					EndIf

					// Já foi registrado no banco.
				Else
					MsgAlert("07 - O boleto " + QRY1->E1_NUM + " Parcela: " + QRY1->E1_PARCELA  + " não pode ser cancelado pois já foi enviado o arquivo de remessa para o banco!", "ATENCAO!")
					SEA->(dbCloseArea())
					QRY1->(dbSkip())
					Loop
				endif

				SEA->(DbCloseArea())
			Else
				IF QRY1->E1_PORTADO == "756" //sicoob
					lRet := U_BEWS0002("EXC",,,aBancos,1,,,aDados, , , , cCodClie)
					If !lRet
						MsgStop("09 - Erro ao cancelar boleto " + QRY1->E1_NUM + " Parcela: " + QRY1->E1_PARCELA  + " junto ao SICOOB . Comunique a Equipe Protheus!", "ATENCAO!")
					EndIf
				EndIf
			ENDIF

			//Ainda não gerou borderô ou cancelou titulo do borderô - poderá excluir
		Else
			if QRY1->E1_PORTADO == "756" //sicoob
				//Realizando o cancelamento junto ao sicoob
				lRet := U_BEWS0002("EXC",,,aBancos,1,,,aDados, , , , cCodClie)
				If !lRet
					MsgStop("09 - Erro ao cancelar boleto " + QRY1->E1_NUM + " Parcela: " + QRY1->E1_PARCELA  + " junto ao SICOOB . Comunique a Equipe Protheus!", "ATENCAO!")
				EndIf
			elseif QRY1->E1_PORTADO == "001" //banco do brasil
				//Realizando o cancelamento junto ao banco do brasil
				U_IntegBB(@oBancoBB,cBanco, Alltrim(cAgencia), Alltrim(cConta))
				lRet := oBancoBB:excluiboletos( Alltrim(QRY1->E1_NOSNUM))
				If !lRet
					if AttIsMemberOf(oBancoBB:CRESULT,"errors")
						MsgStop("09 - Erro ao cancelar boleto " + QRY1->E1_NUM + " Parcela: " + QRY1->E1_PARCELA  + " - " + DecodeUTF8(oBancoBB:CRESULT:ERRORS[1]['MESSAGE'], "cp1252"), "ATENCAO!")
					else
						MsgStop("09 - Erro ao cancelar boleto " + QRY1->E1_NUM + " Parcela: " + QRY1->E1_PARCELA  + " junto ao BANCO DO BRASIL . Comunique a Equipe Protheus!", "ATENCAO!")
					endif
				EndIf
			endif
			if lRet
				If TcSqlExec(cUpd) < 0
					MsgStop("08 - Erro ao cancelar boleto " + QRY1->E1_NUM + " Parcela: " + QRY1->E1_PARCELA  + ". Comunique a Equipe Protheus!", "ATENCAO!")
				else
					aadd(aTitulos, {SE1->E1_NUM, SE1->E1_NOSNUM, SE1->E1_CLIENTE, SE1->E1_NOMCLI })
				EndIf
			EndIf
		endif

		QRY1->(dbSkip())

	End Do

	cMsgMail := " O(s) boleto(s) abaixo foram cancelado(s) por <b>" + UsrRetName(RetCodUsr()) + "</b> no ambiente " + GetEnvServer() + ": <br><lu>"

	for nX := 1 to len(aTitulos)
		cMsgMail += "<BR><li> <b>NF:</b> " + aTitulos[nX][1] + "| <b>Nosso Número: </b>" + aTitulos[nX][2];
			+	" | <b>Cliente:</b> " + aTitulos[nX][3] + " - " + aTitulos[nX][4] + "</li>"
	next nX

	cMsgMail += "</lu> <BR>É muito importante certificar-se que os boletos impressos foram fisicamente DESCARTADOS. "

	IIF(! EMPTY(aTitulos), U_BIOPADEM(GETMV("MV_XXFAT21"),;
		"[PROTHEUS] Cancelamento de Boleto - " + GetEnvServer(),;
		cMsgMail, "<center>Cancelamento de Boleto</center>"), )

	cMarc := ""
	oMark:MarkRec(.F.)
	oMark:Refresh()

	U_NOPRINT()

Return

/*/{Protheus.doc} VerNCC
description

** Consulta na SE1 todos os clientes que possuem NCC em aberto  **
** e compara com os boletos que ainda não foram impresso.		**

@type function
@version  
@author Igor Guimarães
@since 8/16/2024
@return variant, return_description
/*/
User Function VerNCC()

	local cMensagem := ""
	Local cQuery 	:= ""
	Local cDataInicio := '20240918'
	cQuery := " SELECT SE1NCC.E1_CLIENTE, SA1.A1_NOME, E1_NUM,                  " + CRLF
	cQuery += " 	 	CASE                                                    " + CRLF
	cQuery += " 	 	 	WHEN E1_XXTPDEV = '1' THEN 'Negociação Especial'    " + CRLF
	cQuery += " 	 	 	WHEN E1_XXTPDEV = '2' THEN 'Avaria / Remanescente'  " + CRLF
	cQuery += " 	 		ELSE ' - '                                          " + CRLF
	cQuery += " 	 	END AS TIPO                                             " + CRLF
	cQuery += " FROM  " + RetSqlName("SE1") + "    AS SE1NCC                    " + CRLF
	cQuery += " INNER JOIN " + RetSqlName("SA1") + " AS SA1						" + CRLF
	cQuery += "						ON SE1NCC.E1_FILIAL = SA1.A1_FILIAL        	" + CRLF
	cQuery += " 					AND SE1NCC.E1_CLIENTE = SA1.A1_COD         	" + CRLF
	cQuery += " 					AND SE1NCC.D_E_L_E_T_ = SA1.D_E_L_E_T_     	" + CRLF
	cQuery += " WHERE SE1NCC.D_E_L_E_T_ <> '*'                                 	" + CRLF
	cQuery += "             AND SE1NCC.E1_FILIAL = '" + xFilial("SE1") + "'    	" + CRLF
	cQuery += " 	       		AND SE1NCC.E1_TIPO = 'NCC'                     	" + CRLF
	cQuery += " 	       		AND SE1NCC.E1_SALDO > 0                        	" + CRLF
	cQuery += " 	       		AND SE1NCC.E1_BAIXA = ''                       	" + CRLF
	cQuery += "             AND SE1NCC.E1_CLIENTE IN (                         	" + CRLF
	cQuery += "                 SELECT E1_CLIENTE                              	" + CRLF
	cQuery += "             	 FROM  " + RetSqlName("SE1") + "   AS SE1      	" + CRLF
	cQuery += "             	 WHERE E1_FILIAL = '" + xFilial("SE1") + "'    	" + CRLF
	cQuery += "                   	AND  SE1.E1_TIPO = 'NF'                    	" + CRLF
	cQuery += "                   	AND SE1.E1_XXBOIMP <> 'S'                   " + CRLF
	cQuery += "             	  	AND SE1.E1_SALDO > 0                       	" + CRLF
	cQuery += "             	  	AND SE1.E1_EMISSAO >= '"+cDataInicio + "'  	" + CRLF
	cQuery += "             	  	AND SE1.D_E_L_E_T_=''                      	" + CRLF
	cQuery += "             	  	AND RTRIM(SE1.E1_IDCNAB)=''                	" + CRLF
	cQuery += "             	  	AND (SE1.E1_PARCELA='1'                    	" + CRLF
	cQuery += "             				OR SE1.E1_PARCELA='01'))           	" + CRLF
	cQuery += " GROUP BY SE1NCC.E1_CLIENTE, SA1.A1_NOME, E1_NUM, 				" + CRLF
	cQuery += "			CASE                  									" + CRLF
	cQuery += " 	 	 	WHEN E1_XXTPDEV = '1' THEN 'Negociação Especial'   	" + CRLF
	cQuery += " 	 	 	WHEN E1_XXTPDEV = '2' THEN 'Avaria / Remanescente' 	" + CRLF
	cQuery += " 	 		ELSE ' - '                                         	" + CRLF
	cQuery += " 	 	END                                                    	" + CRLF

	// Grava a consulta no protheus_data\logbio\
	MemoWrite( SuperGetMV("BE_LOGDIR", , "\logbio\") + 'BIOFIN03_VERNCC' + "_cQry.sql", cQuery  )


	If Select('QRY') <> 0
		QRY->(DbCloseArea())
	endif

	TCQUERY cQuery NEW ALIAS 'QRY'

	if QRY->(EOF())
		MsgInfo('Não há nenhuma NCC para ser compensada com os boletos não impressos.', 'Não há NCCs')
	else

		cMensagem := "<b> Você pode compensar as NCC(s) do(s) seguinte(s) cliente(s):</b>"
		cMensagem += "<ul>"

		Do While QRY->(!Eof())
			cMensagem += "<li> " + QRY->E1_CLIENTE + " - " + Capital(Alltrim(QRY->A1_NOME)) + " - " + QRY->TIPO +  " - " + QRY->E1_NUM +  ".</li>"
			QRY->(!DbSkip())
		End do

		cMensagem += "</ul>"
		MsgInfo(cMensagem, "NCCs em aberto: ")

	endif

	QRY->(DbCloseArea())

Return(.T.)

/*/{Protheus.doc} GetBancos
description
@type function
@version  
@author Igor Guimarães
@since 10/31/2025
@return variant, return_description
/*/
Static function GetBancos()

	Local cTMPSEE := GetNextAlias()
	Local nIndex := 0

	BeginSql Alias cTMPSEE

		SELECT EE_CODIGO, 
					 EE_CODEMP, 
					 EE_CONTA, 
					 EE_DVCTA, 
					 EE_AGENCIA, 
					 EE_DVAGE, 
					 EE_XXCARTE, 
					 EE_XXMENS1, 
					 EE_XXTXJUR, 
					 EE_XXTXJDI, 
					 EE_FAXATU, 
					 EE_FAXFIM, 
					 EE_DIASREC,
					 EE_NUMCTR, 
					 EE_CODCART, 
					 EE_TIPCART,
					 EE_DIASPRT,
					 EE_TABELA,
					 A6_NOME
					 FROM %table:SEE% SEE
					 INNER JOIN %table:SA6% SA6 on
						SA6.D_E_L_E_T_ <> '*'
						and A6_FILIAL = EE_FILIAL
						AND EE_CODIGO = A6_COD
						AND EE_AGENCIA = A6_AGENCIA
						AND EE_CONTA = A6_NUMCON
					 WHERE SEE.D_E_L_E_T_ <> '*'
					 AND SEE.EE_SUBCTA = '001'
	EndSql

	While (cTMPSEE)->(!Eof())
		nIndex++
		if nIndex == 1
			cCodBco := Alltrim((cTMPSEE)->EE_CODIGO)
			cCodAge := Alltrim((cTMPSEE)->EE_AGENCIA)
			cCodCta := Alltrim((cTMPSEE)->EE_CONTA)
			cNomeBco := Alltrim((cTMPSEE)->A6_NOME)
		endif

		AADD(aBcosApt, { (cTMPSEE)->EE_CODIGO, (cTMPSEE)->EE_AGENCIA, (cTMPSEE)->EE_DVAGE, (cTMPSEE)->EE_CONTA, (cTMPSEE)->EE_DVCTA, (cTMPSEE)->EE_XXCARTE, (cTMPSEE)->EE_FAXATU, (cTMPSEE)->EE_FAXFIM, (cTMPSEE)->EE_XXMENS1, (cTMPSEE)->EE_XXTXJUR, (cTMPSEE)->EE_XXTXJDI, (cTMPSEE)->EE_DIASREC, (cTMPSEE)->EE_NUMCTR, (cTMPSEE)->EE_CODCART, (cTMPSEE)->EE_TIPCART, (cTMPSEE)->EE_DIASPRT, (cTMPSEE)->EE_TABELA } )

		aadd(aRelBco, Alltrim(EE_CODIGO) +" - "+ Padr(Alltrim((cTMPSEE)->EE_AGENCIA),TamSX3("EE_AGENCIA")[1]) + Padr(Alltrim((cTMPSEE)->EE_DVAGE),TamSX3("EE_DVAGE")[1]) + " - "+ Padr(Alltrim((cTMPSEE)->EE_CONTA),TamSX3("EE_CONTA")[1]) +  Padr(Alltrim((cTMPSEE)->EE_DVCTA),TamSX3("EE_DVCTA")[1]) + " - " + Padr(Alltrim((cTMPSEE)->A6_NOME),TamSX3("A6_NOME")[1]) )
		(cTMPSEE)->(DbSkip())

	EndDo
	(cTMPSEE)->(DbCloseArea())
Return
/*/{Protheus.doc} setBanco
description
@type function
@version  
@author Igor Guimarães
@since 10/31/2025
@return variant, return_description		
/*/
static function setBanco()

	Local cCodBkp := cCodBco
	cCodBco := left(cCodBkp,3)
	cCodAge := Substr(cCodBkp,7,4)
	cCodCta := Alltrim(Substr(cCodBkp,16,10))
	cNomeBco := Alltrim(Substr(cCodBkp,30,Len(cCodBkp)))

	cBanco   := cCodBco
	cAgencia := Padr(cCodAge, TamSX3("EE_AGENCIA")[1])
	cConta   := Padr(cCodCta, TamSX3("EE_CONTA"	 )[1])


	oCodBco:Refresh()
	oCodAge:Refresh()
	oCodCta:Refresh()
	oNomeBco:Refresh()

return


/*/{Protheus.doc} ImpBolBB
Imprime Boleto Banco do Brasil
@type function
@version 1.1
@author Igor Guimarães
@since 11/4/2025
@return variant, return_description
/*/

User Function ImpBolBB(nOpc)
	Local aArea      := GetArea()
	Local oBancoBB as object
	Local oPrn		 as object
	Local cFilePrint := ""
	Local cTMPSE1    := GetNextAlias()
	Local _cCodfil   := xFilial("SE1")
	Local _cFiltro   := ""
	Local cArqBs64   := ""
	Local lEspera	   := .T.
	Local cPath 	   := GetTempPath() + "totvsprinter\"
	Local nI         := 0

	cMarc := substr(cMarc,1,Len(cMarc)-1) //Retira a virgula final

	IF !Empty(cMarc)
		_cFiltro := " SE1.R_E_C_N_O_ IN ( " + cMarc + " )"
		_cFiltro := "% " + _cFiltro + " %"
		BeginSql Alias cTMPSE1
		SELECT SE1.E1_PARCELA, 
			   SE1.E1_PREFIXO, 
			   SE1.E1_NUM, 
			   SE1.E1_TIPO, 
			   SE1.E1_CLIENTE, 
			   SE1.E1_LOJA, 
			   SE1.E1_NOSNUM
		from %table:SE1% SE1
		where SE1.E1_FILIAL = %Exp:_cCodfil%
		AND ( %Exp:_cFiltro% )
		ORDER BY E1_NUM, E1_PARCELA
		EndSql

		U_IntegBB(@oBancoBB,cBanco, cCodAge, cCodCta)

		WHILE (cTMPSE1)->(!Eof())
			if nOpc == 1

				oBancoBB:imprimeboletos((cTMPSE1)->E1_PREFIXO, (cTMPSE1)->E1_NUM, (cTMPSE1)->E1_PARCELA, (cTMPSE1)->E1_TIPO, oPrn, .T./*gera BasePDF */,cPath, cFilePrint)

			elseif nOpc == 2
				lSucess :=oBancoBB:consultapix(Alltrim((cTMPSE1)->E1_NOSNUM))
				if lSucess
					lEspera := .F.
				endif
			elseif nOpc == 3
				lSucess := oBancoBB:consultaBoleto(Alltrim(SE1->E1_NUMBCO))
				if lSucess
					lEspera := .F.
				endif
			elseif nOpc == 4

				cFilePrint := strtran("BOL_" + Alltrim((cTMPSE1)->E1_PREFIXO)+"_" + Alltrim((cTMPSE1)->E1_NUM) + Alltrim((cTMPSE1)->E1_PARCELA) + Alltrim((cTMPSE1)->E1_TIPO)  + "_" + AllTrim((cTMPSE1)->E1_CLIENTE) + "_" + AllTrim((cTMPSE1)->E1_LOJA)+"_"+dtos(date())+"_"+time(),":","")

				oPrn := FWMSPrinter():New(cFilePrint + ".PDF",IMP_PDF,.T.,,.T.)
				oBancoBB:imprimeboletos((cTMPSE1)->E1_PREFIXO, (cTMPSE1)->E1_NUM, (cTMPSE1)->E1_PARCELA, (cTMPSE1)->E1_TIPO, oPrn, .F./*gera BasePDF */,cPath, cFilePrint)
				oPrn:SetViewPDF(.T.)
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
			endif
			(cTMPSE1)->(DbSkip())
		EndDo
		(cTMPSE1)->(DbCloseArea())
	ENDIF
	U_FILTBB()
	oCodBco:Refresh()
	oCodAge:Refresh()
	oCodCta:Refresh()
	oNomeBco:Refresh()
	oMark:Refresh()
	RestArea(aArea)
Return Nil


/*/{Protheus.doc} IntegBB
Cria objeto de integração com o Banco do Brasil
| Código | Sigla | Descrição                          |
| -----: | :---: | ---------------------------------- |
|      1 |   CH  | Cheque                             |
|      2 |   DM  | Duplicata Mercantil                |
|      3 |  DMI  | Duplicata Mercantil por Indicação  |
|      4 |   DS  | Duplicata de Serviço               |
|      5 |  DSI  | Duplicata de Serviço por Indicação |
|      6 |   DR  | Duplicata Rural                    |
|      7 |   LC  | Letra de Câmbio                    |
|      8 |  NCC  | Nota de Crédito Comercial          |
|      9 |  NCE  | Nota de Crédito à Exportação       |
|     10 |  NCI  | Nota de Crédito Industrial         |
|     11 |  NCR  | Nota de Crédito Rural              |
|     12 |   NP  | Nota Promissória                   |
|     13 |  NPR  | Nota Promissória Rural             |
|     14 |   TM  | Triplicata Mercantil               |
|     15 |   TS  | Triplicata de Serviço              |
|     16 |   NS  | Nota de Seguro                     |
|     17 |   RC  | Recibo                             |
|     18 |  FAT  | Fatura                             |
|     19 |  NDB  | Nota de Débito                     |
|     20 |  APS  | Apólice de Seguro                  |
|     21 |   ME  | Mensalidade Escolar                |
|     22 |   PC  | Parcela de Consórcio               |
|     23 |  DAU  | Dívida Ativa da União              |
|     24 |  DAE  | Dívida Ativa do Estado             |
|     25 |  DAM  | Dívida Ativa do Município          |
|     31 |  CART | Cartão de Crédito                  |
|     32 |  BPRO | Boleto Proposta                    |
|     33 |  BAPO | Boleto Aporte                      |
|     99 |  OUT  | Outros                             |

@type function
@version  
@author Igor Guimarães
@since 11/2/2025
@return variant, return_description
/*/
user function IntegBB(oBancoBB,cCodBco, cCodAge, cCodCta)

	//(codigoAgencia as Character, codigoConta as Character, codigoConvenio as Character, numeroVariacaoCarteira as Character, codigoModalidade as Character, numeroCarteira as Character)
	Local aArea      := GetArea()
	Local cIdCliente := "eyJpZCI6ImY3YjgwMjUtOWViYi00YmUxLTk0IiwiY29kaWdvUHVibGljYWRvciI6MCwiY29kaWdvU29mdHdhcmUiOjc1MjE3LCJzZXF1ZW5jaWFsSW5zdGFsYWNhbyI6Mn0"
	Local cURL       := "https://api.bb.com.br/cobrancas/v2"
	Local cAppKey    := "61e42175360c102fb3abbee54097602b"
	Local cCodCart   := ""
	Local cCodConv   := ""
	Local cCodVaria  := "19" //Número da variação da carteira
	Local cCodMod	   := "1" //Domínio: 1 - Simples; 4 - Vinculada.
	Local cCodAceit  := "A" //Código para identificar se o boleto de cobrança foi aceito (reconhecimento da dívida pelo Pagador). Domínio: A - Aceito; N - Não aceito
	Local nTipTit		 := 2 //Duplicata Mercantil
	Local cRecParc   := "N" //Código para identificação da autorização de pagamento parcial do boleto. Domínios: S - SIM N - NÃO
	Local cIndPIX	   := "S" //Código para informar se o boleto terá um QRCode Pix atrelado. Se informado caracter inválido, assumirá 'N'.Domínios: 'S' - QRCODE DINAMICO; 'N' - SEM PIX; OUTRO - SEM PIX
	Local nJuros     := 0.00
	Local cKeyClient := "eyJpZCI6IjQ0YTZmNGItMTcwYS00MGE5LTgxNmEtODIiLCJjb2RpZ29QdWJsaWNhZG9yIjowLCJjb2RpZ29Tb2Z0d2FyZSI6NzUyMTcsInNlcXVlbmNpYWxJbnN0YWxhY2FvIjoyLCJzZXF1ZW5jaWFsQ3JlZGVuY2lhbCI6MSwiYW1iaWVudGUiOiJwcm9kdWNhbyIsImlhdCI6MTcxODk5MzI0ODYxOH0"

	DbSelectArea("SEE")
	DbSetOrder(1)
	DbSeek( xFilial("SEE") + PADR(cCodBco,TamSX3("EE_CODIGO")[1]) + PADR(cCodAge,TamSX3("EE_AGENCIA")[1]) + PADR(cCodCta,TamSX3("EE_CONTA")[1]) +  '001',  .T.)
	cCodCart := Alltrim(SEE->EE_CODCART)
	cCodConv := Alltrim(SEE->EE_CODEMP)
	nJuros   := SEE->EE_XXTXJUR
	oBancoBB := bancodobrasil():new( cCodBco, cCodAge, cCodCta, cCodConv,cCodVaria,cCodMod,cCodCart, cURL, cIdCliente, cKeyClient, cAppKey, cCodAceit, nTipTit, cRecParc, cIndPIX, nJuros)
	RestArea(aArea)
Return

User Function FILTBB()
	cMarc := ""
	oMark:CleanFilter()
	oMark:SetFilterDefault(cFilBB)
	oMark:Refresh()

Return Nil
