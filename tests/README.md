# Testes do motor

Abra `DelphiBlocks.groupproj` e ative `Breakout.Tests.exe` no painel Projects. O projeto é um console que depende somente da biblioteca padrão e das units do motor, sem `Forms`, controles VCL, HUD ou diagnóstico.

Selecione **Win32 / Debug** e execute **Build** na IDE. Nesta instalação Community Edition, o compilador de linha de comando não produz o executável; o build deve ser feito pela IDE. Depois de compilar, execute na raiz do repositório:

```powershell
.\build\tests\Win32\Debug\Breakout.Tests.exe
```

O retorno é **0** para sucesso, **1** para falhas nos testes e **2** para erro do executor. O relatório é `build/e2/latest/engine.json`. Um primeiro argumento permite escolher outra pasta. Win64/Debug foi validado com:

```powershell
.\build\tests\Win64\Debug\Breakout.Tests.exe build\e2\win64-debug
```

Os **46 casos** verificam estados, comandos, limites da raquete, três quedas, pontuação única, blocos inativos, IDs estáveis, reinício, conclusão de fase/vitória, isolamento das fotografias e reprodução com semente explícita. Os testes executam passos síncronos; não dependem do relógio nem do timer do Windows.

`Breakout.TestScenarios.pas` contém um probe usado somente nos executores de testes para preparar quedas e blocos isolados. Ele não é referenciado pelo jogo principal. Os casos observam resultados de regras e transições; não exigem coordenadas de controles visuais. `Snapshot` devolve uma cópia da grade para impedir alterações externas no estado vivo.

A instalação contém DCUs de DUnitX para Win64, mas não foi encontrado o framework utilizável em Win32 nem seus fontes nos diretórios verificados. A suíte usa um executor pequeno com RTL e JSON para manter a referência Win32 sem dependências adicionais. Migrar para um framework depois não exige alterar a API do motor.

As verificações do adaptador VCL ficam no [modo `--e2` do BaselineRunner](../tools/e2/README.md). Ângulos proporcionais, faces/cantos, alta velocidade e passo fixo continuam na E3; os testes atuais não certificam essas regras de física.
