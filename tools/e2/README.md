# Verificação do adaptador VCL da E2

O `BaselineRunner.exe` continua no grupo `DelphiBlocks.groupproj`. Ative-o, selecione **Win32 / Debug** e execute **Build**. Em **Run > Parameters**, informe `--e2`, depois execute **Run Without Debugging**. Também é possível rodar o executável já compilado:

```powershell
.\tools\e0\BaselineRunner.exe --e2
```

O resultado fica em `build/e2/latest/checks.json`; um segundo argumento escolhe outra pasta. A janela informa `checks passed` ou `checks failed`. A suíte termina com a partida pronta para conferência manual. Feche a janela principal antes de recompilar. Se ocorrer F2039, use o botão direito no projeto que falhou no painel Projects, execute **Clean** somente nele e depois **Build**, conforme a orientação do usuário.

São **52 verificações**: os 43 casos de fluxo da E1, adaptados à propriedade dos dados pelo motor, mais nove casos do adaptador. Eles confirmam que mudar posição/visibilidade/Tag de controles não altera as regras, que repintar não move nem pontua, que o timer não avança um motor em `Ready`, que colisões ocultam os controles mantendo seus IDs e que vitória/mensagens/diagnóstico seguem a fotografia do motor.

Desde a E3, o diagnóstico tem 23 chaves e informa velocidades por segundo e tempo acumulado/descartado. As regressões usam passos explícitos de 1/120 s. O [modo `--e3`](../e3/README.md) inclui esta suíte e verifica o relógio e as colisões na interface.

O [executor de console](../../tests/README.md) verifica o motor sem formulários. O modo `--e2` verifica a integração com os controles; nenhum deles substitui a conferência visual, DPI ou testes de duração.
