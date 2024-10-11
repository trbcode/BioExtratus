/*/{Protheus.doc} FI040ROT
description
@type function
@version  
@author iglal
@since 10/10/2024
@return variant, return_description
/*/
User Function FI040ROT()

	Local aRotina := AClone(PARAMIXB)

	AAdd(aRotina, {"Títulos Percentuais", "U_AltDtLim()", 0, 3})

Return (aRotina)

/*/{Protheus.doc} nomeFunction
(long_description)
@type user function
@author user
@since 10/10/2024
@version version

@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function AltDtLim()

	Local aArea      := GetArea()
	Local cTMPSE1    := GetNextAlias()
	Local lRet       := .F.
	Local nPOS       := 1
	Local aBancos    := {}
	Local aDatSacado := {}
	Local aDadosEmp  := {}
	Local aDadosTit  := {}
	Local aDados     :={}
	lOCAL aBolText   := {}

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

	BeginSql Alias cTMPSE1
        SELECT
            E1_FILIAL,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO, E1_EMISSAO, E1_VENCTO, E1_VENCREA, E1_PORTADO,  E1_AGEDEP, E1_CONTA, E1_NOSNUM
        FROM
            %Table:SE1% E1
        WHERE
            E1.E1_NUMBCO = %Exp:cNosso%
            AND D_E_L_E_T_ = ' ' 
			AND E1.E1_PORTADO = '756'
			AND E1.E1_SALDO > 0
            AND E1.E1_VENCREA >= dDatabase
            AND E1.E1_XQRCODE <> ' '
	EndSql

	while (cTMPSE1)->(!Eof())

		dbSelectArea("SEE")
		dbSetOrder(1)   // EE_FILIAL  	+ EE_CODIGO + EE_AGENCIA + EE_CONTA +   EE_SUBCTA
		dbSeek(  XFILIAL('SEE')	+ (cTMPSE1)->E1_PORTADO    + (cTMPSE1)->E1_AGEDEP   + (cTMPSE1)->E1_CONTA   +  '001',     .T.)

		aBancos[nPOS][5]	 := alltrim(SEE->EE_DVAGE)
		aBancos[nPOS][6]    :=  alltrim(SEE->EE_DVCTA)
		aBancos[nPOS][7]    :=  alltrim(SEE->EE_CONTA) + alltrim(SEE->EE_DVCTA)
		aBancos[nPOS][8]    :=  alltrim(SEE->EE_CODEMP)
		aBancos[nPOS][9]    :=  (cTMPSE1)->E1_CONTA
		aBancos[nPOS][10]   :=  (cTMPSE1)->E1_AGEDEP
		aBancos[nPOS][12]   :=  alltrim(SEE->EE_XXCARTE)
		aBancos[nPOS][13]   :=  alltrim(SEE->EE_FAXFIM)
		aBancos[nPOS][15]   :=  SEE->EE_XXTXJUR
		aBancos[nPOS][16]   :=  SEE->EE_XXTXJDI
		aBancos[nPOS][17]   :=  SEE->EE_DIASREC

		aDadosTit:= {}

		nVlrAbat    :=  SomaAbat((cTMPSE1)->E1_PREFIXO,(cTMPSE1)->E1_NUM,(cTMPSE1)->E1_PARCELA,"R",1,,(cTMPSE1)->E1_CLIENTE,(cTMPSE1)->E1_LOJA)
		nValorReal  := ((cTMPSE1)->E1_SALDO-nVlrAbat+ (cTMPSE1)->E1_ACRESC - (cTMPSE1)->E1_DECRESC)

		aDadosTit	:= {AllTrim((cTMPSE1)->E1_NUM)+AllTrim((cTMPSE1)->E1_PARCELA)	,;  // [1] Número do título
		(cTMPSE1)->E1_EMISSAO                              	                ,;  // [2] Data da emissão do título
		dDataBase                    					                ,;  // [3] Data da emissão do boleto
		(cTMPSE1)->E1_VENCTO +  aBancos[nPOS][17] ,;  // [4] Data do vencimento
		nValorReal                	                                    ,;  // [5] Valor do título
		(cTMPSE1)->E1_NOSNUM                             	                        ,;  // [6] Nosso número (Ver fórmula para calculo)
		(cTMPSE1)->E1_PREFIXO                               	                ,;  // [7] Prefixo da NF
		(cTMPSE1)->E1_TIPO}

		lRet := U_BEWS0002("ALTLIM",aDadosEmp,aDadosTit,@aBancos,nPOS,aDatSacado,aBolText,@aDados, , , , cCodClie,aDadosTit[6])
		(cTMPSE1)->(dbskip())
	enddo

	(cTMPSE1)->(DbCloseArea())
	RestArea(aArea)
Return lRet
