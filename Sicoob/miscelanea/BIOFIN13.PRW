//============================================================================//
// Autor    | Ângelo Barros		                                              //
//----------------------------------------------------------------------------//
// Data     | 03/03/2020                                                      //
//----------------------------------------------------------------------------//
// Descricao| Rotina para geração e Impressão de Boletos FUPROM	CHIKAS  	  //
//----------------------------------------------------------------------------//
// Partida  | Menu do Programa		                                          //
//============================================================================//

#INCLUDE 'PROTHEUS.CH'

/*/{Protheus.doc} BIOFIN13
Geração de Boletos FUP.
@author Ângelo Barros.
@since 03/03/2020
@version 12.1.25
@history 03/03/2020, Ângelo Barros, Separar títulos PAC (BB) dos títulos FUPROM  - Chamado nº. 32381.
@type function
/*/
User Function BIOFIN13()
	U_BIOFIN06("FUPCHK")
Return .T. 