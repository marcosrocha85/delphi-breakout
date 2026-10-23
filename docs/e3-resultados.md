# E3 — tempo e colisões contínuas

Data: 22/10/2026. Base: merge `3af2531` da E2. Implementação na branch `codex/e3-physics`, sem abertura de sessão da Gideon.

A E3 corrige os ricochetes dos blocos e implementa a resposta proporcional da raquete. A bola agora usa geometria circular, e a raquete usa corpo reto com pontas semicirculares, conforme o sprite e a observação do usuário. O jogo continua com os sprites e controles VCL existentes; o desenho em superfície única pertence à E4.

## Resultado dos defeitos relatados

| Cenário dirigido | Resultado verificado |
| --- | --- |
| Bola descendo atinge o topo do bloco | Destrói/pontua uma vez, inverte Y para cima e usa o tempo restante após o contato. |
| Bola subindo atinge a face inferior | Inverte Y para baixo, preservando X no contato isolado da face. |
| Impacto na face esquerda ou direita, subindo ou descendo | Inverte X e preserva Y; o bloco inativo não volta a colidir ou pontuar. |
| Bola passa perto de um canto vazio | O contato considera o arco circular; entrar apenas no retângulo envolvente não destrói o bloco. |
| Bola encontra a raquete | O deslocamento entre os centros determina o ângulo. Pontas arredondadas usam a soma dos raios da bola e da raquete. |

## Implementação e parâmetros

- `Breakout.Physics`: varredura contínua de círculo contra faces e quatro arcos dos blocos; varredura contra cápsula da raquete; normal, penetração, reflexão e ângulo proporcional, sem VCL.
- `Breakout.Game`: procura o primeiro contato em cada passo, avança até ele, reflete/separa e continua o tempo restante. Contatos simultâneos usam ordem estável: paredes esquerda/direita/topo, raquete, ordem da coleção de blocos e perda inferior. Normais de emenda que já estão separando não provocam uma segunda inversão. Todos os blocos no contato simultâneo são desativados e pontuados uma vez.
- `Breakout.Loop`: acumulador independente da VCL, com passos de **1/120 s**, aceite máximo de **100 ms** e até **12 passos por callback**. Pausa, retomada, desativação, reinício, perda de vida e transições de fase limpam o resto acumulado. O tempo não executado após uma transição terminal não é carregado para a próxima partida/vida.
- `UMain`: mede o tempo real com `TStopwatch.GetTimeStamp/Frequency`, solicita trabalho a cada **16 ms** e apresenta a fotografia após os passos. Os relógios são reiniciados nas transições por comando; F1 avança exatamente um passo, apenas pausado com diagnóstico visível.
- Velocidade inicial total **240 unidades/s**, com lançamento a 45°. A raquete preserva a velocidade incidente; usa até **60°** em relação à vertical e mínimo de **5°** na região central, preservando o sinal horizontal de entrada no centro exato. Assim, a componente vertical é pelo menos metade da velocidade total após o rebote.
- Bola de diâmetro **17**; raquete **50 × 15**, com raio das pontas **7,5**. A bola fica centralizada em coordenadas fracionárias em `Ready`; o arredondamento ocorre somente ao sincronizar os controles.
- Até **oito grupos de impactos por passo**. Se esse orçamento excepcional se esgotar, o motor fica no último contato seguro e contabiliza o tempo restante descartado, sem avançar através dos objetos. Separação espacial de `1e-6` unidade e tolerância temporal de `1e-10` s evitam contatos repetidos por arredondamento.
- A perda ocorre quando a bola cruza completamente o limite inferior (topo da bola em Y=453), independentemente da posição horizontal da raquete. A perda de vida e a conclusão terminam o passo e o processamento acumulado.
- O diagnóstico possui **23 chaves**, com velocidade, passo, passos por callback, total de passos incluindo F1, acumulador, callbacks limitados e tempo descartado. Os contadores de agendamento são cumulativos da janela; os contadores físicos do motor zeram no reinício.

O mínimo de 5° introduz uma pequena região central de ângulo mínimo; fora dela, o ângulo varia proporcionalmente ao ponto de contato. O movimento da raquete continua instantâneo entre passos, conforme a entrada atual do mouse; não há cálculo de impulso ou varredura de uma raquete em movimento nesta etapa.

## Validação realizada

Builds feitos pela IDE **Delphi 13 Community Edition, 37.0.60542.8024**. O jogo e o console foram compilados em Win32/Win64, Debug/Release. O BaselineRunner foi compilado em Win32 Debug. Ocorrências de F2039 foram resolvidas com **Clean somente no projeto que falhou**, seguido de Build, conforme a orientação do usuário.

| Configuração | Estados e regras (`engine.json`) | Física e tempo (`physics.json`) | Resultado |
| --- | ---: | ---: | --- |
| Win32 Debug | 46 | 104 | 150 aprovados, zero falhas |
| Win32 Release | 46 | 104 | 150 aprovados, zero falhas |
| Win64 Debug | 46 | 104 | 150 aprovados, zero falhas |
| Win64 Release | 46 | 104 | 150 aprovados, zero falhas |
| Adaptador VCL, Win32 Debug | 52 regressões E1/E2 + 11 casos E3 | — | 63 aprovados, zero falhas |

O console Debug mantém checagem de faixa e overflow. A física verifica as quatro faces, os quatro cantos circulares, tangência, sobreposição, emendas e paredes simultâneas, alta velocidade, uso do tempo restante, orçamento de colisões, pontuação única e perda inferior sob a própria raquete. A raquete é verificada por ângulos, módulo da velocidade, centro, duas pontas, ausência de colisão na quina vazia e passagem ascendente.

As agendas de **30/60/144 chamadas por segundo**, com os mesmos comandos e tempo simulado, executaram **360 passos em três segundos** e produziram a mesma posição, velocidade, estado, vidas, pontos e blocos ativos, dentro da tolerância numérica dos testes. Atraso de 1,5 s executou no máximo 12 passos e registrou **1,4 s descartado**. Pausa, desativação, reinício, perda de vida, vitória e troca de fase não carregaram dívida de tempo.

Dez sementes executaram **3.600 passos cada**, ou 30 segundos simulados por partida, com a raquete acompanhando a bola. Todas preservaram a velocidade de 240, os limites do campo e orçamento físico sem esgotamento. São simulações de regras; não representam cinco minutos medidos de desenho da interface nem um teste de jogabilidade humana.

O modo `--e3` também exercitou o relógio real da interface com esperas curtas controladas, a retomada sem salto, os sprites/placar após impactos superior e laterais e os valores do diagnóstico. A conferência ao vivo observou os sprites preservados, lançamento, movimento, destruição/pontuação de bloco, queda e reinício. O estado pausado é coberto pela suíte automatizada; a conferência manual desta etapa não é usada como prova adicional de pausa.

Relatórios completos, capturas e hashes estão em [evidencias/e3-2026-10-22](evidencias/e3-2026-10-22/validation.json). Os resultados de E0/E1/E2 e as duas alterações locais do README foram preservados. As preferências locais da IDE nos `.dproj` também foram preservadas, separadas das referências novas necessárias à PR.

## Limites e próxima etapa

A E3 valida a mecânica e a integração atual. Não certifica FPS de apresentação, DPI em várias escalas, ausência de vazamentos por horas, nem equivalência binária de ponto flutuante entre plataformas. As simulações são reproduzíveis dentro de cada configuração, e os testes usam tolerância numérica explícita.

A **E4** pode agora substituir a movimentação de `TImage` por uma superfície única com buffer/cache e medir atualização e pintura separadamente. Interpolação visual e limitação da frequência do diagnóstico devem ser avaliadas nessa etapa; a física permanece a 120 passos/s.
