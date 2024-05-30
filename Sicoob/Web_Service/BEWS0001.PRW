
/*//#########################################################################################
Projeto : Sicoob
Modulo  : module
Fonte   : BEWS0001
Objetivo: Gerar Chave Token
*///#########################################################################################

#INCLUDE 'TOTVS.CH'

/*/{Protheus.doc} BEWS0001

    Geração do Token

    @author  Igor Guimarães
    @example Exemplos
    @param   [Nome_do_Parametro],Tipo_do_Parametro,Descricao_do_Parametro
    @return  Especifica_o_retorno
    @table   Tabelas
    @since   29/05/2024
/*/

User Function BEWS0001()

    Local cURL      := "https://auth.sicoob.com.br/auth/realms/cooperado/protocol/openid-connect/token"
    Local nTimeOut  := 120
    Local aHeadOut  := {}
    Local cHeadRet  := ""
    Local cPostRet  := ""
    Local cCert     := ""
    Local cKey 	    := ""
    Local cAc_Token := ""
    Local cClientId := ""
    Local cPSWRCO   := ""
    Private lLogin  := Type("cEmpAnt") != "U"

    If !lLogin
        RpcSetEnv("01","0201","Admin")
    EndIf

    cCert := "\certs\0201_certif_cert.pem"
    cKey  := "\certs\0201_certif_key.pem"

    cAc_Token := "grant_type=client_credentials"
    cAc_Token += "&client_id=" + cClientID+"" // foi gerado pela passo 2 do manual
    cAc_Token += "&scope=" + "cobranca_boletos_consultar cobranca_boletos_incluir cobranca_boletos_pagador cobranca_boletos_segunda_via cobranca_boletos_descontos cobranca_boletos_abatimentos cobranca_boletos_valor_nominal cobranca_boletos_seu_numero cobranca_boletos_especie_documento cobranca_boletos_baixa cobranca_boletos_rateio_credito cobranca_pagadores cobranca_boletos_negativacoes_incluir cobranca_boletos_negativacoes_alterar cobranca_boletos_negativacoes_baixar cobranca_boletos_protestos_incluir cobranca_boletos_protestos_alterar cobranca_boletos_protestos_desistir cobranca_boletos_solicitacao_movimentacao_incluir cobranca_boletos_solicitacao_movimentacao_consultar cobranca_boletos_solicitacao_movimentacao_download cobranca_boletos_prorrogacoes_data_vencimento cobranca_boletos_prorrogacoes_data_limite_pagamento cobranca_boletos_encargos_multas cobranca_boletos_encargos_juros_mora cobranca_boletos_pix" // Arquivo de senha

    aadd(aHeadOut, 'Content-Type: application/x-www-form-urlencoded')
    cPostRet := HTTPSPost( cURL, cCert, cKey, cPSWRCO, "", cAc_Token, nTimeOut, aHeadOut, @cHeadRet )

    //Exibe o retorno do POST e também o header de retorno
    ConOut("Retorno do POST gToken:", cPostRet)
    ConOut("Header do POST gToken:", cHeadRet)

    //Transforma o retorno em um JSON
    jJsonToken := JsonObject():New()
    jJsonToken:FromJson(cPostRet)

return (jJsonToken)
