//Bibliotecas
#Include "Totvs.ch"
#Include "FWMVCDef.ch"
#Include "prtopdef.ch"


/*/{Protheus.doc} User Function BIOFIN2
Boletos
@author ALESSANDRO MAGNO DE PAULA
@since 30/09/2024
@version 1.0
@type function
@obs Codigo gerado automaticamente pelo Autumn Code Maker
@see http://autumncodemaker.com
/*/

User Function BIOFIN24()
	Local aArea := FWGetArea()
    Local aPergs   := {}
	Local xPar1 := DaySub(Date(),1)
	Local xPar2 := Date()   
    Local xPar3 := ""

//Adicionando os parametros do ParamBox
	aAdd(aPergs, {1, "Emissão de:", xPar1,  "", ".T.", "", ".T.", 80,  .T.})
	aAdd(aPergs, {1, "Emissão até:", xPar2,  "", ".T.", "", ".T.", 80,  .T.})

	aAdd(aPergs, {2, "Situação", xPar3, {"1=Não Registrado", "2=Registrado", "3=Todos"}, 090, ".T.", .T.})    

    //Se a pergunta for confirma, chama a tela
    If ParamBox(aPergs, "Informe os parametros")
        fMontaTela()
    EndIf

	FWRestArea(aArea)
Return


/*/{Protheus.doc} fMontaTela
Monta a tela com a marcação de dados
@author ALESSANDRO MAGNO DE PAULA
@since 30/09/2024
@version 1.0
@type function
@obs Codigo gerado automaticamente pelo Autumn Code Maker
@see http://autumncodemaker.com
/*/

Static Function fMontaTela()
    Local aArea         := GetArea()
    Local aCampos := {}
    Local oTempTable := Nil
    Local aColunas := {}
    Local cFontPad    := 'Calibri'
    Local oFontGrid   := TFont():New(cFontPad, /*uPar2*/, -14)
    //Janela e componentes
    Private oDlgMark
    Private oPanGrid
    Private oMarkBrowse
    Private cAliasTmp := GetNextAlias()
    Private aRotina   := MenuDef()
    //Tamanho da janela
    Private aTamanho := MsAdvSize()
    Private nJanLarg := aTamanho[5]
    Private nJanAltu := aTamanho[6]

    //Adiciona as colunas que serão criadas na temporária
    aAdd(aCampos, { 'OK', 'C', 2, 0}) //Flag para marcação
    aAdd(aCampos, { 'E1_PREFIXO', 'C', 3, 0}) //Prefixo
    aAdd(aCampos, { 'E1_NUM', 'C', 10, 0}) //No Título
    aAdd(aCampos, { 'E1_PARCELA', 'C', 2, 0}) //Parcela    
    aAdd(aCampos, { 'E1_NOSNUM', 'C', 10, 0}) //Nosso Número
    aAdd(aCampos, { 'E1_TIPO', 'C', 3, 0}) //Tipo
    aAdd(aCampos, { 'E1_NATUREZ', 'C', 10, 0}) //Natureza
    aAdd(aCampos, { 'E1_XXTPDIS', 'C', 1, 0}) //Tipo Distribuidor
    aAdd(aCampos, { 'E1_CLIENTE', 'C', 6, 0}) //Tipo Distribuidor    
    aAdd(aCampos, { 'E1_NOMCLI', 'C', 50, 0}) //Cliente    
    aAdd(aCampos, { 'E1_EMISSAO', 'D', 8, 0}) //Tipo Distribuidor    
    aAdd(aCampos, { 'E1_VENCTO', 'D', 8, 0}) //Tipo Distribuidor        
    aAdd(aCampos, { 'E1_XXBOIMP', 'C', 3, 0}) //Prefixo        


    //Cria a tabela temporária
    oTempTable:= FWTemporaryTable():New(cAliasTmp)
    oTempTable:SetFields( aCampos )
    oTempTable:AddIndex('1', {'E1_NUM'})
    oTempTable:AddIndex('2', {'E1_NOMCLI'})    
    oTempTable:Create()  

  
    //Popula a tabela temporária
    Processa({|| fPopula()}, 'Processando...')

    //Adiciona as colunas que serão exibidas no FWMarkBrowse
    aColunas := fCriaCols()
     
    aSeek := {}
    cCampoAux := "E1_NUM"
    aAdd(aSeek,{GetSX3Cache(cCampoAux, "X3_TITULO"), {{"", GetSX3Cache(cCampoAux, "X3_TIPO"), GetSX3Cache(cCampoAux, "X3_TAMANHO"), GetSX3Cache(cCampoAux, "X3_DECIMAL"), AllTrim(GetSX3Cache(cCampoAux, "X3_TITULO")), AllTrim(GetSX3Cache(cCampoAux, "X3_PICTURE"))}} } )

    cCampoAux := "E1_NOMCLI"
    aAdd(aSeek,{GetSX3Cache(cCampoAux, "X3_TITULO"), {{"", GetSX3Cache(cCampoAux, "X3_TIPO"), GetSX3Cache(cCampoAux, "X3_TAMANHO"), GetSX3Cache(cCampoAux, "X3_DECIMAL"), AllTrim(GetSX3Cache(cCampoAux, "X3_TITULO")), AllTrim(GetSX3Cache(cCampoAux, "X3_PICTURE"))}} } )


    //Criando a janela
    DEFINE MSDIALOG oDlgMark TITLE 'Geração de Boletos SICOOB ' FROM 000, 000  TO nJanAltu, nJanLarg COLORS 0, 16777215 PIXEL
        //Dados
        oPanGrid := tPanel():New(001, 001, '', oDlgMark, /*oFont*/, /*lCentered*/, /*uParam7*/, RGB(000,000,000), RGB(254,254,254), (nJanLarg/2) - 1, (nJanAltu/2) - 1)
        oMarkBrowse := FWMarkBrowse():New()
        oMarkBrowse:SetAlias(cAliasTmp)                
        oMarkBrowse:SetDescription('Boletos')
        oMarkBrowse:oBrowse:SetFixedBrowse(.T.)
        oMarkBrowse:SetFontBrowse(oFontGrid)
        oMarkBrowse:SetFieldMark('OK')
        oMarkBrowse:SetTemporary(.T.)
        oMarkBrowse:SetColumns(aColunas)
        oMarkBrowse:oBrowse:SetSeek(.T.,aSeek)        
        oMarkBrowse:oBrowse:SetDBFFilter(.T.)
        oMarkBrowse:oBrowse:SetUseFilter(.T.)

        //Define a legenda
        oMarkBrowse:AddLegend("ALLTRIM(E1_XXBOIMP) <>  'S'", "GREEN"	,  "Não Registrado")
        oMarkBrowse:AddLegend("ALLTRIM(E1_XXBOIMP) ==  'S'", "BLACK"	,  "Registrado")


        oMarkBrowse:SetOwner(oPanGrid)
        oMarkBrowse:Activate()
    ACTIVATE MsDialog oDlgMark CENTERED
    
    //Deleta a temporária e desativa a tela de marcação
    oTempTable:Delete()
    oMarkBrowse:DeActivate()
    
    RestArea(aArea)
Return

/*/{Protheus.doc} MenuDef
Botões usados no Browse
@author ALESSANDRO MAGNO DE PAULA
@since 30/09/2024
@version 1.0
@type function
@obs Codigo gerado automaticamente pelo Autumn Code Maker
@see http://autumncodemaker.com
/*/

Static Function MenuDef()

    Local aRotina := {}
     
    //Criação das opções
    ADD OPTION aRotina TITLE 'Registrar'  ACTION 'u_FINPROC'     OPERATION 2 ACCESS 0
    ADD OPTION aRotina TITLE 'Imprimir'  ACTION 'u_FINPROC'     OPERATION 2 ACCESS 0    
	ADD OPTION aRotina TITLE 'Verificar NCC'   	ACTION 'U_VerNCC()'     OPERATION 3 ACCESS 0    

Return aRotina

/*/{Protheus.doc} fPopula
Executa a query SQL e popula essa informação na tabela temporária usada no browse
@author ALESSANDRO MAGNO DE PAULA
@since 30/09/2024
@version 1.0
@type function
@obs Codigo gerado automaticamente pelo Autumn Code Maker
@see http://autumncodemaker.com
/*/

Static Function fPopula()
    Local cQryDados := ''
    Local nTotal := 0
    Local nAtual := 0
	Private cQLinha   := Chr(13) + Chr(10)    

    //Monta a consulta

    cQryDados = "SELECT                             "+cQLinha
    cQryDados += "E1_XXBOIMP,                       "+cQLinha
    cQryDados += "E1_PREFIXO,                       "+cQLinha
    cQryDados += "E1_NUM,                           "+cQLinha
    cQryDados += "E1_PARCELA,                       "+cQLinha
    cQryDados += "E1_NOSNUM,                        "+cQLinha
    cQryDados += "E1_TIPO,                          "+cQLinha
    cQryDados += "E1_NATUREZ,                       "+cQLinha
    cQryDados += "E1_XXTPDIS,                        "+cQLinha    
    cQryDados += "E1_CLIENTE,                        "+cQLinha        
    cQryDados += "E1_NOMCLI,                        "+cQLinha
    cQryDados += "E1_EMISSAO,                        "+cQLinha
    cQryDados += "E1_VENCTO                        "+cQLinha    
    cQryDados += "FROM SE1010                       "+cQLinha
    cQryDados += "WHERE E1_XXGRBOL <>'2'            "+cQLinha
    cQryDados += "AND E1_NATUREZ <> '1020003'       "+cQLinha
    cQryDados += "AND E1_PREFIXO = 'TES'                "+cQLinha
    cQryDados += "AND E1_SALDO > 0                  "+cQLinha
    cQryDados += "AND D_E_L_E_T_ = ' '              "+cQLinha
    cQryDados += "AND E1_FILIAL='01'                "+cQLinha
    cQryDados += "AND E1_EMISSAO BETWEEN '"+DTOS(MV_PAR01)+"'"+cQLinha
    cQryDados += "AND '"+ DTOS(MV_PAR02) + "'" +cQLinha   

    if MV_PAR03='1'
        cQryDados +=" AND (E1_XXBOIMP) <>  'S' "   
    elseif MV_PAR03='2'
        cQryDados +=" AND (E1_XXBOIMP) =  'S' "       
    endif

    cQryDados += "ORDER BY  E1_EMISSAO, E1_NOMCLI   "+cQLinha    
    
    MemoWrite( SuperGetMV("BE_LOGDIR", , "\logbio\") + 'BIOFIN24' + "_cQry.sql", cQryDados )    
    PLSQuery(cQryDados, 'QRYDADTMP')

    //Definindo o tamanho da régua
    DbSelectArea('QRYDADTMP')
    Count to nTotal
    ProcRegua(nTotal)
    QRYDADTMP->(DbGoTop())

    //Enquanto houver registros, adiciona na temporária
    While ! QRYDADTMP->(EoF())
        nAtual++
        IncProc('Analisando registro ' + cValToChar(nAtual) + ' de ' + cValToChar(nTotal) + '...')

        RecLock(cAliasTmp, .T.)
            (cAliasTmp)->OK := Space(2)
            (cAliasTmp)->E1_PREFIXO := QRYDADTMP->E1_PREFIXO
            (cAliasTmp)->E1_NUM := QRYDADTMP->E1_NUM
            (cAliasTmp)->E1_PARCELA := QRYDADTMP->E1_PARCELA            
            (cAliasTmp)->E1_NOSNUM := QRYDADTMP->E1_NOSNUM
            (cAliasTmp)->E1_TIPO := QRYDADTMP->E1_TIPO
            (cAliasTmp)->E1_NATUREZ := QRYDADTMP->E1_NATUREZ
            (cAliasTmp)->E1_XXTPDIS := QRYDADTMP->E1_XXTPDIS
            (cAliasTmp)->E1_CLIENTE := QRYDADTMP->E1_CLIENTE
            (cAliasTmp)->E1_NOMCLI := QRYDADTMP->E1_NOMCLI
            (cAliasTmp)->E1_EMISSAO := QRYDADTMP->E1_EMISSAO
            (cAliasTmp)->E1_VENCTO := QRYDADTMP->E1_VENCTO            
            (cAliasTmp)->E1_XXBOIMP := QRYDADTMP->E1_XXBOIMP  
        (cAliasTmp)->(MsUnlock())

        QRYDADTMP->(DbSkip())
    EndDo
    QRYDADTMP->(DbCloseArea())
    (cAliasTmp)->(DbGoTop())
Return

/*/{Protheus.doc} fCriaCols
Função que gera as colunas usadas no browse (similar ao antigo aHeader)
@author ALESSANDRO MAGNO DE PAULA
@since 30/09/2024
@version 1.0
@type function
@obs Codigo gerado automaticamente pelo Autumn Code Maker
@see http://autumncodemaker.com
/*/

Static Function fCriaCols()
    Local nAtual       := 0 
    Local aColunas := {}
    Local aEstrut  := {}
    Local oColumn
    
    //Adicionando campos que serão mostrados na tela
    //[1] - Campo da Temporaria
    //[2] - Titulo
    //[3] - Tipo
    //[4] - Tamanho
    //[5] - Decimais
    //[6] - Máscara
    aAdd(aEstrut, { 'E1_PREFIXO', 'Prefixo', 'C', 3, 0, ''})
    aAdd(aEstrut, { 'E1_NUM', 'No Título', 'C', 10, 0, ''})
    aAdd(aEstrut, { 'E1_PARCELA', 'Parcela', 'C', 2, 0, ''})        
    aAdd(aEstrut, { 'E1_NOSNUM', 'Nosso Número', 'C', 10, 0, ''})
    aAdd(aEstrut, { 'E1_TIPO', 'Tipo', 'C', 3, 0, ''})
    aAdd(aEstrut, { 'E1_NATUREZ', 'Natureza', 'C', 10, 0, ''})
    aAdd(aEstrut, { 'E1_XXTPDIS', 'Tp Dis', 'C', 1, 0, ''})
    aAdd(aEstrut, { 'E1_CLIENTE', 'Cod Dis', 'C', 6, 0, ''})    
    aAdd(aEstrut, { 'E1_NOMCLI', 'Cliente', 'C', 30, 0, ''})
    aAdd(aEstrut, { 'E1_EMISSAO', 'Emissão', 'D', 8, 0, ''})    
    aAdd(aEstrut, { 'E1_VENCTO', 'Vencimento', 'D', 8, 0, ''})        
    aAdd(aEstrut, { 'E1_XXBOIMP', 'Registrado', 'C', 1, 0, ''}) 
    
       

    //Percorrendo todos os campos da estrutura
    For nAtual := 1 To Len(aEstrut)
        //Cria a coluna
        oColumn := FWBrwColumn():New()
        oColumn:SetData(&('{|| ' + cAliasTmp + '->' + aEstrut[nAtual][1] +'}'))
        oColumn:SetTitle(aEstrut[nAtual][2])
        oColumn:SetType(aEstrut[nAtual][3])
        oColumn:SetSize(aEstrut[nAtual][4])
        oColumn:SetDecimal(aEstrut[nAtual][5])
        oColumn:SetPicture(aEstrut[nAtual][6])

        //Adiciona a coluna
        aAdd(aColunas, oColumn)
    Next
Return aColunas

/*/{Protheus.doc} User Function BIOFIN2O
Função acionada pelo botão continuar da rotina
@author ALESSANDRO MAGNO DE PAULA
@since 30/09/2024
@version 1.0
@type function
@obs Codigo gerado automaticamente pelo Autumn Code Maker
@see http://autumncodemaker.com
/*/

User Function FINPROC()
    Processa({|| fProcessa()}, 'Processando...')
Return

/*/{Protheus.doc} fProcessa
Função que percorre os registros da tela
@author ALESSANDRO MAGNO DE PAULA
@since 30/09/2024
@version 1.0
@type function
@obs Codigo gerado automaticamente pelo Autumn Code Maker
@see http://autumncodemaker.com
/*/

Static Function fProcessa()
    Local aArea     := FWGetArea()
    Local cMarca    := oMarkBrowse:Mark()
    Local nAtual    := 0
    Local nTotal    := 0
    Local nTotMarc := 0
    
    //Define o tamanho da régua
    DbSelectArea(cAliasTmp)
    (cAliasTmp)->(DbGoTop())
    Count To nTotal
    ProcRegua(nTotal)
    
    //Percorrendo os registros
    (cAliasTmp)->(DbGoTop())
    While ! (cAliasTmp)->(EoF())
        nAtual++
        IncProc('Analisando registro ' + cValToChar(nAtual) + ' de ' + cValToChar(nTotal) + '...')

        //Caso esteja marcado
        If oMarkBrowse:IsMark(cMarca)
            nTotMarc++
            FWAlertInfo((cAliasTmp)->E1_NUM, "Mensagem de teste")
         //Início da migração da solução   
		//Integração para registrar a cobrança no Sicoob.
            IF cBanco== "756" .and. Empty(QRY->E1_XQRCODE)//sicoob
                //(cOrigem,aDadosEmp,aDadosTit,aBancos,nPOS,aDatSacado,aBolText,aDados,dDtaBx,cDatIni,cDatFim, cCodClie, cNossoNum)
                cNossoNum  := U_MONTANUM (cBanco, alltrim(cCodEmp), cFaixaAtu, cFaixaFim, aBancos[nPOS])
                lRet :=  U_BEWS0002("GER",aDadosEmp,aDadosTit,@aBancos,nPOS,aDatSacado,aBolText,@aDados, , , , cCodClie,cNossoNum)
                If !lRet
                    MsgInfo("Boleto não registrado!","BEFINM01")
                    return // igor - provisório até definir regra
                Endif
            Else
                aDados[2] := Alltrim(QRY->E1_CODBAR)
                aDados[3] := Alltrim(QRY->E1_CODDIG)
                aDados[38] := Alltrim(QRY->E1_XQRCODE)
                aDados[13] := Alltrim(QRY->E1_NOSNUM)
            Endif
        EndIf
         
        (cAliasTmp)->(DbSkip())
    EndDo


    
    //Mostra a mensagem de término e caso queria fechar a dialog, basta usar o método End()
    FWAlertInfo('Dos [' + cValToChar(nTotal) + '] registros, foram processados [' + cValToChar(nTotMarc) + '] registros', 'Atenção')
    //oDlgMark:End()

    FWRestArea(aArea)
Return
