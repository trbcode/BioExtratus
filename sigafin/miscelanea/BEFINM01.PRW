/*//#########################################################################################
Projeto : project
Modulo  : module
Fonte   : BEFINM02
Objetivo: cHAMA ROTINA
*///#########################################################################################

#INCLUDE 'TOTVS.CH'

/*/{Protheus.doc} BEFINM01
Executa baixas dos títulos  Sicoob
@type user function
@author Igor Guimarães
@since 15/08/2024
@version version
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function BEFINM01(cTipo)

	Local aArea     := GetArea()
	Local lLogin    := Type("cEmpAnt") != "U"
	Local nX  		  := 0
	Local cDatIni   := ""
	Local cDatFim   := ""
	Local aBancos   := {}
	Local nPOS      := 1
	Local cBanco   := ""
	Local cAgencia := " "
	Local cConta   := "      "
	Local oBancoBB as Object
	Local oSendMail as Object
	Local lRet 		:= .F.
	Local dDatabkp    := ctod("")
	Local cHtml			:= ""
	Private aParBox := {}
	Private aParRet := {}

	if !lLogin
		RpcSetEnv("01","01","Admin")
	endif

	if alltrim(cTipo) ==''
		cTipo := 'BIO'
	endif

	IF cTipo == 'BIO'
		cBanco   := "756"
		cAgencia := "4108 "
		cConta   := "8429      "
		//cCodClie  := "e24ab947-b2b6-4c55-86fb-2662a014a63b"
		cCodClie  := "e227419d-ce16-43c0-ac2e-a64cea1bd6d5"
	ELSEIF cTipo == 'FUP'
		cBanco   := GetMV("MV_XXFUPBA")
		cAgencia := Padr(GetMV("MV_XXFUPAG"), TamSX3("EE_AGENCIA")[1])
		cConta   := Padr(GetMV("MV_XXFUPCC"), TamSX3("EE_CONTA"	 )[1])
		cCodClie  := "28477a68-ed9d-43a6-8e97-9a161917e7ca"

		// FUPROM - Chikas
	ELSEIF cTipo == 'FUPCHK'
		cBanco   := GetMV("MV_XXFCHBA")
		cAgencia := Padr(GetMV("MV_XXFCHAG"), TamSX3("EE_AGENCIA")[1])
		cConta   := Padr(GetMV("MV_XXFCHCC"), TamSX3("EE_CONTA")[1])
		cCodClie  := "b7e6001d-1131-4687-a8b5-c7262f146f89"
	ELSEIF cTipo == 'BB'
		cBanco	 := "001"
		cAgencia := Padr("3394", TamSX3("EE_AGENCIA")[1])
		cConta   := Padr("105002", TamSX3("EE_CONTA")[1])
		dDatabkp  := dDataBase
		For nX:= 1 to 7
			if datavalida(DATE()-nX) <> DATE()
				cDatIni := STRZERO(DAY(DATE()-nX),2)+"."+STRZERO(MONTH(DATE()-nX),2)+"."+CVALTOCHAR(YEAR(DATE()-nX))
				cDatFim := cDatIni
				dDataBase := DATE()-nX
				EXIT
			EndIf
		Next nX

		U_IntegBB(@oBancoBB,cBanco, cAgencia, cConta)
		lRet := oBancoBB:recebimentoboletos(cDatIni, cDatFim,"B")
		IF lRet .and. !empty(oBancoBB:aRecebidosSucesso)
			FwAlertSuccess("Processamento de baixas do Banco do Brasil concluído com sucesso!", "BEFINM01 - BB")
		ENDIF
		// Enviar email de confirmação


		cHtml += ' 	<!DOCTYPE html>                                                        '
		cHtml += ' <html lang="pt-BR">                                                     '
		cHtml += ' <head>                                                                  '
		cHtml += '   <meta charset="UTF-8" />                                              '
		cHtml += '   <title>Painel Bio Extratus - Exemplo</title>                          '
		cHtml += '   <meta name="viewport" content="width=device-width, initial-scale=1" />'
		cHtml += '   <style>                                                                '
		cHtml += '     * {                                                                  '
		cHtml += '       box-sizing: border-box;                                            '
		cHtml += '       margin: 0;                                                         '
		cHtml += '       padding: 0;                                                        '
		cHtml += '       font-family: Arial, Helvetica, sans-serif;                         '
		cHtml += '     }                                                                    '
		cHtml += '     body {                                                               '
		cHtml += '       background-color: #f5f5f5;                                         '
		cHtml += '       color: #333;                                                       '
		cHtml += '       min-height: 100vh;                                                 '
		cHtml += '       display: flex;                                                     '
		cHtml += '       flex-direction: column;                                            '
		cHtml += '     }                                                                    '
		cHtml += '     header {                                                             '
		cHtml += '       background: #ffffff;                                               '
		cHtml += '       padding: 20px;                                                     '
		cHtml += '       box-shadow: 0 2px 4px rgba(0,0,0,0.08);                            '
		cHtml += '       display: flex;                                                     '
		cHtml += '       justify-content: center;                                           '
		cHtml += '       align-items: center;                                               '
		cHtml += '     }                                                                    '
		cHtml += '     header img {                                                         '
		cHtml += '       max-height: 60px;                                                  '
		cHtml += '     }                                                                    '
		cHtml += '     main {                                                               '
		cHtml += '       flex: 1;                                                           '
		cHtml += '       padding: 20px;                                                     '
		cHtml += '       max-width: 1200px;                                                 '
		cHtml += '       margin: 0 auto;                                                    '
		cHtml += '     }                                                                    '
		cHtml += '     h1 {                                                                 '
		cHtml += '       font-size: 24px;                                                   '
		cHtml += '       margin-bottom: 16px;                                               '
		cHtml += '       text-align: center;                                                '
		cHtml += '     }                                                                    '
		cHtml += '     .description {                                                       '
		cHtml += '       text-align: center;                                                '
		cHtml += '       margin-bottom: 24px;                                               '
		cHtml += '       color: #666;                                                       '
		cHtml += '     }                                                                    '
		cHtml += '     .table-container {                                                   '
		cHtml += '       background: #ffffff;                                               '
		cHtml += '       border-radius: 8px;                                                '
		cHtml += '       padding: 16px;                                                     '
		cHtml += '       box-shadow: 0 2px 6px rgba(0,0,0,0.06);                            '
		cHtml += '       overflow-x: auto;                                                  '
		cHtml += '     }                                                                    '
		cHtml += '     table {                                                              '
		cHtml += '       width: 100%;                                                       '
		cHtml += '       border-collapse: collapse;                                         '
		cHtml += '       min-width: 600px;                                                  '
		cHtml += '     }                                                                    '
		cHtml += '     thead {                                                              '
		cHtml += '       background: #225a2d;                                               '
		cHtml += '       color: #ffffff;                                                    '
		cHtml += '     }                                                                    '
		cHtml += '     th, td {                                                             '
		cHtml += '       padding: 10px 12px;                                                '
		cHtml += '       text-align: left;                                                  '
		cHtml += '       font-size: 14px;                                                   '
		cHtml += '       border-bottom: 1px solid #e0e0e0;                                  '
		cHtml += '     }                                                                    '
		cHtml += '     th {                                                                 '
		cHtml += '       text-transform: uppercase;                                         '
		cHtml += '       font-weight: 600;                                                  '
		cHtml += '       letter-spacing: 0.03em;                                            '
		cHtml += '     }                                                                    '
		cHtml += '     tbody tr:nth-child(even) {                                           '
		cHtml += '       background: #f9f9f9;                                               '
		cHtml += '     }                                                                    '
		cHtml += '     .status {                                                            '
		cHtml += '       padding: 4px 8px;                                                  '
		cHtml += '       border-radius: 12px;                                               '
		cHtml += '       font-size: 12px;                                                   '
		cHtml += '       display: inline-block;                                             '
		cHtml += '     }                                                                    '
		cHtml += '     .status-ativo {                                                      '
		cHtml += '       background: #e1f7e6;                                               '
		cHtml += '       color: #1e7b34;                                                    '
		cHtml += '     }                                                                    '
		cHtml += '     .status-inativo {                                                    '
		cHtml += '       background: #ffe6e6;                                               '
		cHtml += '       color: #c62828;                                                    '
		cHtml += '     }                                                                    '
		cHtml += '     footer {                                                             '
		cHtml += '       text-align: center;                                                '
		cHtml += '       padding: 12px;                                                     '
		cHtml += '       font-size: 12px;                                                   '
		cHtml += '       color: #777;                                                       '
		cHtml += '     }                                                                    '
		cHtml += '   </style>                                                               '
		cHtml += ' </head>                                                                  '
		cHtml += ' <body>                                                                   '
		cHtml += '   <header>                                                               '
		cHtml += '     <!-- Logo da empresa -->                                             '
		cHtml += '     <img                                                                 '
		cHtml += '       src="https://bioextratusvirtual.vtexassets.com/assets/vtex/assets-builder/bioextratusvirtual.bioextratus/1.0.120/logo/bottom-logo___4fa352bac5ff206b4395f37c6fef817c.png"'
		cHtml += '       alt="Logo Bio Extratus"                                             '
		cHtml += '     />                                                                    '
		cHtml += '   </header>                                                               '
		cHtml += '   <main>                                                                  '
		cHtml += '     <h1>Painel de Exemplo - Bio Extratus</h1>                             '
		cHtml += '     <p class="description">                                               '
		cHtml += '       Dados fictícios apenas para demonstração de layout com 5 colunas.   '
		cHtml += '     </p>                                                                  '
		cHtml += '     <div class="table-container">                                         '
		cHtml += '       <table>                                                             '
		cHtml += '         <thead>                                                           '
		cHtml += '           <tr>                                                            '
		cHtml += '             <th>Código</th>                                               '
		cHtml += '             <th>Produto</th>                                              '
		cHtml += '             <th>Categoria</th>                                            '
		cHtml += '             <th>Estoque</th>                                              '
		cHtml += '             <th>Status</th>                                               '
		cHtml += '           </tr>                                                           '
		cHtml += '         </thead>                                                          '
		cHtml += '         <tbody>                                                           '
		cHtml += '           <tr>                                                            '
		cHtml += '             <td>0001</td>                                                 '
		cHtml += '             <td>Shampoo Nutri Cachos</td>                                 '
		cHtml += '             <td>Cabelos Cacheados</td>                                    '
		cHtml += '             <td>120</td>                                                  '
		cHtml += '             <td><span class="status status-ativo">Ativo</span></td>       '
		cHtml += '           </tr>                                                           '
		cHtml += '           <tr>                                                            '
		cHtml += '             <td>0002</td>                                                 '
		cHtml += '             <td>Máscara Hidratante Botica</td>                            '
		cHtml += '             <td>Tratamento</td>                                           '
		cHtml += '             <td>45</td>                                                   '
		cHtml += '             <td><span class="status status-ativo">Ativo</span></td>       '
		cHtml += '           </tr>                                                           '
		cHtml += '           <tr>                                                            '
		cHtml += '             <td>0003</td>                                                 '
		cHtml += '             <td>Condicionador Pós-Química</td>                            '
		cHtml += '             <td>Pós-Química</td>                                          '
		cHtml += '             <td>8</td>                                                    '
		cHtml += '             <td><span class="status status-inativo">Em falta</span></td>  '
		cHtml += '           </tr>                                                           '
		cHtml += '           <tr>                                                            '
		cHtml += '             <td>0004</td>                                                 '
		cHtml += '             <td>Tônico Antiqueda</td>                                     '
		cHtml += '             <td>Tratamento</td>                                           '
		cHtml += '             <td>62</td>                                                   '
		cHtml += '             <td><span class="status status-ativo">Ativo</span></td>       '
		cHtml += '           </tr>                                                           '
		cHtml += '           <tr>                                                            '
		cHtml += '             <td>0005</td>                                                 '
		cHtml += '             <td>Shampoo Kids Suave</td>                                   '
		cHtml += '             <td>Infantil</td>                                             '
		cHtml += '             <td>30</td>                                                   '
		cHtml += '             <td><span class="status status-ativo">Ativo</span></td>       '
		cHtml += '           </tr>                                                           '
		cHtml += '         </tbody>                                                          '
		cHtml += '       </table>                                                            '
		cHtml += '     </div>                                                                '
		cHtml += '   </main>                                                                 '
		cHtml += '   <footer>                                                                '
		cHtml += '     Página de exemplo • Dados mocados • Bio Extratus                      '
		cHtml += '   </footer>                                                               '
		cHtml += ' </body>                                                                   '
		cHtml += ' </html>                                                                   '

		oSendMail := sendMail():New()
		lRet := oSendMail:Send("Confirmação de Baixas - Banco do Brasil", 'trbcode@gmail.com','iglalguimaraes@gmail.com', cHtml )

		dDataBase  := dDatabkp

	ENDIF

	if cTipo <> 'BB'
		AADD(aBancos, { "756","SICOOB","756.bmp","756-0",,,,,,,,"",,,,})    //Sicoob

		//Buscando parâmetros de banco  e atualizando o array de bancos
		dbSelectArea("SEE")
		dbSetOrder(1)   // EE_FILIAL  	+ EE_CODIGO + EE_AGENCIA + EE_CONTA +   EE_SUBCTA
		dbSeek( XFILIAL("SEE")	+ cBanco    + cAgencia   + cConta   +  '001',     .T.)

		aBancos[nPOS][5]	  := alltrim(SEE->EE_DVAGE)
		aBancos[nPOS][6]    :=  alltrim(SEE->EE_DVCTA)
		aBancos[nPOS][7]    :=  alltrim(SEE->EE_CONTA) + alltrim(SEE->EE_DVCTA)
		aBancos[nPOS][8]    :=  alltrim(SEE->EE_CODEMP)
		aBancos[nPOS][9]    :=  cConta
		aBancos[nPOS][10]   :=  cAgencia
		aBancos[nPOS][12]   :=  alltrim(SEE->EE_XXCARTE)
		aBancos[nPOS][13]   :=  alltrim(SEE->EE_FAXFIM)
		aBancos[nPOS][15]   :=  SEE->EE_XXTXJUR
		aBancos[nPOS][16]   :=  SEE->EE_XXTXJDI

		if !IsBlind()
			if !ValidPerg()
				Return()
			endif
			dDtaBx  := MV_PAR01
			cDatIni := dtos(dDtaBx)
			cDatFim := cDatIni
		else
			for nX:= 1 to 7
				if datavalida(DATE()-nX) <> DATE()
					cDatIni := CVALTOCHAR(YEAR(DATE()-nX))+STRZERO(MONTH(DATE()-nX),2)+STRZERO(DAY(DATE()-nX),2)
					dDtaBx := DATE()-nX
					exit
				endif
			Next nX
			cDatFim := cDatIni
		endif

		Processa({|| U_BEWS0002("BAI",,,aBancos,nPOS,,,,dDtaBx,cDatIni,cDatFim, cCodClie)}, "Baixando...")
	EndIf
	RestArea(aArea)
return()


/*/{Protheus.doc} ValidPerg
description
@type function
@version  
@author Igor Guimarães
@since 8/23/2024
@return variant, return_description
/*/
Static Function ValidPerg()

	Local lRet      := .F.
	Local dDataDe   := Date()-1
	Local nX

	for nX:= 1 to 7
		if datavalida(DATE()-nX) <> DATE()
			dDataDe := DATE()-nX
			exit
		endif
	Next nX
	//Adiciona os parametros para a pergunta

	AADD( aParBox , { 1 , "Dt Recebimento"  , dDataDe,  "", ".T.", "", ".T.", 80,  .F.})

	lRet := ParamBox(aParBox ,"Boleto Sicoob",aParRet)
Return lRet
