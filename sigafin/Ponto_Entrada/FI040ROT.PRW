#INCLUDE 'TOTVS.CH'
#INCLUDE 'TOPCONN.CH'



User Function FI040ROT()
	Local aRotina := AClone(PARAMIXB)

	AAdd(aRotina, {"Alterar Data Limite" , "U_AltDtLim", 0, 3})

Return (aRotina)



User Function AltDtLim()

	Local aArea      := GetArea()
	Local cTMPSE1    := GetNextAlias()
	Local lRet       := .F.
	Local nPOS       := 1
	Local cCodClie   := ""
	Local aDatSacado := {}
	Local aDadosEmp  := {}
	Local aDadosTit  := {}
	Local aDados     :={}
	lOCAL aBolText   := {}

	private aBancos    := {}

	setBanc()
	nPOS := checkBanc('756')

	aDadosEmp := {  Alltrim(SM0->M0_NOMECOM)                                  ,; //[1]Nome da Empresa
	Alltrim(SM0->M0_ENDCOB)                                                   ,; //[2]Endereço
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
            E1_FILIAL,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO, E1_EMISSAO, E1_VENCTO, E1_VENCREA, E1_PORTADO,  E1_AGEDEP, E1_CONTA, E1_NOSNUM, E1_CLIENTE, E1_LOJA, E1_ACRESC, E1_DECRESC, E1_SALDO
        FROM
            %Table:SE1% E1
        WHERE D_E_L_E_T_ = ' '
            AND E1.E1_PORTADO = '756'
            AND E1.E1_SALDO > 0
            AND E1.E1_NUM ='000189984'
            AND E1.E1_VENCREA >= %exp:dDatabase%
            AND E1.E1_XQRCODE <> ' '  
            ORDER BY E1_VENCREA ASC
	EndSql

	while (cTMPSE1)->(!Eof())

		dbSelectArea("SEE")
		dbSetOrder(1)   // EE_FILIAL    + EE_CODIGO + EE_AGENCIA + EE_CONTA +   EE_SUBCTA
		dbSeek(  XFILIAL('SEE') + (cTMPSE1)->E1_PORTADO    + (cTMPSE1)->E1_AGEDEP   + (cTMPSE1)->E1_CONTA   +  '001',     .T.)

		//BIO
		IF ALLTRIM((cTMPSE1)->E1_CONTA) == '8429'
			cCodClie := u_getIdClientSicoob(alltrim((cTMPSE1)->E1_PORTADO), alltrim((cTMPSE1)->E1_AGEDEP), alltrim((cTMPSE1)->E1_CONTA)) //"e24ab947-b2b6-4c55-86fb-2662a014a63b"
			// FUP
		ELSEIF ALLTRIM((cTMPSE1)->E1_CONTA) == '16068'
			cCodClie := u_getIdClientSicoob(alltrim((cTMPSE1)->E1_PORTADO), alltrim((cTMPSE1)->E1_AGEDEP), alltrim((cTMPSE1)->E1_CONTA)) //"28477a68-ed9d-43a6-8e97-9a161917e7ca"
			//FUPCHIK
		ELSEIF ALLTRIM((cTMPSE1)->E1_CONTA) == '39380'
			cCodClie := u_getIdClientSicoob(alltrim((cTMPSE1)->E1_PORTADO), alltrim((cTMPSE1)->E1_AGEDEP), alltrim((cTMPSE1)->E1_CONTA)) //"b7e6001d-1131-4687-a8b5-c7262f146f89"
		ENDIF

		aBancos[nPOS][5]     := alltrim(SEE->EE_DVAGE)
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

		aDadosTit   := {AllTrim((cTMPSE1)->E1_NUM)+AllTrim((cTMPSE1)->E1_PARCELA)   ,;  // [1] Número do título
		(cTMPSE1)->E1_EMISSAO                                               ,;  // [2] Data da emissão do título
		dDataBase                                                       ,;  // [3] Data da emissão do boleto
		(cTMPSE1)->E1_VENCTO                                               ,;  // [4] Data do vencimento
		nValorReal                                                      ,;  // [5] Valor do título
		ALLTRIM((cTMPSE1)->E1_NOSNUM)                                                        ,;  // [6] Nosso número (Ver fórmula para calculo)
		(cTMPSE1)->E1_PREFIXO                                                   ,;  // [7] Prefixo da NF
		(cTMPSE1)->E1_TIPO}

		lRet := U_BEWS0002("ALTLIM",aDadosEmp,aDadosTit,@aBancos,nPOS,aDatSacado,aBolText,@aDados, , , , cCodClie,aDadosTit[6])
		(cTMPSE1)->(dbskip())
	enddo

	(cTMPSE1)->(DbCloseArea())
	RestArea(aArea)
Return lRet



Static Function setBanc()

	// DEFINE PARÂMETROS DE CADA BANCO POSSÝVEL (9)
	// Vide documentação


	AADD(aBancos, { "001","BANCO DO BRASIL", "001.bmp"    , "001-9",,,,,,,,"",,,,,})    //Banco do Brasil
	AADD(aBancos, { "237","BRADESCO",        "237.bmp"    , "237-2",,,,,,,,"",,,,,})    //Bradesco
	AADD(aBancos, { "341","BANCO ITAÚ S.A ", "341.bmp"    , "341-7",,,,,,,,"",,,,,})    //Itau
	AADD(aBancos, { "756","SICOOB",          "756.bmp"    , "756-0",,,,,,,,"",,,,,})    //Sicoob
	AADD(aBancos, { "104","CAIXA",           "104.bmp"    , "104-0",,,,,,,,"",,,,,})    //Caixa

Return


Static Function checkBanc(cBanco)

	Local nPOS := 0
	nPOS := ASCAN(aBancos,{|x| x[1]==cBanco})

Return nPos
