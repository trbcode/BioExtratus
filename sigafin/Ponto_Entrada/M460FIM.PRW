/*//#########################################################################################
Projeto : project
Modulo  : module
Fonte   : M460FIM
Objetivo: objetivo
*///#########################################################################################

#INCLUDE 'TOTVS.CH'

/*/{Protheus.doc} M460FIM
    Este P.E. e' chamado apos a Gravacao da NF de Saida, e fora da transação.
        - Envia dados do boleto para cobrança bancária (SICOOB)
    @type  Function
    @author Igor Guimarães
    @since 14/08/2024
    /*/
User Function M460FIM()
	Local aAreaSF2 := SF2->(GetArea())
	Local aAreaSD2 := SD2->(GetArea())
	Local aAreaSC5 := SC5->(GetArea())
	Local aAreaSC6 := SC6->(GetArea())
	Local aAreaSA1 := SA1->(GetArea())



	RestArea(aAreaSF2)
	RestArea(aAreaSD2)
	RestArea(aAreaSC5)
	RestArea(aAreaSC6)
	RestArea(aAreaSA1)
Return
