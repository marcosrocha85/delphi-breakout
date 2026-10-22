# E1 — Organização e correções de fluxo

Data: 22/10/2026. Base: `fc29204`, merge da E0. Ambiente: Delphi 13 Community Edition, Windows, Win32.

**E1 concluída.** O evento de timer delega a um passo organizado em métodos com responsabilidades explícitas. Lançamento, pausa, reinício, perda de vida e atualização do diagnóstico agora seguem caminhos centralizados. O jogo continua usando os controles e a física legados durante esta etapa.

## Comportamento corrigido

| Situação | Referência E0 | Resultado E1 |
| --- | --- | --- |
| Lançar depois de mover a raquete | O lançamento podia recentralizar a posição. | Clique e espaço preservam a posição preparada. |
| F3 logo depois do lançamento | Podia ser ignorado antes do primeiro timer. | Pausa imediatamente e mostra a mensagem. |
| Clique/espaço durante pausa | Espaço relançava e deixava a mensagem de pausa. | Preservam pausa, posição e mensagem; F3 retoma. |
| Perda de vida | Reposicionava e continuava movendo no mesmo passo. | Desconta uma vida, reposiciona e encerra o passo. |
| F1 sem diagnóstico ou depois de game over | Permitia movimento fora do contexto de inspeção. | Só avança com partida pausada, vidas e diagnóstico visível. |
| F2 em movimento, pausa ou game over | Estado e mensagens eram tratados por caminhos diferentes. | Restaura três vidas, zero pontos, 96 blocos e estado pronto. |
| Diagnóstico | Chaves divergentes, valores anteriores ao passo e texto pouco legível. | Nove chaves compartilhadas, posição posterior ao passo e contraste legível. F10 não desloca a janela principal. |
| Pontuação longa | A rotina de preenchimento podia duplicar os dígitos. | Mínimo de nove dígitos, sem truncar valores maiores. |

Em `UMain`, `StepGame` coordena limites, perda, raquete, blocos, descarte e movimento. `StartNewGame`, `LaunchBall`, `SetPaused` e os métodos de atualização eliminam duplicações. As direções agora têm tipos próprios, sem conflito com a propriedade `Left` do formulário. O gerador aleatório é inicializado uma vez na criação.

`Application.ProcessMessages` foi removido da pontuação; um bloqueio de reentrada protege o passo. `Language` pertence ao formulário e seus labels pertencem a ela; o encerramento desabilita o timer e libera o diagnóstico e os textos. Declarações sem uso foram removidas. Os blocos continuam sendo `TImage`, com descarte em ordem inversa e sem reutilizar blocos inativos.

## Validação executada

- **Clean All** do grupo `DelphiBlocks`: sucesso para `Breakout` e `BaselineRunner`, ambos Win32/Debug.
- **Build All** após a limpeza: sucesso. O jogo principal também compilou separadamente em Win32/Debug e Win32/Release. Nenhum warning ou hint foi exibido nesses builds finais; os seis hints de declarações sem uso da referência E0 desapareceram.
- `BaselineRunner --e1`, compilado após o Clean: **43 verificações, 43 aprovadas, zero falhas**. Inclui os três descontos de vida, ausência de movimento extra, comandos nos estados de pronto/pausa/game over, pontuação até `MaxInt`, diagnóstico fechado pelo X/reaberto por F10 e 50 reinícios com contagens estáveis.
- Conferência pela interface do executor: espaço lançou, F3 pausou, espaço e clique preservaram a pausa, F10 abriu o diagnóstico e F1 avançou um passo mantendo a pausa. Conferido o contraste das nove linhas após a correção visual.
- A alteração local preexistente em `README.md` foi preservada e não faz parte deste lote. As evidências históricas da E0 foram mantidas.

Houve uma tentativa intermediária de build com erro `F2039` porque o executável auxiliar continuava em execução. Após encerrar a janela principal, o Clean All e o Build All acima passaram. O erro não era de compilação dos fontes.

As verificações automatizadas acionam os handlers dos formulários; não são testes de um motor independente nem injeção de teclado. A conferência pela interface complementa essa limitação. Contagens estáveis após 50 reinícios não demonstram ausência de vazamentos. Não foi estabelecida melhoria de FPS ou cadência nesta entrega; Win64, DPI e partidas longas continuam pendentes para a consolidação.

## Evidências e reprodução

- [Relatório das 43 verificações](evidencias/e1-2026-10-22/checks.json).
- [Clean All](evidencias/e1-2026-10-22/05-clean-all-win32-debug.png).
- [Build do executor Win32/Debug](evidencias/e1-2026-10-22/01-build-runner-win32-debug.png).
- [Build do jogo Win32/Debug](evidencias/e1-2026-10-22/04-build-main-win32-debug.png) e [Win32/Release](evidencias/e1-2026-10-22/02-build-main-win32-release.png).
- [Espaço preservando a pausa](evidencias/e1-2026-10-22/03-space-preserves-pause.png) e [diagnóstico legível](evidencias/e1-2026-10-22/06-debug-readable.png).
- [Instruções do modo `--e1`](../tools/e1/README.md).

O executor permanece no mesmo grupo da IDE. Sem parâmetros, ele usa uma pasta nova em `build/baseline-runs/`, evitando substituir a referência histórica da E0; `--e1` grava por padrão em `build/e1/latest/`.

## Próxima etapa

A E2 extrairá o motor e os estados para reduzir a dependência dos controles visuais e permitir testes das regras sem VCL. O ângulo proporcional da raquete e a bola atravessando blocos continuam pendentes da E3, junto com o passo fixo e a resolução geométrica das colisões. A troca da renderização permanece na E4.
