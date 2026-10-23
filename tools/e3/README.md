# Verificação visual da E3

O `BaselineRunner.exe` continua no mesmo `DelphiBlocks.groupproj`. Ative-o, selecione **Win32 / Debug** e execute **Build**. Em **Run > Parameters**, informe `--e3` e execute **Run Without Debugging**. Também é possível executar o binário já compilado:

```powershell
.\tools\e0\BaselineRunner.exe --e3
```

O resultado fica em `build/e3/latest/checks.json`; um segundo argumento escolhe outra pasta. O título indica `PASSED` ou `FAILED`. O executor deixa a partida em `Ready`, permitindo jogar e conferir F10. Feche a janela principal antes de recompilar. Se ocorrer F2039, use o botão direito **somente no projeto que falhou**, execute **Clean** e depois **Build**, conforme a orientação do usuário.

São **63 casos**: 43 regressões de fluxo da E1, nove do adaptador da E2 e 11 da E3. As regressões antigas agora injetam tempo explícito no mesmo `AdvanceFrame` usado pelo timer, com expectativas em unidades/segundo. A E3 verifica intervalo de 16 ms, medição real com `TStopwatch`, múltiplos passos por callback, retomada sem compensar a pausa, ocultação/pontuação dos blocos no topo e nas duas laterais, posição refletida, diagnóstico de velocidade/atrasos e F1 de 1/120 s.

O teste do relógio usa esperas curtas de 30 e 120 ms somente no executor; o código do jogo não espera nem chama `ProcessMessages`. Os limites verificam quantidade de passos, sem exigir uma frequência exata do agendador do Windows. A física detalhada está nos [150 testes sem VCL](../../tests/README.md).

A janela de diagnóstico apresenta 23 chaves, incluindo velocidades por segundo, passo de 8,333 ms, passos do último callback, total de passos (inclui F1), resto do acumulador, atrasos descartados e limite de colisões. Os contadores são cumulativos da janela; F2 limpa a partida e os limites físicos do motor, enquanto o histórico do agendamento permanece disponível.

Essa suíte valida o adaptador atual de `TImage`; a superfície única, interpolação, DPI e medição de pintura pertencem à E4. As evidências históricas de E0/E1/E2 permanecem preservadas.
