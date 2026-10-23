# Ajustes visuais após avaliação — 23/10/2026

- Fade: 350 → 250 ms.
- Contador: 20 → 10 ms por ponto, incremento 1; 100 pontos em um segundo.
- Balanceamento de Marcos: verde 100, amarelo 150, ciano 200, vermelho 250, prata 400, ouro 500.

Build pela IDE Delphi 13 Community: jogo e BaselineRunner Win32 Debug; console Win64 Debug. O erro F2039 do jogo foi resolvido com Clean somente no projeto Breakout, pelo painel Projects, seguido de Build. Build All do grupo aprovado depois da limpeza.

Resultado: 46 regressões do motor + 104 da física + 41 da apresentação = 191 casos sem falhas; mais 47 verificações VCL/bitmap em Win32 Debug, sem falhas. Foram atualizadas as expectativas da tabela e do tempo de contagem e conferidas as três durações configuráveis de fade (250/350/500 ms), além do bitmap no início, metade e fim do efeito padrão.

Estes relatórios complementam a matriz de quatro configurações da entrega original em `../e4-2026-10-22/`; essa matriz não foi repetida integralmente para o ajuste de parâmetros. As medições de desempenho anteriores permanecem como referência histórica.
