# E2 — Motor independente e estados explícitos

Data: 22/10/2026. Base: `c91c248`, merge da E1. Ambiente: Delphi 13 Community Edition, Windows.

**E2 concluída.** O motor executa as regras sem formulários, controles, labels, timer ou estado global da VCL. O formulário encaminha comandos e sincroniza a apresentação com uma fotografia dos dados. A física por tick permanece como referência para a E3.

## Estrutura e comportamento

| Arquivo | Responsabilidade |
| --- | --- |
| `src/Breakout.Types.pas` | Estados, comandos, configuração e registros da bola, raquete, blocos e fotografia; gerador aleatório com estado próprio. |
| `src/Breakout.Game.pas` | Regras, estados, vidas, pontos, comandos e passo da simulação. |
| `src/Breakout.Levels.pas` | Grade legada de 96 blocos, gerada a partir de semente e número da fase. |
| `src/Breakout.Texts.pas` | Textos da interface em `resourcestring`, separados do motor e preparados para tradução por recursos do Delphi. |
| `UMain.pas` | Entrada, agendamento, labels e adaptador temporário dos controles existentes. |
| `UDebug.pas` | Apresentação da fotografia do motor, incluindo estado, fase e semente. |
| `tests/` | Executor de console, casos do motor e preparação de cenários sem VCL. |

Os estados são `Ready`, `Playing`, `Paused`, `LevelComplete`, `GameOver` e `Victory`. `Execute` trata lançar/continuar, reiniciar, alternar pausa, desativar e avançar um passo em pausa. `MovePaddle` limita o movimento; `Step` avança somente em `Playing`. A interface exige diagnóstico visível para encaminhar F1. O estado do motor decide se um passo é permitido, mesmo que alguém habilite o timer.

Uma queda encerra o passo e leva a `Ready` ou `GameOver`. Destruir o último bloco encerra o passo em `LevelComplete` ou `Victory`. Continuar após uma fase intermediária carrega a seguinte em `Ready`, mantendo vidas e pontos. A configuração padrão mantém uma fase; configurações com mais fases reutilizam o gerador legado. Os layouts adicionais e a curva de dificuldade permanecem na E5.

Cada bloco mantém seu ID e posição na coleção depois de inativo. O adaptador oculta sua imagem e reutiliza os controles existentes. A sincronização não detecta colisões nem altera pontos. `Snapshot` copia a grade; modificar a fotografia ou um controle não altera os dados vivos do motor. Posições são `Double`, arredondadas na apresentação; a colocação inicial preserva as coordenadas inteiras da referência E1.

A semente é recebida explicitamente pelo motor. O formulário escolhe uma ao abrir e o diagnóstico a exibe. F2 reutiliza essa semente, restaurando a mesma grade e direção inicial; abrir outra execução escolhe uma nova. A geração dos blocos e o sorteio do lançamento têm estados separados e não dependem de `RandSeed` ou de sorteios externos.

`TLanguage` e o data module vazio foram removidos depois de migrar suas referências. Os labels pertencem ao formulário. A intenção de internacionalização informada pelo usuário está preservada em `Breakout.Texts.pas`: os textos continuam em inglês e podem ser traduzidos por recursos. Seleção de idioma e traduções adicionais não foram implementadas nesta etapa. O motor expõe dados e estados, sem frases da interface.

## Validação

| Execução | Resultado |
| --- | --- |
| Motor, Win32/Debug | 46 casos aprovados, zero falhas; retorno do console 0. |
| Motor, Win64/Debug | Os mesmos 46 casos aprovados, zero falhas; retorno 0. |
| Adaptador e regressões da E1, Win32/Debug | 52 casos aprovados, zero falhas: 43 de fluxo e nove do adaptador. |
| Build All final do grupo | Sucesso, com jogo, observador e testes em Win32/Debug. |
| Jogo principal, Win32/Release | Sucesso. |

Os builds finais pela IDE não exibiram warnings ou hints. O projeto de testes usa verificações de faixa e overflow em Debug e possui saídas separadas por plataforma/configuração. Foi necessário fechar e reabrir o grupo para a IDE reler as alterações das configurações de saída.

Uma tentativa intermediária do observador retornou F2039. O **Clean somente do BaselineRunner**, pelo botão direito no painel Projects, seguido de Build resolveu o erro, conforme a orientação do usuário.

Os testes cobrem comandos em estados inadequados, pausa imediata, perda de foco, três quedas sem movimento extra, pontuação única, blocos inativos, IDs estáveis, reinício, progressão e vitória, fotografias independentes, geração determinística e replay de 200 passos sob interferência no gerador aleatório global. O adaptador verifica que alterar controles não modifica as regras, que atualizar a apresentação não move nem pontua e que as mensagens e o diagnóstico refletem os dados.

Na interface do observador foram conferidos grade, lançamento por espaço, vidas, pontuação, remoção visual de blocos e atualização legível do diagnóstico. A prova automatizada dos comandos usa chamadas síncronas e complementa essa conferência; não representa uma partida longa nem uma certificação de DPI ou fluidez.

Foi encontrado DUnitX compilado para Win64, mas não um conjunto utilizável em Win32 ou os fontes nos diretórios verificados. O executor usa RTL e JSON, mantendo a referência Win32 sem instalar dependências. O probe de cenários é exclusivo dos testes e não é referenciado pelo executável principal.

## Evidências e reprodução

- [Motor Win32/Debug](evidencias/e2-2026-10-22/engine-win32-debug.json) e [Win64/Debug](evidencias/e2-2026-10-22/engine-win64-debug.json).
- [Adaptador Win32/Debug e regressões da E1](evidencias/e2-2026-10-22/adapter-win32-debug.json).
- [Build do observador](evidencias/e2-2026-10-22/01-build-runner-win32-debug.png), [motor Win32](evidencias/e2-2026-10-22/02-build-engine-win32-debug.png) e [motor Win64](evidencias/e2-2026-10-22/04-build-engine-win64-debug.png).
- [Jogo Release](evidencias/e2-2026-10-22/05-build-main-win32-release.png), [jogo Debug](evidencias/e2-2026-10-22/06-build-main-win32-debug.png) e [Build All final](evidencias/e2-2026-10-22/07-build-group-win32-debug.png).
- [Diagnóstico com estado, fase e semente](evidencias/e2-2026-10-22/03-debug-ready.png).
- [Configurações verificadas e hashes dos fontes/executáveis](evidencias/e2-2026-10-22/validation.json).
- [Como executar o console](../tests/README.md) e [o modo `--e2` do observador](../tools/e2/README.md).

As evidências de E0/E1 e a alteração local preexistente no README foram preservadas. O observador continua integrado ao grupo e seus cenários agora preparam o motor diretamente; o resumo considera a pontuação do bloco isolado porque a coleção de teste mantém um segundo bloco distante. Reprocessar uma cópia dos CSVs históricos produziu o mesmo resumo da E0, sem modificar seus arquivos.

## Próxima etapa e limites

A E3 corrigirá o relógio, as unidades de velocidade, a linha inferior de perda e as colisões. Continuam pendentes o ângulo proporcional da raquete e os defeitos de ricochete vertical e lateral dos blocos relatados pelo usuário. Os testes desta entrega não demonstram que essas regras geométricas estejam corretas.

O jogo ainda move controles VCL, cria fotografias da grade para sincronização e atualiza o diagnóstico a cada passo. A E4 tratará composição do quadro e medição de desempenho. Nesta entrega não há resultado de FPS, validação visual Win64, matriz de DPI ou teste de duração.
