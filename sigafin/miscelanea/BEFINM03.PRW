// Função para gerar o "Nosso Número" e calcular o dígito verificador
STATIC FUNCTION GerarNossoNumeroSicoob(nCooperativa, nSequencial)
	LOCAL cNossoNumero := ""
	LOCAL nDV := 0

	// Formata o número da cooperativa com 4 dígitos
	cNossoNumero := StrZero(nCooperativa, 4)

	// Adiciona o sequencial da cobrança (7 dígitos)
	cNossoNumero += StrZero(nSequencial, 7)

	// Calcula o dígito verificador pelo Módulo 11
	nDV := Modulo11(cNossoNumero)

	// Concatena o dígito verificador ao Nosso Número
	cNossoNumero += Str(nDV, 1)

RETURN cNossoNumero


// Função para cálculo do Módulo 11
STATIC FUNCTION Modulo11(cNumero)
	LOCAL nSoma := 0
	LOCAL nPeso := 2
	LOCAL i := 0
	LOCAL nDigito := 0

	// Percorre o número da direita para a esquerda
	FOR i := Len(cNumero) TO 1 STEP -1
		nSoma += Val(SubStr(cNumero, i, 1)) * nPeso
		nPeso++
		IF nPeso > 9
			nPeso := 2
		ENDIF
	NEXT

	// Calcula o resto da divisão por 11
	nDigito := 11 - (nSoma % 11)

	// Regras para o dígito verificador
	IF nDigito == 10
		nDigito := 1
	ELSEIF nDigito >= 11
		nDigito := 0
	ENDIF

RETURN nDigito
