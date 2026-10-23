# Verificação da apresentação E4

No grupo `DelphiBlocks.groupproj`, ative `BaselineRunner.exe`, selecione Win32/Debug e faça Build pela IDE. O projeto continua em `tools/e0/` para manter o atalho já integrado. Sem argumentos, executa 47 verificações e deixa o jogo aberto para avaliação. Opcionalmente:

```powershell
.\tools\e0\BaselineRunner.exe --e4 build\e4\view
.\tools\e0\BaselineRunner.exe --benchmark build\e4\after
```

`--e4` grava `view.json` e imagens do renderer em tamanho original, raquete ampliada, metade do esmaecimento e escalas 100/125/150/200%. Testa entrada, comandos, perda de foco, relógio real, impactos, vidas, vitória com animação pendente, F2, F1, diagnóstico, camadas, pixels da raquete, transparência e reutilização do buffer. As chamadas diretas aos handlers complementam a verificação manual; não substituem teclado/mouse reais.

`--benchmark` coleta 20 segundos sem diagnóstico e 20 com ele. Mantenha a janela ativa durante os 40 segundos. O controlador exclusivo do teste acompanha a bola. Grava `timer.csv` (intervalo/custo do handler e simulação), `paint.csv` (intervalo entre inícios de pinturas, composição, apresentação e custo total) e `resources.csv` (CPU acumulada, memória, handles, GDI e USER). O programa permanece aberto ao finalizar. Não há sincronização com o refresh do monitor; callback e pintura são métricas distintas. As partidas têm sementes diferentes e não representam cargas idênticas. Um terceiro argumento opcional, inteiro em milissegundos, substitui o intervalo do timer somente no processo do benchmark; por exemplo, `--benchmark <pasta> 15`.

Os testes não implementam powerups. O probe exclusivo do executor altera a largura da raquete para conferir o contrato do renderer e a centralização/clamp da entrada. O executável de produção desenha `Snapshot.Paddle.Width` usando os três sprites originais.

Os testes de DPI acima compõem bitmaps em tamanhos equivalentes. Isso verifica transformação e rasterização; não representa troca real de monitor ou mudança do DPI do Windows. Consulte [resultados e limites](../../docs/e4-resultados.md).
