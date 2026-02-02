/*//#########################################################################################
Projeto : project
Modulo  : module
Fonte   : BEFINM02
Objetivo: Rotina pra encupsular API Sicoob (Venda de produto)
*///#########################################################################################

#INCLUDE 'TOTVS.CH'

/*/{Protheus.doc} BEFINM02
Rotina pra encupsular API Sicoob (Venda de produto)
@type user function
@author Igor Guimarães
@since 24/09/2024
@version version
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function BEFINM02()

	Local lLogin    := Type("cEmpAnt") != "U"
	Local cBcoCNAB  := PADR("756",TAMSX3("A6_COD")[1])
	Local cAgeCNAB  := PADR("4108",TAMSX3("A6_AGENCIA")[1])
	Local cCtaCNAB  := PADR("8429",TAMSX3("A6_NUMCON")[1])
	Local cCodClie  := "e24ab947-b2b6-4c55-86fb-2662a014a63b"

	If !lLogin
		RpcSetEnv("01","01","Admin")
	EndIf

	U_BIOFIN03(cBcoCNAB, cAgeCNAB, cCtaCNAB,cCodClie)

Return()
