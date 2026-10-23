# Testes do motor e da física

Abra `DelphiBlocks.groupproj` e ative `Breakout.Tests.exe` no painel Projects. O console depende somente da RTL e das units do motor, sem formulários ou controles VCL. Faça **Build** pela IDE do Delphi 13 Community Edition; o compilador de linha de comando desta instalação não produz o executável.

Depois do Build, execute na raiz do repositório:

```powershell
.\build\tests\Win32\Debug\Breakout.Tests.exe
.\build\tests\Win32\Release\Breakout.Tests.exe build\e3\win32-release
.\build\tests\Win64\Debug\Breakout.Tests.exe build\e3\win64-debug
.\build\tests\Win64\Release\Breakout.Tests.exe build\e3\win64-release
```

Cada comando exige o Build da respectiva configuração. Retornos: **0** para sucesso, **1** para falhas, **2** para erro do executor. Sem argumento, os relatórios ficam em `build/e3/latest/engine.json` e `physics.json`; o primeiro argumento escolhe outra pasta.

São **150 casos** por configuração: 46 regressões de estados, comandos, vidas, pontuação, IDs, conclusão, sementes e isolamento das fotografias, mais 104 casos de geometria, colisões e tempo. Estes cobrem quatro faces e quatro cantos dos blocos, laterais nas duas direções verticais, falsos contatos de quinas, tangência, sobreposição inicial, emendas, contatos simultâneos, alta velocidade, tempo restante, limite de impactos, bola circular e raquete em cápsula. Também cobrem ângulo proporcional, velocidade constante, centro da raquete, perda inferior, atrasos, pausas e troca de fase.

As agendas de 30/60/144 chamadas por segundo executam os mesmos 360 passos em três segundos com os mesmos comandos e comparam posição, velocidade, estado, vidas, pontos e blocos ativos. Dez sementes executam 3.600 passos cada, equivalentes a 30 segundos simulados por partida, com acompanhamento da bola pela raquete. Isso não é um benchmark de pintura nem uma partida humana.

`Breakout.TestScenarios.pas` prepara cenários somente nos executores; não é referenciada por `Breakout.dpr`. Os testes síncronos usam `TGame.Step` ou `TGameLoop.Advance`, sem esperar pelo timer do Windows. O [modo `--e3` do BaselineRunner](../tools/e3/README.md) verifica a integração VCL e o relógio real.

A suíte pequena em RTL/JSON mantém Win32 sem dependências adicionais: a instalação possuía DCUs de DUnitX para Win64, mas não foi encontrado um framework utilizável em Win32 com fontes. A [evidência da E3](../docs/e3-resultados.md) registra as quatro configurações validadas.
