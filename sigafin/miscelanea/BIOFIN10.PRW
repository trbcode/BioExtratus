//============================================================================//
// Autor    | Ângelo Barros		                                              //
//----------------------------------------------------------------------------//
// Data     | 16/01/2018                                                      //
//----------------------------------------------------------------------------//
// Descricao| Rotina para geração e Impressão de Boletos FUPROM				  //
//----------------------------------------------------------------------------//
// Partida  | Menu do Programa		                                          //
//============================================================================//

#INCLUDE 'PROTHEUS.CH'

/*/{Protheus.doc} BIOFIN10
Geração de Boletos FUP.
@author Ângelo Barros.
@since 16/01/2019
@version 12.1.17
@history 28/12/2018, Ângelo Barros, Separar títulos PAC (BB) dos títulos FUPROM  - Chamado nº.29272
@type function
/*/
User Function BIOFIN10()
	U_BIOFIN06("FUP")
Return .T. 