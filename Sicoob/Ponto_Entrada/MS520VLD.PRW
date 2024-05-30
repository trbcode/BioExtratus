/*//#########################################################################################
Project  : project
Module   : SIGAFAT
Source   : MS520VLD
Objective: Integra Exclusão com API BB
*///#########################################################################################

#INCLUDE 'TOTVS.CH'



/*/{Protheus.doc} MS520VLD

    Description

    @author  Igor Guimarães
    @example Example
    @param   [Parameter_Name],Parameter_type,Parameter_Description
    @return  Return
    @table   Tables
    @since   25-08-2021
/*/
User Function MS520VLD()

    Local lRet          := .T.
    Local aArea         := GetArea()
    Local cNosso        :=""
    Local cCodBco       := ""
    Local cSerie        := Padr(SF2->F2_SERIE,TAMSX3("F2_SERIE")[1])
    Local cNumTit       := Padr(SF2->F2_DOC,TAMSX3("F2_DOC")[1])
    Local cChaveSE1     := cSerie + cNumTit
    Local aDados        := {}

    dbSelectArea("SE1")
    dbSetOrder(1)
    if dbSeek(xFilial("SE1")+cChaveSE1)
        While !Eof() .and. cChaveSE1 == SE1->E1_PREFIXO + SE1->E1_NUM
            aDados := {}
            cNosso  := Alltrim(SE1->E1_NUMBCO)
            cCodBco := Alltrim(SE1->E1_PORTADO)

            if Empty(cNosso)
                SE1->(DBSkip())
                LOOP
            EndIf

            Aadd(aDados,"")
            Aadd(aDados,"")
            Aadd(aDados,cNosso)

            If cCodBco == "756"
                lRet := U_BEWS0002("EXC",,,,,,aDados,,,)//sicoob
            EndIf
            SE1->(DBSkip())
        EndDo
    EndIF

    If lRet
        MsgInfo("Boleto Excluido no banco com sucesso!","MS520VLD")
    Else
        MsgInfo("Boleto não Excluido no banco!","MS520VLD")
    EndIf
    RestArea(aArea)
Return(lRet)
