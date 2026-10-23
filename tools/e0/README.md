# Executor de observação da E0

Este projeto auxiliar usa os formulários atuais e o motor por referência. Sem parâmetros, observa a versão atual com os cenários criados na E0. Com `--e1`, executa a [suíte de regressões de fluxo](../e1/README.md); com `--e2`, verifica também o [adaptador visual](../e2/README.md). As evidências históricas da E0 continuam em `docs/evidencias/e0-2026-10-22/`.

## Executar no Delphi 13 Community Edition

1. Abra `DelphiBlocks.groupproj` na raiz do repositório. O Project Manager contém `Breakout.exe` e `BaselineRunner.exe`; dê duplo clique em `BaselineRunner.exe` para torná-lo ativo, selecione Windows 32-bit / Debug e execute Build. O `.dproj` desta pasta também pode ser aberto separadamente.
2. Execute **Run Without Debugging** (`Ctrl+Shift+F9`). O compilador da instalação Community usada nesta E0 recusou compilação pela linha de comando, mesmo retornando código de saída zero.
3. Aguarde aproximadamente 40 segundos, mantendo a janela ativa e evitando mouse/teclado durante a coleta.
4. O título muda de `sampling without debug` para `sampling with debug` e, no final, para `ready for manual checks`.
5. Os arquivos `scenarios.csv`, `timer.csv` e `resources.csv` são gravados em uma nova pasta `build/baseline-runs/AAAAMMDD-HHMMSSmmm/`. Assim, executar novamente preserva a coleta histórica. Para outra pasta, informe o caminho como primeiro parâmetro de execução nas opções de depuração da IDE.
6. Para produzir `summary.json` da nova coleta, execute pelo terminal, na raiz do repositório: `python tools/e0/summarize.py "build/baseline-runs/<pasta-gerada>"`. O script usa apenas a biblioteca padrão do Python 3. Sem argumento, ele reprocessa a referência histórica da E0. Suas observações ainda caracterizam a física legada; use `--e1` para validar as regras de fluxo corrigidas.
7. Feche o executor e dê duplo clique em `Breakout.exe` no mesmo Project Manager para voltar ao jogo principal. Não é necessário trocar o grupo aberto.

Se o arquivo do executor for alterado fora da IDE, confirme a recarga do módulo a partir do disco antes de compilar. A IDE pode compilar o conteúdo antigo ainda aberto no editor. O resumo valida que o cenário de pausa chegou efetivamente ao estado pausado, evitando aceitar uma coleta feita com essa versão antiga.

## O que o executor faz

- Instancia os mesmos formulários e chama seus handlers para observar lançamento, estados, vidas e respostas de colisão. Desde a E2, os cenários são preparados no motor por um probe exclusivo dos testes; mover um controle não altera a simulação.
- Nos cenários de colisão, substitui a grade, somente na memória do processo auxiliar, por um bloco em posição conhecida e outro distante. O segundo evita que a transição de conclusão interrompa a observação do deslocamento após o impacto. Depois restaura a partida usando F2. A referência histórica da E0 usava apenas um bloco.
- Registra as três regiões da raquete com as mesmas dimensões atuais. A largura do indicador de vidas é observada em pixels: 45, 30, 15 e 0 correspondem a três, duas, uma e zero vidas.
- Mede o início e a duração de cada chamada real do timer, delegando ao handler original. A primeira chamada de cada período tem intervalo zero e é excluída das estatísticas de intervalo.
- Coleta aproximadamente 20 segundos sem F10 e 20 segundos com F10. Um timer auxiliar acompanha a bola com a raquete e relança quando necessário, para manter a simulação ativa. As fases têm a aleatoriedade do código original e não constituem cargas idênticas.
- Amostra CPU acumulada do processo, memória residente, memória privada, handles e objetos GDI/USER. A CPU resumida é percentual de um núcleo lógico; em uma máquina com 16 processadores lógicos, dividir por 16 aproxima o percentual agregado da máquina.
- No final, restaura a partida e desliga seu próprio controlador, permitindo os testes manuais normais.

## Limites de interpretação

O projeto auxiliar habilita `Application.MainFormOnTaskbar` para tornar a janela controlável e tem configuração de projeto própria gerada pela IDE. Essas diferenças devem ser consideradas em testes de foco, aparência e DPI.

As medições incluem o custo do observador, do controlador auxiliar e da VCL. `handler_ms` cobre o handler da versão compilada e suas atualizações, mas não mede separadamente a composição final da tela. A referência da E0 inclui `ProcessMessages`; a E1 remove essa chamada. A frequência registrada é a de atualização da simulação; não é FPS de apresentação. Uma perda de foco pausa a partida e invalida a comparação de cadência; nesse caso, refaça a coleta mantendo o jogo ativo.

Os cenários automatizados são chamadas diretas aos handlers, e não injeção de teclado/mouse. Os testes manuais registrados no relatório complementam essa observação. Uma coleta curta não demonstra ausência de vazamentos nem substitui os testes de duração e de plataformas previstos para as próximas etapas.

O resumo caracteriza defeitos conhecidos. As verificações de integridade não significam que o jogo esteja correto; após corrigir a mecânica, parte dessas observações deve mudar e ser substituída por testes das regras desejadas.
