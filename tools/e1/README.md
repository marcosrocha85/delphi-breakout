# Regressões de fluxo da E1

A unidade `UE1Checks.pas` usa os mesmos formulários do jogo e está referenciada pelo `BaselineRunner.dproj`, já incluído no grupo `DelphiBlocks.groupproj`. Não é necessário abrir outro projeto. Desde a E2, a preparação dos cenários usa o motor, os labels pertencem diretamente ao formulário e o diagnóstico tem 15 chaves. A evidência histórica da E1 permanece preservada; o [modo `--e2`](../e2/README.md) acrescenta verificações do adaptador.

1. Abra o grupo, ative `BaselineRunner.exe` e selecione **Win32 / Debug**.
2. Use **Build**. Se os fontes tiverem sido editados fora da IDE, aceite sua recarga antes de compilar.
3. Em **Run > Parameters**, informe `--e1` e execute **Run Without Debugging**. Alternativamente, após compilar, execute `tools\e0\BaselineRunner.exe --e1` no terminal da raiz do repositório.
4. O título informa `checks passed` ou `checks failed`. O relatório completo é `build/e1/latest/checks.json`; a cada execução ele é substituído. Para guardar outra execução, use `--e1 "caminho-da-pasta"`.
5. Confira `passed = true`, `checks = 43` e `failures = 0`. O modo de testes termina deixando a janela pronta para a conferência manual. Feche a janela principal antes de recompilar ou limpar o projeto.

Os casos cobrem lançamento por clique/espaço, pausa imediata e perda de foco, comandos ignorados nos estados inadequados, três quedas sem movimento extra, game over, F2 em movimento/pausa, F1 restrito ao diagnóstico visível e pausado, F10, valores atuais do diagnóstico, formatação de pontuação, direção independente da posição da janela, ownership e 50 reinícios com contagens estáveis.

Os passos são acionados de forma síncrona pelos handlers públicos existentes. O timer é desabilitado pelo observador nos cenários dirigidos. Isso verifica os resultados do fluxo atual, sem depender da cadência do Windows. A futura E2 poderá executar regras diretamente no motor, sem formulários.

Esses testes não validam o ângulo contínuo da raquete, faces/cantos dos blocos, alta velocidade, passo fixo, DPI, desempenho de pintura ou ausência de vazamentos em partidas longas. Esses itens permanecem nas etapas correspondentes do plano. A inspeção visual complementa os testes: na E1 ela também detectou e corrigiu o contraste do diagnóstico.
