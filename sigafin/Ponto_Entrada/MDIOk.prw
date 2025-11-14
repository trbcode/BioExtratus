/*//#########################################################################################
Projeto : POUPEX
Modulo  : SIGACFG
Fonte   : MDIOk
Objetivo: Adiciona Teclas de Atalho para usuários
*///#########################################################################################

#INCLUDE 'TOTVS.CH'
#INCLUDE 'TBICONN.CH'

/*/{Protheus.doc} MDIOk

	Adiciona Teclas de Atalho para usuários

	@author  Robson Rogério Silva
	@since   23/10/2018
/*/
User Function MDIOk()

	Local lLogin    := Type("cEmpAnt") != "U"

	If ! lLogin
		PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01"
	EndIf
	//Adiciona o relatórios PEX no CTRL + F8
	//SetKey( K_CTRL_F8,  {|| ProtectMdi("U_F8PxReport()") } )

	//If FwIsAdmin()
	SetKey( K_CTRL_F12,  {|| ProtectMdi("U_PXRUNPRG()") } )
	//EndIf
Return

/*/{Protheus.doc} ProtectMdi

	Protege a execução de rotina na TRHEAD do MAIN pois a mesma não reabre as SX's quando troca de empresa.

	@author  Robson Rogério Silva
	@since   24-01-2019
/*/

Static Function ProtectMdi(cPrograma)

	Local aDicionarios := RetSxs()
	Local nI

	For nI := 1 To Len(aDicionarios)
		If( Select(aDicionarios[ni][1]) > 0)
			(aDicionarios[ni][1])->(DbCloseArea())
		EndIf
	Next nI

	MsgRun("Preparando ambiente.","Aguarde...", { || aEVal(aDicionarios, {|x| DbSelectArea(x[1])}) })

	&cPrograma
Return

/*/{Protheus.doc} PXRUNPRG

	Executa uma função fora do menu

	@author  Robson Rogério Silva
	@since   17-01-2019
/*/

User Function PXRUNPRG()

	Local cPrograma	:= SPACE(250)//GetMv("LD_PROG") + SPACE(250)
	Local aPergs := {}

	aAdd( aPergs ,{1,"Nome da Função"       , cPrograma                    ,,'.T.',"" ,'.T.',60, .T.})
	aAdd( aPergs ,{4,"Protege execução"  , .T.,"Protege execução",85,,})


	ParamBox( @aPergs , "Processa FUNCAO" , NIL , NIL , NIL , .T. )
	RodaPrg(AllTrim(MV_PAR01))


Return

/*/{Protheus.doc} RodaPrg

	Executa o programa recebido.

	@author  Robson Rogério
	@since   17-01-2019
/*/

Static Function RodaPrg(cPrograma)
	Local cFunName		:= FunName()
	Local cProgramaOld  := cPrograma
	Local nPos          := At("(",cPrograma)
	// Salva bloco de código do tratamento de erro
	Local oError 		:= ErrorBlock({|e| MsgAlert("Mensagem de Erro: " + CRLF + e:Description, "MDIOK.prw")})

	//monta o FunName que precisa para rodar
	cPrograma   := SubStr(cPrograma,1,nPos-1)

	SetFunName(cPrograma)

	If MV_PAR02
		&cProgramaOld
		ErrorBlock(oError)
	Else
		ErrorBlock(oError)
		&cProgramaOld
	EndIf


	SetFunName(cFunName)

Return
