/*//#########################################################################################
Project  : project
Module   : module
Source   : BEFINM01
Objective: objective
*///#########################################################################################

#INCLUDE 'TOTVS.CH'

/*/{Protheus.doc} BEFINM01

    Gera dados do boleto pra enviar API SICOOB

    @author  Igor Guimarães
    @example Example
    @param      1 - Nota
                2 - Série
                3 - Coódigo do Cliente
                4 - Loja
                5 - Enderço do arquivo
                6 - Objeto de Impressão
                7 - Se Imprime Boleto
    @return  Return
    @table   Tables
    @since   29-05-2024
/*/
User Function BEFINM01(cNota,cSerie,cCodiC,cLojaC,cCamArq,oDANFE,lImpBol)

	Local aAreaNF     := GetArea()
	Local aDadosEmp   := {}
	Local aDadosBanco := {}
	Local aDatSacado  := {}
	Local aDadosTit   := {}
	Local aBolText    := {}
	Local aCB_RN_NN   := Array(6)
	Local cCodConv    := ""
	Local cChaveSA6   := ""
	Local lRetBB      := .F.
	Local cTMPSE1     := GetNextAlias()
	Local cDatIni     := ""
	Local cDatFim     := ""
	Local cCodPort    := ""
	Local _cMVPar01   := ""
	Local _cMVPar02   := ""
	Local _cMVPar03   := ""
	Local _cMVPar07   := Stod(space(8))
	Local _cMVPar08   := Stod(space(8))
	Local _cMVPar18   := ""
	Local _cMVPar19   := ""
	Local _cMVPar20   := ""
	Private lLogin    := Type("cEmpAnt") != "U"
	Private cFilter   := ""
	Private nVlrAbat  := 0
	Private cBcoCNAB  := ""
	Private cAgeCNAB  := ""
	Private cCtaCNAB  := ""

	DEFAULT lImpBol   := .T.

	If !lLogin
		RpcSetEnv("01","01","Admin")
	EndIf

	If Empty(MV_PAR01)
		Pergunte("NFSIGW",.F.)
		MV_PAR01 := ""
		MV_PAR02 := "ZZZZZZZZZ"
		MV_PAR07 := DATE() - 360
		MV_PAR08 := DATE()
	EndIf
	if VALTYPE(MV_PAR07) <>"D"
		Pergunte("NFSIGW",.F.)
	endif

	_cMVPar01 := MV_PAR01
	_cMVPar02 := MV_PAR02
	_cMVPar03 := MV_PAR03
	_cMVPar07 := MV_PAR07
	_cMVPar08 := MV_PAR08
	_cMVPar18 := MV_PAR18
	_cMVPar19 := MV_PAR19
	_cMVPar20 := MV_PAR20

	cCodPort := GetBco(_cMVPar03, _cMVPar01)

	iF !Empty(cCodPort)
		cBco := cCodPort
	EndIF

	If _cMVPar01 <> cNota .and. !Empty(_cMVPar01)
		_cMVPar01 := cNota
		_cMVPar02 := cNota
		_cMVPar03 := cSerie
	endif

	cDatIni     := iif(Empty(_cMVPar07),DtoS(dDataBase),DtoS(_cMVPar07))
	cDatFim     := iif(Empty(_cMVPar08),DtoS(dDataBase),DtoS(_cMVPar08))

	cCodConv  := "338184"
	cBcoCNAB  := PADR(AllTrim( SuperGETMV( "BE_BCSICOB",, "756" )),TAMSX3("A6_COD")[1])
	cAgeCNAB  := PADR(AllTrim( SuperGETMV( "BE_AGSICOB",, "4030" )),TAMSX3("A6_AGENCIA")[1])
	cCtaCNAB  := PADR(AllTrim( SuperGETMV( "BE_CCSICOB",, "421103" )),TAMSX3("A6_NUMCON")[1])

	cChaveSA6 := cBcoCNAB+cAgeCNAB+cCtaCNAB

	aDadosEmp := {	SM0->M0_NOMECOM                                               ,; //[1]Nome da Empresa
	SM0->M0_ENDCOB                                                            ,; //[2]Endereço
	AllTrim(SM0->M0_BAIRCOB)+", "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB ,; //[3]Complemento
	"CEP: "+Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3)             ,; //[4]CEP
	"PABX/FAX: "+SM0->M0_TEL                                                  ,; //[5]Telefones
	"CNPJ: "+Subs(SM0->M0_CGC,1,2)+"."+Subs(SM0->M0_CGC,3,3)+"."+              ; //[6]
	Subs(SM0->M0_CGC,6,3)+"/"+Subs(SM0->M0_CGC,9,4)+"-"+                       ; //[6]
	Subs(SM0->M0_CGC,13,2)                                                    ,; //[6]CGC
	"I.E.: "+Subs(SM0->M0_INSC,1,3)+"."+Subs(SM0->M0_INSC,4,3)+"."+            ; //[7]
	Subs(SM0->M0_INSC,7,3)+"."+Subs(SM0->M0_INSC,10,3)                        }  //[7]I.E

	dbSelectArea("SA6")
	dbSetOrder(1)
	dbSeek(xFilial("SA6")+cChaveSA6,.T.)
	aDadosBanco  := {SA6->A6_COD,; 													   			// [1]Numero do Banco
	SA6->A6_NREDUZ,;  											       	// [2]Nome do Banco
	SUBSTR(SA6->A6_AGENCIA, 1, 4)+"-"+SUBSTR(SA6->A6_AGENCIA, 5, 5),; 	// [3]Agência
	alltrim(SA6->A6_NUMCON),; 	       									// [4]Conta Corrente
	SA6->A6_DVCTA  ,;    	   												// [5]Dígito da conta corrente
	"17"}

	BeginSql Alias cTMPSE1
        SELECT
            E1_PREFIXO,
            E1_NUM,
            E1_PARCELA,
            E1_EMISSAO,
            E1_CLIENTE,
            E1_LOJA,
            E1_NUMBCO,
            E1_VENCTO,
            E1_TIPO,
            E1_VALOR,
            E1_SALDO,
            E1_ACRESC,
            E1_DECRESC,
            E1_AGEDEP E1_CONTA,
            E1_PORTADO,
            E1_HIST,
            E1_XPIXURL,
            E1_XPIXID,
            E1_XPIXEMV,
            E1_CODBAR
        FROM
            %Table:SE1% E1
        WHERE
            E1.E1_NUM >= %Exp:_cMVPar01%
            AND E1.E1_NUM <= %Exp:_cMVPar02%
            AND E1.E1_PREFIXO = %Exp:_cMVPar03%
            AND E1.E1_EMISSAO >= %Exp:cDatIni%
            AND E1.E1_EMISSAO <= %Exp:cDatFim%
            AND E1.E1_TIPO NOT IN ('NCC', 'RA')
            AND E1.d_e_l_e_t_ = ' '
            AND E1.E1_SALDO > 0 //and e1.E1_NUMBCO = ' '
        order by
            E1_PREFIXO,
            E1_NUM,
            E1_PARCELA
	EndSql

	While (cTMPSE1)->(!EOF())
		aCB_RN_NN := Array(6)
		aDadosTit := {}
		//Posiciona o SA1 (Cliente)
		dbSelectArea("SA1")
		dbSetOrder(1)
		dbSeek(xFilial("SA1")+(cTMPSE1)->E1_CLIENTE+(cTMPSE1)->E1_LOJA)

		If SA1->A1_IMPBOL == "2"
			(cTMPSE1)->(DBSkip())
			loop
		EndIf

		If Empty(SA1->A1_ENDCOB)
			aDatSacado   := {AllTrim(SA1->A1_NOME)           ,;      	// [1]Razão Social
			AllTrim(SA1->A1_COD )+"-"+SA1->A1_LOJA           ,;      	// [2]Código
			STRTRAN(AllTrim(SA1->A1_END),"-"," ")                     ,;      	// [3]Endereço
			AllTrim(SA1->A1_MUN )                            ,;			// [4]Cidade
			SA1->A1_EST                                      ,;    		// [5]Estado
			cvaltochar(val(SA1->A1_CEP))                                      ,;      	// [6]CEP
			SA1->A1_CGC									     ,;			// [7]CGC
			SA1->A1_PESSOA									 ,;         // [8]PESSOA
			STRTRAN(AllTrim(SA1->A1_BAIRRO),"-"," ")                  } 			// [9]BAIRRO
		Else
			aDatSacado   := {AllTrim(SA1->A1_NOME)              ,;   	// [1]Razão Social
			AllTrim(SA1->A1_COD )+"-"+SA1->A1_LOJA              ,;   	// [2]Código
			STRTRAN(AllTrim(SA1->A1_ENDCOB),"-"," "),;                       	// [3]Endereço
			AllTrim(SA1->A1_MUNC)	                            ,;   	// [4]Cidade
			SA1->A1_ESTC	                                    ,;   	// [5]Estado
			cvaltochar(val(SA1->A1_CEPC))                                        ,;   	// [6]CEP
			SA1->A1_CGC										    ,;		// [7]CGC
			SA1->A1_PESSOA									    ,;      // [8]PESSOA
			STRTRAN(AllTrim(SA1->A1_BAIRROC),"-"," ")          }		// [9]BAIRRO
		Endif

		aBolText    := { Alltrim(_cMVPar18),Alltrim(_cMVPar19),Alltrim(_cMVPar20) }
		nVlrAbat    :=  SomaAbat((cTMPSE1)->E1_PREFIXO,(cTMPSE1)->E1_NUM,(cTMPSE1)->E1_PARCELA,"R",1,,(cTMPSE1)->E1_CLIENTE,(cTMPSE1)->E1_LOJA)
		If Empty((cTMPSE1)->E1_NUMBCO)
			If cBco == "001"
				aCB_RN_NN[3] := cCodConv+StrZero(Val(Right(Alltrim((cTMPSE1)->E1_NUM),07)),07) + StrZERO(Val(Alltrim((cTMPSE1)->E1_PARCELA)),3)
			EndIf
		Else
			cBco := (cTMPSE1)->E1_PORTADO
			aCB_RN_NN[3] := Alltrim((cTMPSE1)->E1_NUMBCO)
			aCB_RN_NN[4] := Alltrim((cTMPSE1)->E1_XPIXURL)
			aCB_RN_NN[5] := Alltrim((cTMPSE1)->E1_XPIXID)
			aCB_RN_NN[6] := Alltrim((cTMPSE1)->E1_XPIXEMV)
		EndIF

		If (cTMPSE1)->E1_CLIENTE <> '45543915'      //Alexandre - Alteração efetuada para atender o carrefour 01/08/2014
			aDadosTit	:= {AllTrim((cTMPSE1)->E1_NUM)+AllTrim((cTMPSE1)->E1_PARCELA)		,;  // [1] Número do título
			(cTMPSE1)->E1_EMISSAO                              	,;  // [2] Data da emissão do título
			dDataBase                    					,;  // [3] Data da emissão do boleto
			(cTMPSE1)->E1_VENCTO                               	,;  // [4] Data do vencimento
			((cTMPSE1)->E1_SALDO-nVlrAbat+ (cTMPSE1)->E1_ACRESC - (cTMPSE1)->E1_DECRESC)                  	,;  // [5] Valor do título
			aCB_RN_NN[3]                             	,;  // [6] Nosso número (Ver fórmula para calculo)
			(cTMPSE1)->E1_PREFIXO                               	,;  // [7] Prefixo da NF
			(cTMPSE1)->E1_TIPO	                           		}   // [8] Tipo do Titulo
		Else
			aDadosTit	:= {AllTrim((cTMPSE1)->E1_NUM)		,;  // [1] Número do título
			(cTMPSE1)->E1_EMISSAO                              	,;  // [2] Data da emissão do título
			dDataBase                    					,;  // [3] Data da emissão do boleto
			(cTMPSE1)->E1_VENCTO                               	,;  // [4] Data do vencimento
			((cTMPSE1)->E1_SALDO-nVlrAbat+ (cTMPSE1)->E1_ACRESC - (cTMPSE1)->E1_DECRESC)                  	,;  // [5] Valor do título
			aCB_RN_NN[3]                             	,;  // [6] Nosso número (Ver fórmula para calculo)
			(cTMPSE1)->E1_PREFIXO                               	,;  // [7] Prefixo da NF
			(cTMPSE1)->E1_TIPO	                           		}   // [8] Tipo do Titulo
		EndIf

		If Empty((cTMPSE1)->E1_NUMBCO)
			lRetBB := U_RLWS0024("GER",@aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,@aCB_RN_NN)
		Else
			lRetBB := .T.
		EndIF

		If lRetBB
			DbSelectArea("SE1")
			dbSetOrder(1)
			SE1->(DBSeek(xFilial("SE1")+(cTMPSE1)->E1_PREFIXO+(cTMPSE1)->E1_NUM+(cTMPSE1)->E1_PARCELA))
			If (Empty(SE1->E1_NUMBCO) .or. Empty(SE1->E1_AGEDEP) .or. Empty(SE1->E1_CONTA) .or. Empty(SE1->E1_PORTADO))
				If RecLock("SE1",.f.)
					SE1->E1_NUMBCO 	 := aCB_RN_NN[3]  // Nosso número (Ver fórmula para calculo)
					SE1->E1_AGEDEP   := cAgeCNAB
					SE1->E1_CONTA    := cCtaCNAB
					SE1->E1_PORTADO  := cBcoCNAB
					SE1->E1_HIST     := "BOLETO GERADO VIA API"
					SE1->E1_ZBOLENV  := "2" //-- PTorres - Março/2023 - Gravar se o boleto foi registrado ou não!
					IF cBco == "001"
						SE1->E1_XPIXURL  := aCB_RN_NN[4]
						SE1->E1_XPIXID   := aCB_RN_NN[5]
						SE1->E1_XPIXEMV  := aCB_RN_NN[6]
					EndIf
					If !Empty(aCB_RN_NN[1]) .and. Empty(SE1->E1_CODBAR)
						SE1->E1_CODBAR := Alltrim(aCB_RN_NN[1])
						SE1->E1_CODDIG := Alltrim(aCB_RN_NN[2])
					EndIF
					MsUnlock()
				EndIf
			EndIf
		Else
			lImpBol := .F.
			MsgInfo("Boleto não registrado!","BEFINM01")
			//-- PTorres - Março/2023 - Gravar se o boleto foi registrado ou não!
			DbSelectArea("SE1")
			SE1->(DbSetOrder(1))
			SE1->(DbSeek(xFilial("SE1")+(cTMPSE1)->E1_PREFIXO+(cTMPSE1)->E1_NUM+(cTMPSE1)->E1_PARCELA))

			If (Empty(SE1->E1_NUMBCO) .OR. Empty(SE1->E1_AGEDEP) .OR. Empty(SE1->E1_CONTA) .OR. Empty(SE1->E1_PORTADO))
				If RecLock("SE1",.f.)
					SE1->E1_ZBOLENV := "2"
					SE1->(MsUnlock())
				Endif
			Endif
		Endif

		(cTMPSE1)->(DBSkip())
	Enddo

	If lImpBol
		//-- Inicia a impressão do boleto
		If FWIsInCallStack("U_FENVBOL1")
			U_RLFINR05(cSerie,cNota,cNota,"","","",cNota,cSerie,cCodiC,cLojaC,cCamArq,@oDANFE,cBco,"FENVBOL1")
		Else
			U_RLFINR05(_cMVPar03,_cMVPar01,_cMVPar02,"","","",cNota,cSerie,cCodiC,cLojaC,cCamArq,@oDANFE,cBco,"")
		Endif
	EndIf

	//-- Finaliza alias de trabalho
	(cTMPSE1)->(DbCloseArea())

	//-- Restaura a área de trabalho salva
	RestArea(aAreaNF)

Return


/*/{Protheus.doc} GetBco

    Retorna banco portador

    @author  Igor Guimarães
    @example Exemplos
    @param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
    @return  Especifica_o_retorno
    @table   Tabelas
    @since   11-03-2024
/*/

Static Function GetBco(cSerie, cNota)

	Local cRet := ""
	Local cTMPSE1 := GetNextAlias()

	BeginSql Alias cTMPSE1
        SELECT
            E1_PORTADO
        FROM
            SE1010
        WHERE
            e1_num = %Exp:cNota%
            AND E1_SERIE = %Exp:cSerie%
            AND D_E_L_E_T_ = ' '
	EndSql
	if !(cTMPSE1)->(eof())
		cRet := (cTMPSE1)->E1_PORTADO
	EndIf

	(cTMPSE1)->(DbCloseArea())
Return cRet
