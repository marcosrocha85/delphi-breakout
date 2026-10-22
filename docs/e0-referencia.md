# E0 — Referência do comportamento atual

Data: 22/10/2026. Status: concluída para a referência inicial Win32.

A E0 confirmou os dois defeitos relatados e registrou uma base reproduzível de compilação, comportamento e cadência. As regras e os formulários originais do jogo foram preservados. A implementação das correções começa na E1.

## Ambiente e versão observada

| Item | Referência |
| --- | --- |
| IDE aberta | Delphi 13 Community Edition |
| Versão do executável da IDE | `37.0.60542.8024` |
| Sistema | Windows 11 Pro, versão `10.0.26300`, build `26300` |
| Processador | AMD Ryzen 7 5700X, 8 núcleos / 16 processadores lógicos |
| Commit local de partida | `9d0a3709f1a4e901be8c01f1c84c5442b4bf1c1a` |
| Configuração inicial da IDE | Windows 32-bit / Release |
| Referência de comportamento | Fontes locais, incluindo a alteração preexistente do usuário no README |

A referência local `origin/main` aponta para `984ab185705aa964f21c4e1c63d1802c17075ca2`, um commit à frente, que altera somente o README. Não foi feito fetch, pull ou merge nesta etapa. Antes da implementação, conciliar essa mudança com as duas linhas locais já acrescentadas pelo usuário.

## Compilação

O projeto original foi compilado pela IDE em **Win32 / Debug**, com resultado **Success**, tempo exibido de **0,5 s**, nenhum erro ou warning exibido e seis hints:

| Local | Hint |
| --- | --- |
| `UDM.pas:83` | H2164: `fProgress` declarado e não usado |
| `UDM.pas:84` | H2164: `Label1` declarado e não usado |
| `UDM.pas:85` | H2164: `ProgressBar1` declarado e não usado |
| `UDM.pas:86` | H2164: `SList` declarado e não usado |
| `UDM.pas:87` | H2164: `I` declarado e não usado |
| `UDM.pas:11` | H2219: `IsLabelsCreated` declarado e não usado |

Evidência: [build original e hints](evidencias/e0-2026-10-22/03-build-hints.png). O jogo original abriu pela IDE, com três vidas e a grade completa: [execução original](evidencias/e0-2026-10-22/04-original-em-execucao.png). A imagem histórica `images/main game.jpg` não foi usada como prova dessa execução.

A instalação Community recusou o compilador por linha de comando com a mensagem “This version of the product does not support command line compiling.” O processo retornou código zero mesmo sem produzir o executável auxiliar. Por isso, todos os builds usados como evidência de sucesso foram feitos pela IDE.

O executor auxiliar também compilou em Win32 / Debug. Após sua integração ao grupo, **Build All** passou com `Breakout` em Win32 / Release e `BaselineRunner` em Win32 / Debug; tempo total exibido de 0,8 s, com os mesmos hints dos fontes legados. Evidência: [configurações dos dois builds](evidencias/e0-2026-10-22/15-build-grupo.png).

## Método de observação

A janela do executável original abriu, mas não foi exposta como alvo controlável pela automação da interface. Foi criado um projeto auxiliar em `tools/e0/`, que referencia diretamente os mesmos `UMain`, `UDM`, `UDebug` e DFM, sem copiar ou modificar suas regras.

O executor habilita `MainFormOnTaskbar`, chama handlers existentes para cenários controlados e envolve o callback original do timer para observar seu tempo. Os testes de colisão usam um bloco isolado em memória, evitando que blocos vizinhos escondam a resposta de uma face. Depois dos cenários, F2 restaura a grade.

A coleta final tem dois períodos de aproximadamente 20 s: sem F10 e com F10. Um controlador auxiliar acompanha a bola com a raquete e relança quando necessário, mantendo a simulação ativa. Ao terminar, ele se desliga e deixa o jogo pronto para verificações manuais.

As fases usam a aleatoriedade atual e não são cargas idênticas. CPU e memória incluem a instrumentação. O projeto auxiliar tem configuração própria, e sua janela pode diferir em aparência/foco/DPI. Esses limites impedem tratar seus números como um benchmark exato do executável original isolado.

## Resultados dos dois defeitos relatados

### Resposta da raquete

Com a raquete em X = 300, largura 50 e a bola descendo na altura de contato, os três cenários produziram:

| Região atual | X inicial da bola | Deslocamento X | Deslocamento Y | Inclinação |
| --- | ---: | ---: | ---: | --- |
| Esquerda | 296 | -15 | -15 | 45° para cima e esquerda |
| Centro | 320 | +5 | -5 | 45° para cima e direita |
| Direita | 340 | +15 | -15 | 45° para cima e direita |

O código muda a velocidade e o sentido horizontal, mas mantém módulos horizontal e vertical iguais. A variação proporcional do ângulo pelo ponto de impacto está ausente. Este defeito ficou confirmado na execução dos handlers originais, além da leitura do fonte.

### Bloco destruído sem ricochete

O bloco isolado ocupa X = 300, Y = 100, largura 50 e altura 20. A bola de 17 × 17 foi colocada em X = 310, Y = 84, descendo e com um pixel de interseção na face superior.

Após uma atualização:

- O bloco foi removido e o placar passou a 10 pontos.
- A bola passou de `(310, 84)` para `(315, 89)`.
- O deslocamento vertical continuou positivo: ela seguiu descendo.

Esse caso reproduz diretamente o comportamento de “comer” o bloco sem refletir. O problema já ocorre nesse contato isolado, em baixa velocidade. Os testes varridos de alta velocidade previstos no plano continuam necessários como uma frente adicional.

O contato pela face inferior, com a bola inicialmente subindo, produziu saída para baixo, compatível com a atribuição de `Down` feita pelo primeiro ramo. A seleção incorreta da face explica a assimetria.

## Estados, comandos e vidas

| Verificação | Resultado registrado | Evidência |
| --- | --- | --- |
| Inicialização | 96 blocos e três vidas | `initial` no CSV |
| Clique / espaço em pronto | Timer habilitado e lançamento | `launch_click`, `launch_space`; clique também exercitado na janela |
| Mouse | Movimento da raquete e acompanhamento da bola em pronto observados | Testes pela janela auxiliar |
| F3 após a primeira atualização | Pausa; F3 retoma sem mudar a posição | `pause_after_first_tick`, `resume_f3`; [captura](evidencias/e0-2026-10-22/07-pausa-f3.png) |
| F3 imediatamente após lançar | Ignorado até a primeira atualização, pois `bPlaying` ainda é falso | `f3_immediately_after_launch` |
| Espaço durante pausa | Reposiciona e relança a bola, mantendo a mensagem de pausa visível | `space_while_paused`; [captura](evidencias/e0-2026-10-22/08-espaco-durante-pausa.png) |
| Perda de foco | Pausa; voltar à janela mantém a pausa | Handler e alternância real entre jogo e IDE; [captura](evidencias/e0-2026-10-22/10-perda-foco.png) |
| F1 antes de lançar | Move a bola com o timer desligado | `f1_before_launch` |
| F1 durante pausa | Avança um passo | [captura](evidencias/e0-2026-10-22/11-f1-passo-pausado.png) |
| Quedas sucessivas | Indicador de vidas passa de 45 para 30, 15 e 0 pixels | `lose_life_1` a `lose_life_3` |
| Atualização que perde vida | Depois de reposicionar, ainda desloca a bola em `(+5, -5)` | `extra_motion_after_life_loss` no resumo |
| Clique em game over | Não lança a bola | `click_at_game_over` |
| F1 em game over | Continua movendo a bola | `f1_at_game_over` |
| F2 | Restaura 96 blocos, três vidas e placar zero | `restart_f2`; exercitado também pela janela |
| F10 | Abre e fecha o diagnóstico | Coleta automática e teste pela janela; [captura do painel](evidencias/e0-2026-10-22/09b-painel-debug.png) |

Durante o uso manual de F10 seguido de espaço, também foi observado o menu de sistema da janela. Os handlers não consomem a tecla F10. Tratar como uma observação adicional para verificar na E1, considerando as diferenças da janela auxiliar.

Os cenários controlados chamam handlers diretamente e não substituem a verificação dos eventos reais do teclado/mouse. A tabela distingue os casos complementados pela interface.

## Cadência e recursos

Resultados da coleta final, resumidos por `tools/e0/summarize.py`:

| Medida | Sem F10 | Com F10 |
| --- | ---: | ---: |
| Chamadas registradas | 320 | 319 |
| Duração do período | 20,008 s | 19,950 s |
| Intervalo médio entre atualizações | 62,509 ms | 62,523 ms |
| Intervalo p95 | 76,110 ms | 75,602 ms |
| Maior intervalo | 80,466 ms | 79,006 ms |
| Frequência média de atualização | 15,998/s | 15,994/s |
| Duração média do handler original | 0,207 ms | 0,413 ms |
| Duração p95 do handler original | 0,994 ms | 1,832 ms |
| CPU equivalente a um núcleo lógico | 11,71% | 20,91% |
| Memória residente observada | 20,69–20,93 MiB | 21,13–21,27 MiB |
| Handles no início → fim | 270 → 270 | 274 → 276 |
| Objetos GDI no início → fim | 155 → 149 | 157 → 155 |
| Objetos USER no início → fim | 54 → 55 | 65 → 61 |

Em 16 processadores lógicos, os percentuais de CPU acima correspondem aproximadamente a 0,73% e 1,31% da capacidade agregada da máquina. São medidas do processo auxiliar, incluindo seu controlador e observador; a diferença entre fases não isola causalmente o custo de F10.

O timer configurado em 50 ms não entregou 20 atualizações por segundo nessa amostra. O processamento do handler foi bem menor que o intervalo entre chamadas. Isso sustenta priorizar medição do tempo e agendamento do loop antes de atribuir a baixa fluidez a um custo alto da física.

Esses números medem **atualização da simulação**, e não FPS de apresentação. A pintura final não foi instrumentada separadamente. A amostra curta também não comprova ausência de vazamentos. A sequência temporal completa está em `timer.csv`, incluindo posição da bola e duração de cada chamada.

## Arquivos de evidência e reprodução

- [Dados dos cenários](evidencias/e0-2026-10-22/scenarios.csv).
- [Amostra temporal de aproximadamente 40 segundos](evidencias/e0-2026-10-22/timer.csv).
- [Amostras de recursos do processo](evidencias/e0-2026-10-22/resources.csv).
- [Resumo calculado e verificações de integridade](evidencias/e0-2026-10-22/summary.json).
- [Hashes e preservação dos fontes](evidencias/e0-2026-10-22/sources-sha256.json).
- [Instruções do executor](../tools/e0/README.md).

O resumo foi executado com sucesso após a recarga do executor na IDE. Ele valida a integridade da observação e caracteriza o comportamento legado; não representa aprovação das regras atuais.

## Integração solicitada na IDE

`DelphiBlocks.groupproj` agora contém os dois executáveis, cada um com seu `.dproj`. O grupo inclui os targets de Build, Make e Clean para ambos. O jogo e o executor usam os mesmos fontes por referência e não têm dependência de execução entre si.

Para trocar o executável ativo, dê duplo clique em `Breakout.exe` ou `BaselineRunner.exe` no Project Manager; o ativo aparece em negrito. O grupo permanece aberto. A IDE foi deixada com `Breakout.exe` ativo, Windows 32-bit / Release, e o formulário principal visível: [estado final](evidencias/e0-2026-10-22/16-ide-final-grupo.png).

Ao salvar o grupo pela IDE, o Delphi atualizou apenas dois metadados do projeto principal: `ProjectVersion` de `19.5` para `20.3` e a declaração padrão de `ProjectName`. As demais opções do projeto principal foram preservadas. Os arquivos `.pas`, `.dfm`, `Breakout.dpr` e o README preexistente mantiveram seus hashes. O `Breakout.res` regenerado durante builds foi restaurado ao conteúdo inicial versionado.

## Encaminhamento para E1

Começar pelas correções localizadas: centralizar lançamento/pausa, encerrar o passo após perder uma vida, retirar `ProcessMessages` da pontuação e eliminar a ambiguidade dos nomes de direção. Manter os dois defeitos de colisão e resposta da raquete como regressões obrigatórias durante a evolução da mecânica.

A correção de `StrZero`, a seleção das faces laterais, a possibilidade de reentrada e a falta de conclusão de fase continuam fundamentadas pela leitura do fonte, mas não foram reproduzidas isoladamente na E0. Win64, a matriz completa de DPI e o ensaio de dez minutos ficam para as etapas de validação previstas no plano. Não foi aberta sessão da Gideon.
