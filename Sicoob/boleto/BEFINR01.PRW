/*//#########################################################################################
Project  : project
Module   : SIGAFIN
Source   : BEFINR01
Objective: Imprimir Boleto Banco do Brasil
*///#########################################################################################

#INCLUDE 'TOTVS.CH'
#INCLUDE "RPTDEF.CH"


/*/{Protheus.doc} GETBOLBB

    Description

    @author  Name
    @example Example
    @param   [Parameter_Name],Parameter_type,Parameter_Description
    @return  Return
    @table   Tables
    @since   31-08-2021
/*/

User Function GETBOLBB()

	Local aArea     := GetArea()
	Local lLogin    := Type("cEmpAnt") != "U"

	Private oBolNota   := Nil

	If !lLogin
		RPCSETENV("01","0201")
	EndIf

	If !ValidPerg()
		Return()
	EndIf

	u_BEFINR01("3  ",MV_PAR01,MV_PAR02)

	RestArea(aArea)
Return

/*/{Protheus.doc} ValidPerg

    Description

    @author  Name
    @example Example
    @param   [Parameter_Name],Parameter_type,Parameter_Description
    @return  Return
    @table   Tables
    @since   31-08-2021
/*/

Static Function ValidPerg()

	Local aPergs    := {}
	Local aRet	    := {}
	Local lRet   := .F.

	aAdd( aPergs ,{1,"Título De:", Space(tamsx3("E1_NUM")[1]),"@!",".T.","SE1",".T.",75,.F. })
	aAdd( aPergs ,{1,"Título Até:", Space(tamsx3("E1_NUM")[1]),"@!",".T.","SE1",".T.",75,.F. })

	lRet   := ParamBox(aPergs ,"Boletos",aRet)

Return lRet

/*/{Protheus.doc} BEFINR01

    Description

    @author  Igor Guimarães
    @example Example
    @param   [Parameter_Name],Parameter_type,Parameter_Description
    @return  Return
    @table   Tables
    @since   30-08-2021
/*/

User Function BEFINR01(cPrefix,cBolDe,cBolAte,cPathPDF,cFilePrint,cCnpj,cNota,cSerie,cCodiC,cLojaC,cDirUser,oBolNota,cBco,cRot)

	Local aArea     := GetArea()
	Local lLogin    := Type("cEmpAnt") != "U"
	Local nVlrAbat  := 0
	Local cChaveSA6 := ""
	Local cTMPSE1   := GetNextAlias()
	Local cBcoCNAB  := ""
	Local cAgeCNAB  := ""
	Local cCtaCNAB  := ""
	Local cNroDoc   := ""
	Local cDatIni   := ""
	Local cDatFim   := ""
	Local cFiltro   := ""
	//Private oQrCode
	Private nJurosD	:= 0
	Private aDadosTit   := {}
	Private aDadosEmp   := {}
	Private aBolText    := {}
	Private aDatSacado  := {}
	Private aDadosBol   := {}
	Private aDadosBanco := {}
	Private aCB_RN_NN   := Array(6)
	Private oFont8    as Object
	Private oFont11n  as Object
	Private oFont11   as Object
	Private oFont10   as Object
	Private oFont10n   as Object
	Private oFont14   as Object
	Private oFont14n  as Object
	Private oFont15   as Object
	Private oFont15n  as Object
	Private oFont16   as Object
	Private oFont16n  as Object
	Private oFont17   as Object
	Private oFont18   as Object
	Private oFont19   as Object
	Private oFont20   as Object
	Private oFont21   as Object
	Private oFont24   as Object
	Private oFont12  as Object
	Private oFont12n as Object
	Private oFont13  as Object
	Private oFont13n as Object

	//-- PTorres - Agosto/2023 - Geração Boleto + Nota Fiscal
	Private cDirUsr1 := cDirUser //GetTempPath(.T.) + "totvsprinter\"
	Private lCopiArq := .F.

	Default cCnpj      := ""
	Default cFilePrint := ""
	Default cPrefix    := PadR("3",TAMSX3("E1_PREFIXO")[1])

	If !lLogin
		RPCSETENV("01","01")
	EndIf

	If !Empty(cCnpj)
		cFiltro := "%  AND A1_CGC = '"+cCnpj+"' %"
	Else
		cFiltro := "% %"
	EndIf

	cDatIni := dtos(FirstYDate(YearSub(date(),1)))
	cDatFim := dtos(LastYDate(date()))

	if Empty(cPrefix)
		cPrefix  := PadR("3",TAMSX3("E1_PREFIXO")[1])
	EndIf

	aBolText    := { Alltrim(MV_PAR18),Alltrim(MV_PAR19),Alltrim(MV_PAR20) }

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

	If cBco == "001"
		cBcoCNAB  := PADR(AllTrim( SuperGETMV( "RL_BCOCNAB",, "001" )),TAMSX3("A6_COD")[1])
		cAgeCNAB  := PADR(AllTrim( SuperGETMV( "RL_AGECNAB",, "3394" )),TAMSX3("A6_AGENCIA")[1])
		cCtaCNAB  := PADR(AllTrim( SuperGETMV( "RL_CTACNAB",, "137777" )),TAMSX3("A6_NUMCON")[1])
	Else
		cCodConv  := "338184"
		cBcoCNAB  := PADR(AllTrim( SuperGETMV( "RL_BCSICOB",, "756" )),TAMSX3("A6_COD")[1])
		cAgeCNAB  := PADR(AllTrim( SuperGETMV( "RL_AGSICOB",, "4030" )),TAMSX3("A6_AGENCIA")[1])
		cCtaCNAB  := PADR(AllTrim( SuperGETMV( "RL_CCSICOB",, "421103" )),TAMSX3("A6_NUMCON")[1])
	EndIf

	cPrefix      := PadR(cPrefix,TamSX3("E1_PREFIXO")[1])
	cNumero     := PadR(cNumero,TamSX3("E1_NUM")[1])
	cChaveSA6 := cBcoCNAB+cAgeCNAB+cCtaCNAB

	If oBolNota == Nil

		If EMPTY(cFilePrint)
			cFilePrint := "BOL_NFE_" + AllTrim(SF2->F2_DOC) + "_" + AllTrim(SF2->F2_SERIE) + "_" + AllTrim(SF2->F2_CLIENTE) + "_" + AllTrim(SF2->F2_LOJA)
		EndIf

		If !ExistDir(cDirUsr1)
			If MakeDir(cDirUsr1) <> 0
				MakeDir(cDirUsr1)
			EndIf
		EndIf

		fErase(cDirUsr1+cFilePrint+".PDF")

		oBolNota := FWMSPrinter():New(cFilePrint + ".PDF",IMP_PDF,.T.,,.T.)
		oBolNota:SetResolution(78)
		oBolNota:cPathPDF := cDirUsr1
		oBolNota:SetPortrait()
		oBolNota:setPaperSize(DMPAPER_A4)
		oBolNota:SetMargin(60,60,60,60)

		oBolNota:nDevice  := 6
		oBolNota:lServer  := .F.
		oBolNota:lViewPDF := .F.
	Else
		oBolNota:lAdjustToLegacy := .T.
	EndIf

	oFont8   := TFontEx():New(oBolNota,"Arial",8,8,.F.,.T.,.F.)
	oFont10  := TFontEx():New(oBolNota,"Arial",10,10,.F.,.T.,.F.)
	oFont10n := TFontEx():New(oBolNota,"Arial",10,10,.T.,.T.,.F.)
	oFont11  := TFontEx():New(oBolNota,"Arial",11,11,.F.,.T.,.F.)
	oFont11n := TFontEx():New(oBolNota,"Arial",11,11,.T.,.T.,.F.)
	oFont12  := TFontEx():New(oBolNota,"Times New Roman",12,12,.F.,.T.,.F.)
	oFont12n := TFontEx():New(oBolNota,"Times New Roman",12,12,.T.,.T.,.F.)
	oFont13  := TFontEx():New(oBolNota,"Times New Roman",13,13,.F.,.T.,.F.)
	oFont13n := TFontEx():New(oBolNota,"Times New Roman",13,13,.T.,.T.,.F.)
	oFont14  := TFontEx():New(oBolNota,"Arial",14,14,.F.,.T.,.F.)
	oFont14n := TFontEx():New(oBolNota,"Arial",14,14,.T.,.T.,.F.)
	oFont15  := TFontEx():New(oBolNota,"Arial",15,15,.F.,.T.,.F.)
	oFont15n := TFontEx():New(oBolNota,"Arial",15,15,.T.,.T.,.F.)
	oFont16  := TFontEx():New(oBolNota,"Arial",16,16,.F.,.T.,.F.)
	oFont16n := TFontEx():New(oBolNota,"Arial",16,16,.T.,.T.,.F.)
	oFont17  := TFontEx():New(oBolNota,"Arial",17,17,.F.,.T.,.F.)
	oFont18  := TFontEx():New(oBolNota,"Arial",18,18,.F.,.T.,.F.)
	oFont19  := TFontEx():New(oBolNota,"Arial",19,19,.F.,.T.,.F.)
	oFont20  := TFontEx():New(oBolNota,"Arial",20,20,.F.,.T.,.F.)
	oFont21  := TFontEx():New(oBolNota,"Arial",21,21,.F.,.T.,.F.)


	oFont24  := TFontEx():New(oBolNota,"Arial",24,24,.F.,.T.,.F.)

	dbSelectArea("SA6")
	dbSetOrder(1)
	dbSeek(xFilial("SA6")+cChaveSA6,.T.)

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
            E1_PORCJUR,
            E1_XPIXURL,
            E1_XPIXID,
            E1_XPIXEMV,
            E1_CODBAR,
            E1_CODDIG,
            E1_VENCREA,
            A1_NOME
        FROM
            %Table:SE1% E1
        INNER JOIN %Table:SA1% A1
        ON A1.D_E_L_E_T_ = ''
            AND LEFT(A1_FILIAL, 2) = LEFT(E1_FILIAL, 2)
            AND A1_LOJA = E1_LOJA
            AND A1_COD = E1_CLIENTE
        WHERE
            E1.E1_NUM >= %Exp:cBolDe%
            and E1.E1_NUM <= %Exp:cBolAte%
            AND E1.E1_PREFIXO = %Exp:cPrefix%
            AND E1.E1_EMISSAO >= %Exp:cDatIni%
            and E1.E1_EMISSAO <= %Exp:cDatFim%
            AND E1.d_e_l_e_t_ = ' '
            AND A1.d_e_l_e_t_ = ' '
            and E1_NUMBCO <> ' ' %exp:cFiltro%
        order by
            E1_PREFIXO,
            E1_NUM,
            E1_PARCELA
	EndSql
	While (cTMPSE1)->(!EOF())

		If Empty((cTMPSE1)->E1_NUMBCO)
			aCB_RN_NN[3] := cCodConv+StrZero(Val(Right(Alltrim((cTMPSE1)->E1_NUM),07)),07) + StrZERO(Val(Alltrim((cTMPSE1)->E1_PARCELA)),3)
		Else
			aCB_RN_NN[3] := Alltrim((cTMPSE1)->E1_NUMBCO)
			If cBco == "001"
				aCB_RN_NN[4] := Alltrim((cTMPSE1)->E1_XPIXURL)
				aCB_RN_NN[5] := Alltrim((cTMPSE1)->E1_XPIXID)
				aCB_RN_NN[6] := Alltrim((cTMPSE1)->E1_XPIXEMV)
			EndIf
			if !Empty((cTMPSE1)->E1_CODBAR)
				aCB_RN_NN[1] := Alltrim((cTMPSE1)->E1_CODBAR)
				aCB_RN_NN[2] := Alltrim((cTMPSE1)->E1_CODDIG)
			EndIF
		EndIF

		If (cTMPSE1)->E1_SALDO <= 0
			(cTMPSE1)->(DBSkip())
			loop
		EndIf

		cNroDoc	:= StrZero(Val(Right(Alltrim((cTMPSE1)->E1_NUM),07)),07) + StrZERO(Val(Alltrim((cTMPSE1)->E1_PARCELA)),3)

		//Posiciona o SA1 (Cliente)
		dbSelectArea("SA1")
		dbSetOrder(1)
		dbSeek(xFilial("SA1")+(cTMPSE1)->E1_CLIENTE+(cTMPSE1)->E1_LOJA)

		If SA1->A1_IMPBOL == "2"
			MsgInfo("O cliente "+AllTrim(SA1->A1_COD )+"-"+SA1->A1_LOJA + " ("+AllTrim(SA1->A1_NOME) +") não está liberado para gerar boleto!","BEFINR01")
			(cTMPSE1)->(DBSkip())
			loop
		EndIf
		If Empty(SA1->A1_ENDCOB)
			aDatSacado   := {AllTrim(SA1->A1_NOME)           ,;      	// [1]Razão Social
			AllTrim(SA1->A1_COD )+"-"+SA1->A1_LOJA           ,;      	// [2]Código
			AllTrim(SA1->A1_END )+"-"+AllTrim(SA1->A1_BAIRRO),;      	// [3]Endereço
			AllTrim(SA1->A1_MUN )                            ,;			// [4]Cidade
			SA1->A1_EST                                      ,;    		// [5]Estado
			SA1->A1_CEP                                      ,;      	// [6]CEP
			SA1->A1_CGC									     ,;			// [7]CGC
			SA1->A1_PESSOA									 } 			// [8]PESSOA
		Else
			aDatSacado   := {AllTrim(SA1->A1_NOME)              ,;   	// [1]Razão Social
			AllTrim(SA1->A1_COD )+"-"+SA1->A1_LOJA              ,;   	// [2]Código
			AllTrim(SA1->A1_ENDCOB)+"-"+AllTrim(SA1->A1_BAIRROC),;   	// [3]Endereço
			AllTrim(SA1->A1_MUNC)	                            ,;   	// [4]Cidade
			SA1->A1_ESTC	                                    ,;   	// [5]Estado
			SA1->A1_CEPC                                        ,;   	// [6]CEP
			SA1->A1_CGC										    ,;		// [7]CGC
			SA1->A1_PESSOA									    }		// [8]PESSOA
		Endif

		nVlrAbat    :=  SomaAbat((cTMPSE1)->E1_PREFIXO,(cTMPSE1)->E1_NUM,(cTMPSE1)->E1_PARCELA,"R",1,,(cTMPSE1)->E1_CLIENTE,(cTMPSE1)->E1_LOJA)
		NJUROSD     := (cTMPSE1)->E1_PORCJUR

		aDadosTit	:= {AllTrim((cTMPSE1)->E1_NUM)+AllTrim((cTMPSE1)->E1_PARCELA)		,;  // [1] Número do título
		(cTMPSE1)->E1_EMISSAO                              	,;  // [2] Data da emissão do título
		dDataBase                    					,;  // [3] Data da emissão do boleto
		(cTMPSE1)->E1_VENCTO                               	,;  // [4] Data do vencimento
		((cTMPSE1)->E1_SALDO-nVlrAbat+ (cTMPSE1)->E1_ACRESC - (cTMPSE1)->E1_DECRESC)                  	,;  // [5] Valor do título
		Alltrim((cTMPSE1)->E1_NUMBCO)                             	,;  // [6] Nosso número (Ver fórmula para calculo)
		(cTMPSE1)->E1_PREFIXO                               	,;  // [7] Prefixo da NF
		(cTMPSE1)->E1_TIPO	                           		}   // [8] Tipo do Titulo

		ImpSicoob(cTMPSE1,oBolNota)

		(cTMPSE1)->(DBSkip())

	Enddo
	oBolNota:lAdjustToLegacy := .F.

	If cRot == "FENVBOL1"
		oBolNota:Print()
	Endif

	RestArea(aArea)
Return

/*/{Protheus.doc} Ret_cBarra

    Descricao

    @author  Nome
    @example Exemplos
    @param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
    @return  Especifica_o_retorno
    @table   Tabelas
    @since   23-09-2023
/*/

Static Function Ret_cBarra(	cPrefixo,cNumero,cParcela,cTipo,cBanco,cAgencia,cConta,cDacCC,cNroDoc,nValor,cCart,cMoeda,cVecto)

	Local cNosso		:= ""
	Local NNUM			:= ""
	Local cCampoL		:= ""
	Local cFatorValor	:= ""
	Local cLivre		:= ""
	Local cDigBarra		:= ""
	Local cBarra		:= ""
	Local cParte1		:= ""
	Local cDig1			:= ""
	Local cParte2		:= ""
	Local cDig2			:= ""
	Local cParte3		:= ""
	Local cDig3			:= ""
	Local cParte4		:= ""
	Local cParte5		:= ""
	Local cDigital		:= ""
	Local aRet			:= {}

	//DEFAULT nValor := 0

	cAgencia:=STRZERO(Val(cAgencia),4)

	cNosso := ""
	//NNUM := STRZERO(Val(cNroDoc),17) Comentado por Felipe Andrews

	dbSelectArea("SM0")
	If SubStr(SM0->M0_CODFIL,01,02) == "01"
		NNUM := "1617038" + STRZERO(Val(cNroDoc),10) //Incluido por Felipe Andrews
	ElseIf SubStr(SM0->M0_CODFIL,01,02) == "02"
		NNUM := "1636847" + STRZERO(Val(cNroDoc),10) //Incluido por Felipe Andrews
	EndIf

	//Nosso Numero
	//cDigNosso  := U_CALC_di9(NNUM) //comentado por Felipe Andrews
	cNosso := NNUM //+ cDigNosso //comentado por Felipe Andrews

	// campo livre			// verificar a conta e carteira
	//			cCampoLqqq := cNosso+substr(e1_agedep,1,4)+STRZERO(VAL(e1_conta),8)+'18'
	cCampoL := NNUM+cAgencia+StrZero(Val(cConta),8)+cCart

	//campo livre do codigo de barra                   // verificar a conta
	If nValor > 0
		cFatorValor  := fator(cVecto)+strzero(nValor*100,10)
	Else
		cFatorValor  := fator(cVecto)+strzero((cTMPSE1)->E1_VALOR*100,10)
	Endif

	//cLivre := cBanco+cMoeda+cFatorValor+cCampoL//Comentado por Felipe Andrews
	cLivre := cBanco+cMoeda+cFatorValor+"000000"+NNUM+cCart//Incluido por Felipe Andrews

	// campo do codigo de barra
	//cDigBarra := U_CALC_5p( cLivre )//Comentado por Felipe Andrews
	cDigBarra := Modulo11_2( cLivre )//Incluido por Felipe Andrews
	cBarra    := Substr(cLivre,1,4)+Alltrim(Str(cDigBarra))+Substr(cLivre,5,40)

	// composicao da linha digitavel
	cParte1  := cBanco+cMoeda
	//cParte1  := cParte1 + SUBSTR(cCampoL,1,5)//Comentado por Felipe Andrews
	cParte1  := cParte1 + SUBSTR(cBarra,20,05)//Incluido por Felipe Andrews
	//cDig1    := U_DIGIT001( cParte1 )//Comentado por Felipe Andrews
	cDig1    := Modulo10( cParte1 )//Incluido por Felipe Andrews
	//cParte2  := SUBSTR(cCampoL,6,10)//Comentado por Felipe Andrews
	cParte2  := SUBSTR(cBarra,25,10)//Incluido por Felipe Andrews
	//cDig2    := U_DIGIT001( cParte2 )//Comentado por Felipe Andrews
	cDig2    := Modulo10( cParte2 )//Incluido por Felipe Andrews
	//cParte3  := SUBSTR(cCampoL,16,10)//Comentado por Felipe Andrews
	cParte3  := SUBSTR(cBarra,35,10)//Incluido por Felipe Andrews
	//cDig3    := U_DIGIT001( cParte3 )//Comentado por Felipe Andrews
	cDig3    := Modulo10( cParte3 )//Incluido por Felipe Andrews
	cParte4  := " "+Alltrim(Str(cDigBarra))+" "
	cParte5  := cFatorValor

	cDigital := substr(cParte1,1,5)+"."+substr(cparte1,6,4)+Alltrim(Str(cDig1))+" "+;
		substr(cParte2,1,5)+"."+substr(cparte2,6,5)+Alltrim(Str(cDig2))+" "+;
		substr(cParte3,1,5)+"."+substr(cparte3,6,5)+Alltrim(Str(cDig3))+" "+;
		cParte4+;
		cParte5

	Aadd(aRet,cBarra)
	Aadd(aRet,cDigital)
	Aadd(aRet,cNosso)
Return aRet


/*/{Protheus.doc} Modulo11_2

    Descricao

    @author  Nome
    @example Exemplos
    @param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
    @return  Especifica_o_retorno
    @table   Tabelas
    @since   23-09-2023
/*/

Static Function Modulo11_2(cData)
	LOCAL L, D, P := 0
	L := Len(cdata)
	D := 0
	P := 1
	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		End
		L := L - 1
	End
	D := 11 - (mod(D,11))
	If (D == 0 .Or. D == 10 .Or. D == 11)
		D := 1 //Incluido por Felipe Andrews
	End

	If (D == 0)
		D := 1
	End

	//Se o resto da divisão for “10”, desprezar a diferença entre o divisor menos o resto que será “10” e considerar o dígito como “P”.
	//Se o resto da divisão for “1”, desprezar a diferença entre o divisor menos o resto que será “10” e considerar o dígito como “P”.
	//Se o resto da divisão for “0”, desprezar a diferença entre o divisor menos o resto que será “0” e considerar o dígito como “0”.

Return(D)


/*/{Protheus.doc} Modulo10

    Descricao

    @author  Nome
    @example Exemplos
    @param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
    @return  Especifica_o_retorno
    @table   Tabelas
    @since   23-09-2023
/*/

Static Function Modulo10(cData)
	LOCAL L,D,P := 0
	LOCAL B     := .F.
	L := Len(cData)
	B := .T.
	D := 0
	While L > 0
		P := Val(SubStr(cData, L, 1))
		If (B)
			P := P * 2
			If P > 9
				P := P - 9
			End
		End
		D := D + P
		L := L - 1
		B := !B
	End
	D := 10 - (Mod(D,10))
	If D = 10
		D := 0
	End
Return(D)


/*/{Protheus.doc} Fator

    Descricao

    @author  Nome
    @example Exemplos
    @param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
    @return  Especifica_o_retorno
    @table   Tabelas
    @since   23-09-2023
/*/

Static function Fator(cVecto)
	If Len(ALLTRIM(SUBSTR(DTOC(stod(cVecto)),7,4))) = 4
		cData := SUBSTR(DTOC(stod(cVecto)),7,4)+SUBSTR(DTOC(stod(cVecto)),4,2)+SUBSTR(DTOC(stod(cVecto)),1,2)
	Else
		cData := "20"+SUBSTR(DTOC(stod(cVecto)),7,2)+SUBSTR(DTOC(stod(cVecto)),4,2)+SUBSTR(DTOC(stod(cVecto)),1,2)
	EndIf
	cFator := STR(1000+(STOD(cData)-STOD("20000703")),4)
	//cFator := STR(1000+(SE1->E1_VENCREA-STOD("20000703")),4)
Return(cFator)


/*/{Protheus.doc} ImpSicoob

    Descricao

    @author  Igor Guimarães
    @example Exemplos
    @param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
    @return  Especifica_o_retorno
    @table   Tabelas
    @since   25-11-2023
/*/

Static Function ImpSicoob(cTMPSE1,oBolNota)

	Local aArea      := GetArea()
	Local lLogin     := Type("cEmpAnt") != "U"
	//Local cFilePrint := "testesicoob"
	Local cMsg01     := ""
	Local cMsg02     := ""
	Local cMsg03     := ""
	Local cMsg04     := ""
	Local cLinhaDig  := substr(aCB_RN_NN[2],1,5)+"."+substr(aCB_RN_NN[2],6,5)+" "+substr(aCB_RN_NN[2],11,5)+"."+substr(aCB_RN_NN[2],16,6)+" "+substr(aCB_RN_NN[2],22,5)+"."+substr(aCB_RN_NN[2],27,6) +" "+substr(aCB_RN_NN[2],33,1)+" "+substr(aCB_RN_NN[2],34,len(aCB_RN_NN[2]))
	// Private cDirUsr1 := GetTempPath(.T.) + "totvsprinter\"
	DEFAULT  cTMPSE1 := ""

	If !lLogin
		RPCSETENV("01","0201")
	EndIf
	//Mensagem padrão do boleto
	cMsg01 += "Este recibo somente terá validade com a autenticação mecânica ou "
	cMsg01 += "acompanhado do recibo de pagamento emitido pelo Banco."

	cMsg02 += "EMITIDO PELA COOPERATIVA CONTRATANTE SEM RESPONSABILIDADE DO BANCOOB COOPERATIVA CONTRATANTE 4030 SICOOB DIVICRED"

	cMsg03 += IIF(!Empty(Alltrim(aBolText[1])),aBolText[1],"ENVIAR PARA CARTÓRIO 05 DIAS ÚTEIS APÓS O VENCIMENTO")
	cMsg04 += IIF(!Empty(Alltrim(aBolText[2])),aBolText[2],"COBRAR MORA DE R$ " + Alltrim(Transform((aDadosTit[5]*nJurosD/100),"@E 99,999,999.99")) + " AO DIA") //Incluido por Felipe Andrews
    /*
    oBolNota := FWMSPrinter():New(cFilePrint + ".PDF",IMP_PDF,.T.,,.T.)
    oFont10  := TFontEx():New(oBolNota,"Times New Roman",10,10,.F.,.T.,.F.)
    oFont11  := TFontEx():New(oBolNota,"Times New Roman",11,11,.F.,.T.,.F.)
    oFont12  := TFontEx():New(oBolNota,"Times New Roman",12,12,.F.,.T.,.F.)
    oFont12n  := TFontEx():New(oBolNota,"Times New Roman",12,12,.T.,.T.,.F.)
    oFont13  := TFontEx():New(oBolNota,"Times New Roman",13,13,.F.,.T.,.F.)
    oFont13n  := TFontEx():New(oBolNota,"Times New Roman",13,13,.T.,.T.,.F.)
    oFont14  := TFontEx():New(oBolNota,"Arial",14,14,.F.,.T.,.F.)
    oFont24  := TFontEx():New(oBolNota,"Arial",24,24,.F.,.T.,.F.)
    oBolNota:SetResolution(78)
    oBolNota:cPathPDF := cDirUsr1
    oBolNota:SetPortrait()
    oBolNota:setPaperSize(DMPAPER_A4)
    oBolNota:SetMargin(60,60,60,60)

    oBolNota:nDevice  := 6
    oBolNota:lServer  := .F.
    oBolNota:lViewPDF := .F.
    */
	oBolNota:StartPage()   // Inicia uma nova página


	// PARTE SUPERIOR DO BOLETO
	oBolNota:SayBitmap(80,50,"sicoob_logo.bmp",0550,0130)

	//primeira grade
	oBolNota:Box( 230, 15, 720, 1550, "-4")
	oBolNota:Box( 230, 1550, 720, 2400, "-4")
	oBolNota:Line( 311.6667, 1550, 311.6667, 2400, ,"-4")
	oBolNota:Line( 393.3333, 1550, 393.3333, 2400, ,"-4")
	oBolNota:Line( 556.6667, 1550, 556.6667, 2400, ,"-4")
	oBolNota:Line( 638.3333, 1550, 638.3333, 2400, ,"-4")
	oBolNota:Line( 230, 1975, 556.6667, 1975, ,"-4") // linha vertical
	oBolNota:Line( 475, 15, 475, 1550, ,"-4")
	oBolNota:Line( 475, 1550, 475, 2400, ,"-4")

	//segunda grade
	oBolNota:Box( 850, 15, 1350, 2400, "-4")
	oBolNota:Line( 931.6667, 15, 931.6667, 2400, ,"-4")
	oBolNota:Line( 850, 1975, 931.6667, 1975, ,"-4") // linha vertical
	oBolNota:Line( 1013.333, 15, 1013.333, 2400, ,"-4")
	oBolNota:Line( 1095, 15, 1095, 2400, ,"-4")
	oBolNota:Line( 1176.667, 15, 1176.667, 2400, ,"-4")
	oBolNota:Line( 1095, 1700, 1176.667, 1700, ,"-4") // linha verticalF
	oBolNota:Line( 1095, 1895, 1176.667, 1895, ,"-4") // linha vertical

	//linha das autenticacao
	oBolNota:Line( 1450, 1300, 1450, 1400, ,"-1")
	oBolNota:Line( 1450, 1300, 1531, 1300, ,"-1") // linha vertical

	oBolNota:Line( 1450, 2300, 1450, 2400, ,"-1")
	oBolNota:Line( 1450, 2400, 1531, 2400, ,"-1") // linha vertical

	// PARTE INFERIOR DO BOLETO
	oBolNota:SayBitmap(1700,50,"sicoob_logo.bmp",0550,0130)

	oBolNota:Box( 2950, 15, 1850, 1750, "-4")
	oBolNota:Box( 2950, 1750, 1850, 2400, "-4")
	oBolNota:Line( 1970, 15, 1970, 2400, ,"-4")
	oBolNota:Line( 2090, 15, 2090, 2400, ,"-4")
	oBolNota:Line( 2210, 15, 2210, 2400, ,"-4")
	oBolNota:Line( 2330, 15, 2330, 2400, ,"-4")

	oBolNota:Line( 2450, 1750, 2450, 2400, ,"-4")
	oBolNota:Line( 2570, 1750, 2570, 2400, ,"-4")
	oBolNota:Line( 2690, 15, 2690, 2400, ,"-5")
	oBolNota:Line( 2810, 1750, 2810, 2400, ,"-4")

	oBolNota:Line( 1770, 650, 1850, 650, ,"-1") // linha vertical
	oBolNota:Line( 1770, 860, 1850, 860, ,"-1") // linha vertical

	oBolNota:Line( 2090, 475, 2330, 475, ,"-1") // linha vertical
	oBolNota:Line( 2090, 950, 2330, 950, ,"-1") // linha vertical
	oBolNota:Line( 2090, 1350, 2330, 1350, ,"-1") // linha vertical

	oBolNota:Line( 2090, 1190, 2210, 1190, ,"-1") // linha vertical
	oBolNota:Line( 2210, 712.5, 2330, 712.5, ,"-1") // linha vertical

	//IMPRESSÃO DOS DADOS FIXOS DO BOLETO

	oBolNota:SayAlign( 230,30,"Beneficiário",oFont10:oFont,200, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 230,1565,"Vencimento",oFont10n:oFont,200, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 230,1990,"Valor do Documento",oFont10n:oFont,500, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 270,30,aDadosEmp[1]+Space(5)+aDadosEmp[6],oFont12:oFont,1500, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 270,1570,DtoC(STOD(aDadosTit[4])),oFont12n:oFont,200, 40, CLR_BLACK, 2, 1 )
	oBolNota:SayAlign( 270,1990,Alltrim(Transform(aDadosTit[5],"@E 99,999,999.99")),oFont12n:oFont,300, 40, CLR_BLACK, 1, 1 )

	oBolNota:SayAlign( 311,1565,"(+) Outros acréscimos",oFont10:oFont,500, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 311,1990,"(+) Mora / Multa",oFont10:oFont,500, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 393,1565,"(-) Desconto / Abatimento",oFont10:oFont,500, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 393,1990,"(-) Outras deduções",oFont10:oFont,500, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 475,1565,"Data de Emissão",oFont10:oFont,500, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 475,1990,"(=) Valor cobrado",oFont10:oFont,500, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 515,1570,DtoC(STOD(aDadosTit[2])),oFont12:oFont,200, 40, CLR_BLACK, 2, 1 )

	oBolNota:SayAlign( 556,1565,"Coop Contr/Cód. Beneficiário",oFont10:oFont,500, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 638,1565,"Nosso Número",oFont10:oFont,500, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 658,1990,Alltrim(aDadosTit[6]),oFont12:oFont,300, 40, CLR_BLACK,1, 1 )

	oBolNota:SayAlign( 475,30,"Instruções (texto de responsabilidade do beneficiário)",oFont10:oFont,1400, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 800,30,"Dados do Pagador",oFont14:oFont,1400, 60, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 850,30,"Nome do pagador",oFont10:oFont,1400, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 850,1990,"Número do Documento",oFont10:oFont,1400, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 890,30,aDatSacado[1],oFont12:oFont,1500, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 890,1985,Alltrim(aDadosTit[1]),oFont12:oFont,300, 40, CLR_BLACK,1, 1 )

	oBolNota:SayAlign( 932,30,"Endereço",oFont10:oFont,1400, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 972,30,AllTrim(SA1->A1_ENDCOB),oFont12:oFont,1500, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 1013,30,"Bairro / Distrito",oFont10:oFont,1400, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 1053,30,AllTrim(SA1->A1_BAIRRO),oFont12:oFont,1500, 40, CLR_BLACK, 0, 1 )


	oBolNota:SayAlign( 1095,30,"Munícipio",oFont10:oFont,1400, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 1095,1715,"UF",oFont10:oFont,1400, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 1095,1910,"CEP",oFont10:oFont,1400, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 1135,30,Alltrim(aDatSacado[4]),oFont12:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 1135,1720,Alltrim(aDatSacado[5]),oFont12:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 1135,1910,Alltrim(Transform(aDatSacado[6],"@r 99.999-999")),oFont12:oFont,800, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 1176,30,"Mensagem Pagador",oFont10:oFont,1400, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 1430,1450,"Autenticação mecânica",oFont13:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 1430,1500,"-",oFont13:oFont,800, 40, CLR_BLACK, 2, 1 )
	oBolNota:SayAlign( 1430,1450,"Recibo do Pagador",oFont13n:oFont,800, 40, CLR_BLACK, 1, 1 )

	oBolNota:SayAlign( 1430,30,cMsg01,oFont14:oFont,1200, 270, CLR_BLACK, 3, 1 )

	oBolNota:SayAlign( 1650,0,"- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -",oFont13:oFont,2400, 40, CLR_BLACK, 2, 1 )

	oBolNota:SayAlign( 1760,480,"756",oFont24:oFont,550, 90, CLR_BLACK, 2, 1 )
	oBolNota:SayAlign( 1780,870,cLinhaDig,oFont15n:oFont,2000, 50, CLR_BLACK, 0, 1 )


	oBolNota:SayAlign( 1850,30,"Local de pagamento",oFont10:oFont,1400, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 1850,1765,"Vencimento",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 1890,30,'PAGÁVEL PREFERENCIALMENTE NAS AGÊNCIAS DO BANCO SICOOB',oFont14:oFont,2000, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 1890,1860,DtoC(STOD(aDadosTit[4])),oFont14:oFont,300, 40, CLR_BLACK,0, 1 )


	oBolNota:SayAlign( 1970,30,"Beneficiário",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 1970,1765,"Cooperativa contratante/Cód. Beneficiário",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 2010,30,aDadosEmp[1],oFont14:oFont,1500, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 2090,30,"Data do Documento",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2090,490,"N. Documento",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2090,965,"Tipo Doc.",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2090,1205,"Aceite",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2090,1365,"Data Processamento",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2090,1765,"Nosso Número",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 2130,40,DtoC(STOD(aDadosTit[2])),oFont14:oFont,300, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2130,500,aDadosTit[1],oFont14:oFont,300, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2130,980,"DM",oFont14:oFont,100, 40, CLR_BLACK,0, 1 )
	oBolNota:SayAlign( 2130,1210,"N",oFont14:oFont,100, 40, CLR_BLACK,0, 1 )
	oBolNota:SayAlign( 2130,1375,DtoC(STOD(aDadosTit[2])),oFont14:oFont,300, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2130,1900,Alltrim(aDadosTit[6]),oFont14:oFont,200, 40, CLR_BLACK,0, 1 )

	oBolNota:SayAlign( 2210,30,"Uso do Banco",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2210,490,"Carteira",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2210,727.5,"Espécie",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2210,965,"Quantidade",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 2210,1365,"Valor",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2250,1370,Alltrim(Transform(aDadosTit[5],"@E 99,999,999.99")),oFont14:oFont,300, 60, CLR_BLACK, 1, 1 )

	oBolNota:SayAlign( 2210,1765,"Valor documento",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2250,1950,Alltrim(Transform(aDadosTit[5],"@E 99,999,999.99")),oFont14:oFont,300, 60, CLR_BLACK, 1, 1 )


	oBolNota:SayAlign( 2330,30,"Instruções (texto de responsabilidade do beneficiário)",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2330,1765,"(-) Desconto / Abatimento",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2450,1765,"(-) Outras deduções",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2570,1765,"(+) Mora / Multa",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 2690,30,"Pagador",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2730,30,aDatSacado[1],oFont13n:oFont,1500, 50, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 2690,1765,"(+) Outros acréscimos",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2810,1765,"(=) Valor cobrado",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 2500,30,cMsg03,oFont10:oFont,1200, 300, CLR_BLACK, 3, 1 )
	oBolNota:SayAlign( 2550,30,cMsg04,oFont10:oFont,1200, 300, CLR_BLACK, 3, 1 )

	oBolNota:SayAlign( 2600,30,cMsg02,oFont10:oFont,1200, 300, CLR_BLACK, 3, 1 )

	oBolNota:SayAlign( 2920,30,"Beneficiário Final",oFont10:oFont,800, 40, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 2960,30,aDadosEmp[1],oFont13n:oFont,1500, 50, CLR_BLACK, 0, 1 )

	oBolNota:SayAlign( 2970,1500,"Autenticação mecânica",oFont11:oFont,800, 40, CLR_BLACK, 0, 1 )
	oBolNota:SayAlign( 2970,1500,"-",oFont11:oFont,800, 40, CLR_BLACK, 2, 1 )
	oBolNota:SayAlign( 2970,1550,"Ficha de compensação",oFont11n:oFont,800, 40, CLR_BLACK, 1, 1 )

	oBolNota:FWMSBAR("INT25" /*cTypeBar*/,63/*nRow*/ ,2.0/*nCol*/, aCB_RN_NN[1]/*cCode*/,oBolNota/*oBolNota*/,.F./*lCheck*/,/*Color*/,.T./*lHorz*/,0.025/*nWidth*/,1.0/*nHeigth*/,.F./*lBanner*/,"Arial"/*cFont*/,NIL/*cMode*/,.F./*lPrint*/,2/*nPFWidth*/,2/*nPFHeigth*/,.F./*lCmtr2Pix*/)

	oBolNota:EndPage()
	// oBolNota:Preview()
	RestArea(aArea)
Return()
