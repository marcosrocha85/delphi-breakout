# Plano de evolução do Delphi Breakout

Data: 22/10/2026. Ambiente de execução informado: Delphi 13, Windows.

Status: implementação incremental; **E0, E1 e E2 concluídas em 22/10/2026**. O diagnóstico e a referência estão no [relatório da E0](e0-referencia.md); as correções de fluxo, no [resultado da E1](e1-resultados.md). O [resultado da E2](e2-resultados.md) registra o motor independente, os estados, a preparação dos textos para tradução e os testes do motor/adaptador. Próxima etapa: E3, tempo e física.

## 1. Objetivo e direção

Melhorar a organização dos métodos e funções, a previsibilidade da mecânica e a fluidez da renderização, mantendo o projeto pequeno, didático e fácil de abrir e testar no Delphi 13.

A direção recomendada é continuar com VCL: primeiro corrigir os pontos frágeis, depois extrair um motor independente dos controles e, em seguida, desenhar o jogo em uma única superfície. Cada etapa deve terminar com uma versão compilável e jogável. Recursos visuais e novas fases entram depois dessa base.

Premissas de escopo:

- Preservar inicialmente os sprites e a identidade visual existentes em `images/` e no DFM.
- Manter mouse, clique/espaço para lançar, F2 para reiniciar, F3 para pausar e F10 para diagnóstico; restringir F1 ao avanço controlado em diagnóstico.
- Usar Win32 Debug como primeira referência e validar também Win64 e Release antes de concluir.
- Adotar uma área lógica fixa inicialmente, sem transformar redimensionamento livre ou tela cheia em requisito.
- Priorizar a biblioteca padrão e VCL. Troca de framework gráfico, rede, editor de fases e sistemas extensos de power-ups ficam fora da primeira entrega.
- O plano e os resultados ficam no repositório, sem abertura de sessão da Gideon. A implementação prossegue por etapas autorizadas após a elaboração inicial do plano.

## 2. Diagnóstico com evidências

As linhas abaixo se referem aos fontes legados do diagnóstico inicial. Os resultados de E1 e E2 registram os itens já tratados; os defeitos de física continuam na E3. O relato lateral acrescentado pelo usuário permanece identificado separadamente.

| Prioridade | Evidência local | Consequência e ação proposta |
| --- | --- | --- |
| Alta | `UMain.pas:81`, `Timer1Timer` | Um único método trata limites, raquete, vidas, diagnóstico, blocos, descarte e movimento. Extrair responsabilidades antes de mudar a representação dos objetos. |
| Alta | `UMain.dfm:481`, `Interval = 50`; `UMain.pas:207` | Há aproximadamente 20 chamadas nominais por segundo, com deslocamento em pixels por chamada. Separar tempo de simulação da frequência de pintura. Diminuir somente o intervalo aceleraria o jogo. |
| Alta | `UMain.pas:111` a `UMain.pas:126`, resposta da raquete | Nas três regiões, os módulos dos deslocamentos X/Y são iguais: 15/15 nas pontas e 5/5 no centro. A inclinação permanece em 45°; mudam a velocidade e, nas pontas, o sentido horizontal. Calcular a proporção X/Y a partir do ponto de impacto para obter o ângulo proporcional desejado. |
| Alta | `UMain.pas:153` e `UMain.pas:166` | A interseção é examinada antes do deslocamento, e a face atingida depende de condições sobrepostas, sem instante de impacto nem posição anterior. Corrigir faces, cantos, penetração e atravessamento em alta velocidade. |
| Alta | `UMain.pas:166` a `UMain.pas:184`, seleção da face do bloco | A condição vertical do primeiro ramo já é garantida pelo teste externo de interseção; as condições horizontais são iguais às do `else if`. Assim, o ramo `bY := Up` é inacessível nesse fluxo: uma bola descendo pode continuar descendo e destruir o bloco sem refletir. O segundo ramo lateral também repete condições já satisfeitas e não distingue o lado atingido. Corrigir a seleção da face e testar cada sentido de aproximação. |
| Alta | Relato do usuário em 22/10/2026: colisão na lateral do bloco | Às vezes a bola destrói o bloco sem ricochetear horizontalmente, continuando no mesmo sentido. Registrar e reproduzir separadamente os impactos nas faces esquerda e direita; corrigir na E3 para inverter a velocidade horizontal, preservando a vertical em contatos isolados de face e pontuando o bloco uma única vez. Este caso foi relatado pelo usuário; ainda falta uma reprodução dirigida específica. |
| Alta | `UMain.pas:104` e `UMain.pas:130` | A raquete usa a borda esquerda da bola e margens fixas; a perda de vida depende também da posição horizontal relativa à raquete. Definir geometria coerente e uma linha inferior de perda independente da raquete. |
| Alta | `UMain.pas:132` e fim de `Timer1Timer` | Depois de `Reposition` na perda de vida, a chamada continua e desloca a bola novamente. Encerrar o passo assim que houver transição de estado. |
| Alta | `UMain.pas:30`, `PlayerClick`, `Pause`, `FormKeyDown` | Estado espalhado entre dois booleanos e `Timer1.Enabled`. Espaço durante pausa passa por `PlayerClick`, que reposiciona; F1 chama a atualização diretamente em qualquer estado. Centralizar as transições e as permissões de cada comando. |
| Alta | `UMain.pas:413`, `Application.ProcessMessages` | Processamento de mensagens dentro da pontuação permite reentrada durante colisões, reinício ou descarte de controles. Remover essa chamada e atualizar a apresentação depois de concluir o passo. |
| Alta | Constantes `Left`/`Right` e usos em `UMain.pas:179` e `UMain.pas:294` | `Left` também é uma propriedade do formulário. Eliminar a ambiguidade com nomes específicos e depois substituí-los por velocidade vetorial. Incluir regressão com a janela em posições diferentes e F10 aberto. |
| Média | `UMain.pas:147`, `UMain.pas:198`, `CreateBars` | Os blocos são descobertos por `ComponentCount`, tipo e `Tag`; controles visuais são o estado do jogo. Usar uma coleção de dados com identidade, geometria, pontos e estado ativo. |
| Média | `UMain.pas:361`, `Randomize` dentro do laço | A semente é reinicializada a cada bloco. Inicializar uma vez e permitir uma semente conhecida para reproduzir fases e testes. |
| Média | `UMain.pas:327`, `StrZero` | Para mais de nove caracteres, o método atribui `S` a `Result` e depois concatena `S` novamente. Substituir por formatação com largura mínima, preservando valores maiores integralmente. |
| Média | `UMain.pas:340`, `CreateBars` | Só há implementação do nível 1; não existe transição quando todos os blocos acabam. Separar geração de fase e detectar conclusão. A grade atual contém 12 colunas × 8 linhas. |
| Média | `UMain.pas:300`, `UMain.pas:316`; posições em `UDM.pas` | Bola, raquete, HUD e mouse dependem de coordenadas fixas e da posição externa da janela. Adotar geometria lógica e conversão entre coordenadas de cliente e do jogo. |
| Média | `UDM.pas:9`, `UDM.pas:42`, `UMain.pas:219` | `TLanguage` cria labels diretamente em `FrmMain`, e a instância é criada sem owner e sem liberação explícita nos fontes analisados. Separar textos da apresentação e definir quem cria e libera cada objeto. |
| Baixa | `UDM.pas`, `UDM.dfm`, `Breakout.dpr` | Data module vazio, campos, parâmetros e variáveis sem uso. Remover depois de desacoplar os textos e conferir referências no projeto. |
| Baixa | `UDebug.pas:43` versus `UMain.pas:161` | As chaves de diagnóstico diferem (`Bar Name`/`Name of Bar`, por exemplo). Padronizar e mostrar uma fotografia consistente do estado após cada passo. |
| Apoio | `UMain.dfm:10`, `DoubleBuffered = True` | O formulário já usa buffer duplo. A melhoria deve atacar a movimentação de controles, a cadência e a composição do quadro, além de medir o resultado. |
| Apoio | `Breakout.dproj:79`, `Breakout.dproj:94`, `Breakout.dproj:201` | Win32 e Win64 compartilham saída de DCU, e o arquivo de targets aparece importado duas vezes. Revisar configurações com a IDE e separar saídas por plataforma/configuração. |

## 3. Organização desejada

Extrair poucas units com responsabilidades claras. Não criar hierarquias de objetos para cada sprite, contêiner de dependências ou barramento genérico de eventos.

| Arquivo proposto | Responsabilidade |
| --- | --- |
| `UMain.pas` / `UMain.dfm` | Ciclo de vida da janela, leitura da entrada, agendamento, conversão de coordenadas e solicitação de pintura. Eventos pequenos, delegando ao motor. |
| `src/Breakout.Game.pas` | `TGame`, registros da bola/raquete/blocos, configuração, estados, vidas, pontos, fase e comandos. Sem dependência de formulários ou controles VCL. |
| `src/Breakout.Types.pas` | Tipos de entidades, configuração, estados/comandos e fotografia; extraídos na E2 para compartilhamento sem VCL. |
| `src/Breakout.Texts.pas` | Textos da interface em `resourcestring`, preservando a intenção de internacionalização sem acoplar idiomas ao motor. |
| `src/Breakout.Physics.pas` | Funções de colisão, instante de impacto, normal e reflexão; sem pontuação, labels ou desenho. Extrair junto com a revisão da física. |
| `src/Breakout.Levels.pas` | Definições e geração de fases a partir de dados e semente explícita. Extrair quando a progressão justificar. |
| `src/Breakout.Renderer.Vcl.pas` | Recursos gráficos, buffer, desenho do cenário, blocos, bola, raquete, HUD e sobreposições. |
| `UDebug.pas` / `UDebug.dfm` | Exibição de diagnóstico e comandos de inspeção, consumindo uma fotografia do motor. |
| `tests/Breakout.Tests.dpr` e respectivas units | Testes do motor e da física, executáveis sem abrir a janela do jogo. |

Na primeira etapa, manter os formulários nos caminhos atuais para reduzir mudanças nos arquivos de projeto. Atualizar as referências do `.dpr`/`.dproj` explicitamente ao adicionar units; evitar search paths globais da máquina.

Convenções:

- Usar nomes em inglês para identificadores, coerentes com o projeto: `StartNewGame`, `LaunchBall`, `LoseLife`, `LoadLevel`, `UpdateHud` e `FormatScore`.
- Usar prefixo `F` para campos privados e nomes que expressem unidade/propósito, como `Velocity`, `BallSpeed` e `FixedDeltaSeconds`.
- Substituir `bA`/`bV` por velocidade X/Y em unidades lógicas por segundo. Os valores atuais representam deslocamentos por chamada, apesar dos nomes e comentários de ângulo.
- Declarar configuração explícita para dimensões, margem do HUD, velocidades e passo de simulação. Evitar números espalhados pelos handlers.
- Separar comandos que alteram estado de funções que calculam geometria e formatação. Comentar decisões e limitações; apagar código comentado abandonado.
- A janela possui e libera o motor e o renderizador; o motor possui seus dados; o renderizador possui seus bitmaps. O formulário de diagnóstico não possui o jogo.
- Substituir `TLanguage` inicialmente por `resourcestring` e apresentação no formulário/renderizador; remover `UDM` e a criação de `DM` somente quando não houver referências restantes.

## 4. Mecânica e tempo

### Estados e comandos

Estados propostos: `Ready`, `Playing`, `Paused`, `LevelComplete`, `GameOver` e `Victory`.

| Situação | Comportamento esperado |
| --- | --- |
| Início / F2 | Restaurar três vidas, zerar pontos, carregar fase 1 e entrar em `Ready`. Bola presa à raquete. |
| Clique / espaço em `Ready` | Lançar a bola e entrar em `Playing`. |
| F3 em `Playing` / `Paused` | Alternar pausa preservando posição, velocidade, pontos e fase. |
| Clique / espaço em `Paused` | Permanecer pausado; F3 continua sendo o comando de retomada. |
| Perda de foco em `Playing` | Entrar em `Paused`. Voltar à janela exige F3 para retomar. |
| Bola cruza completamente o limite inferior | Descontar uma única vida; entrar em `Ready` ou `GameOver`; terminar o passo atual. |
| Último bloco destruído | Entrar em `LevelComplete`, preservando vidas e pontos. Clique/espaço carrega a próxima fase em `Ready`. |
| Última fase concluída | Entrar em `Victory`, com mensagem e F2 para nova partida. |
| F1 em diagnóstico | Avançar exatamente um passo apenas quando pausado; nunca lançar uma partida nem avançar após game over. |
| F10 | Abrir/fechar diagnóstico sem alterar o motor ou reposicionar obrigatoriamente a janela principal. |

`Timer.Enabled` passa a ser detalhe do agendamento; o estado do motor decide se a simulação pode avançar. Reinício, pausa, perda de vida e troca de fase devem também atualizar o relógio/acumulador, impedindo um salto na retomada.

### Simulação

- Usar posições e velocidades em ponto flutuante; arredondar apenas para desenhar.
- Medir o tempo real com `System.Diagnostics.TStopwatch`, inicializado explicitamente. A API fornece medição de alta resolução quando disponível. [Documentação oficial](https://docwiki.embarcadero.com/Libraries/Florence/en/System.Diagnostics.TStopwatch).
- Começar com passo fixo de `1/120 s`, acumulador e acionamento do timer em torno de 16 ms. São valores iniciais para medição e ajuste.
- O timer solicita trabalho; o tempo medido determina quantos passos executar. `TTimer` usa mensagens `WM_TIMER`, por isso seu intervalo não deve ser tratado como relógio exato da física. [Documentação oficial](https://docwiki.embarcadero.com/Libraries/Florence/en/Vcl.ExtCtrls.TTimer).
- Limitar o tempo acumulado aceito por chamada, inicialmente a 100 ms, e a 12 passos; descartar atraso excedente de forma explícita e contabilizá-lo no diagnóstico. Nunca compensar uma pausa longa avançando a partida de uma só vez.
- Manter atualização e desenho na thread principal nesta entrega. Remover `Application.ProcessMessages` do ciclo e não adicionar espera ocupada.
- Se a cadência de pintura tornar o movimento visivelmente irregular, interpolar entre os dois estados de simulação usando o restante do acumulador. Reinicializar ambos nas transições para evitar rastros ou saltos.
- Para calibrar, os deslocamentos atuais de 5/5 e 15/15 a cada 50 ms equivalem nominalmente a velocidades vetoriais de aproximadamente 141 e 424 unidades/s. Usar essa faixa como referência inicial, sem assumir que a execução atual mantém exatamente esse ritmo.

### Colisões e resposta da raquete

Representar a bola como círculo e os blocos/raquete como retângulos, com geometria independente dos controles.

1. Procurar o impacto mais próximo no tempo restante do passo, incluindo paredes, raquete e blocos ativos.
2. Usar detecção varrida de círculo contra retângulo, cobrindo faces e cantos. A expansão retangular simples produz falsos contatos nos cantos; validar essa região especificamente.
3. Avançar até o contato, refletir a velocidade pela normal e afastar a bola por uma pequena tolerância geométrica.
4. Marcar imediatamente o bloco atingido como inativo e somar seus pontos uma vez. Empates entre contatos devem ter resolução determinística.
5. Consumir o tempo restante do passo, com limite de impactos por passo. Se o limite for atingido, interromper o restante e registrar o caso, sem entrar em laço infinito.
6. Processar perda de vida ou conclusão de fase como transição terminal daquele passo. Um mesmo bloco não volta a colidir depois de inativado.

Na raquete, aceitar contato pela parte superior quando a bola estiver descendo. Calcular o ponto normalizado de impacto entre -1 e +1 a partir dos centros; mapear para um ângulo contínuo, inicialmente até 60° em relação à vertical. A velocidade total permanece definida pela dificuldade, em vez de mudar abruptamente entre três regiões.

No centro, adotar um pequeno ângulo mínimo configurável, inicialmente 5°, preservando o sinal horizontal anterior, para evitar trajetórias verticais intermináveis. Validar a sensação dessa regra jogando; manter também um componente vertical mínimo para evitar movimento quase horizontal.

## 5. Renderização e entrada

A primeira melhoria é compor o quadro inteiro em uma única superfície VCL, preservando a arte atual.

- Usar um `TPaintBox` na janela e um `TBitmap` persistente como buffer do quadro. Desenhar no buffer e apresentá-lo no `OnPaint`; o evento de pintura apenas lê o estado. `TPaintBox` fornece o canvas para esse desenho. [Documentação oficial](https://docwiki.embarcadero.com/Libraries/Florence/en/Vcl.ExtCtrls.TPaintBox).
- Solicitar pintura com `Invalidate` depois da atualização; também permitir repintura normal após minimizar/restaurar ou cobrir a janela, inclusive pausado.
- Carregar sprites uma vez e recriar buffers somente quando o tamanho necessário mudar. Evitar criar bitmaps, imagens e controles por quadro ou por colisão.
- Desenhar na ordem: fundo, blocos ativos, raquete, bola, efeitos, HUD e mensagens. HUD e mensagens deixam de ser labels independentes ao final da migração.
- Migrar os sprites embutidos no DFM para recursos incorporados ao executável, preservando transparência e cores. Não depender do diretório de trabalho para encontrar `images/`.
- Reusar o buffer duplo já habilitado no formulário enquanto for necessário e medir o custo da composição; não acrescentar sucessivas cópias de tela sem benefício observado.
- Começar com referência lógica de 688 × 453, separando explicitamente a faixa inferior do HUD da área de jogo. Ajustar a altura útil após comparar a posição atual da raquete e dos indicadores.
- Usar uma única transformação uniforme entre coordenadas lógicas e pixels do cliente, centralizando a área e preenchendo eventuais margens. Aplicar a transformação inversa ao mouse; não aplicar a escala de DPI duas vezes.
- Para entrada, converter a posição do mouse para coordenadas do cliente e depois lógicas; limitar a raquete entre zero e largura útil menos sua largura. Eliminar subtrações manuais da posição externa da janela.
- Usar um único caminho de entrada da superfície; ao usar captura do mouse durante arraste, liberá-la em pausa, desativação e fechamento. Não prender o cursor ao monitor por padrão.
- Em `Ready`, acompanhar a raquete com a bola centralizada e acima dela. Em pausa, congelar também a raquete, coerente com o comportamento pretendido atual.
- Conferir escala de 100%, 125%, 150% e 200%, nitidez dos sprites, legibilidade do HUD e movimentação entre monitores. O `.dproj` contém configurações `PerMonitorV2`; confirmar o resultado efetivo do build antes de mudar manifestos.

Depois da estabilidade, acrescentar feedback discreto: brilho curto no bloco atingido, partículas limitadas e mensagem de fase concluída. Efeitos usam um estado visual separado e não alteram colisões, sorteios de fases ou pontuação. Sons e novos sprites são opcionais e devem ser avaliados como uma entrega posterior.

## 6. Etapas de implementação

Cada etapa deve resultar em uma alteração pequena e revisável, com build e verificação antes de iniciar a seguinte. Não misturar movimentação de arquivos com reescrita completa da física no mesmo lote.

### Etapa 0 — Registrar a referência atual

**Concluída:** ver [referência e evidências da E0](e0-referencia.md). O executor de diagnóstico está integrado ao grupo `DelphiBlocks.groupproj`, ao lado do jogo principal.

- Compilar pela IDE no Delphi 13 e registrar plataforma/configuração, avisos, erros e versão efetivamente utilizada.
- Jogar e anotar comportamento de lançamento, pausa, perda de foco, F2, F1, F10, vidas e colisões suspeitas.
- Registrar uma captura de tela e uma amostra curta de execução; distinguir a imagem histórica em `images/main game.jpg` da execução atual.
- Medir cadência de atualização e consumo de recursos com e sem diagnóstico, sem assumir desempenho a partir do intervalo configurado.
- Verificar o estado do Git antes de cada lote. Na elaboração deste plano já havia alteração local em `README.md`, que deve ser preservada. A branch local também estava um commit atrás de `origin/main` segundo as referências locais; reconciliar essa diferença antes de implementar, sem sobrescrever trabalho existente.

**Saída:** referência reproduzível de build e jogabilidade, com problemas observados separados dos inferidos por leitura.

### Etapa 1 — Organizar o código e corrigir defeitos localizados

**Concluída:** ver [resultado e evidências da E1](e1-resultados.md). Física e renderização permanecem nas etapas E3 e E4.

- Extrair de `Timer1Timer` métodos como `HandleBounds`, `HandlePaddleCollision`, `HandleBrickCollisions`, `LoseLife`, `MoveBall` e `UpdateDebug` ainda no formulário.
- Centralizar `StartNewGame`, lançamento e pausa, removendo fluxos diferentes entre clique, espaço e F3.
- Remover `ProcessMessages`, corrigir `StrZero`, inicializar a aleatoriedade uma vez, tratar a saída imediata na perda de vida e eliminar nomes de direção ambíguos.
- Padronizar as chaves do diagnóstico e definir ownership/liberação de `Language` durante a transição.
- Remover declarações sem uso e código morto, preservando temporariamente a representação visual atual dos blocos.

**Saída:** jogo com organização legível e correções verificadas, ainda sem a migração gráfica. Validar reinícios repetidos, pontuação grande e pausa por todos os caminhos de entrada.

### Etapa 2 — Extrair o motor e os estados

**Concluída:** ver [resultado e evidências da E2](e2-resultados.md). Foram aprovados 46 casos do motor em Win32/Win64 e 52 casos de integração em Win32. O console também está integrado ao grupo da IDE.

- Criar `TGame`, os registros das entidades e a configuração. Usar uma coleção de blocos com IDs estáveis e flag ativo; a VCL passa a refletir os dados.
- Introduzir os estados e comandos da seção 4; estado completo após cada passo deve ser consultável pelo diagnóstico.
- Manter um adaptador temporário que sincroniza os controles atuais a partir do motor, sem regras de colisão ou pontuação na sincronização.
- Introduzir semente explícita e rotina de geração de fase; separar a aleatoriedade de efeitos daquela usada pelo jogo.
- Criar testes dos estados, vidas, pontos, reinício e geração de fase. Preferir DUnitX se disponível na instalação; verificar a disponibilidade antes de adicionar dependências. O RAD Studio documenta integração e runner de console. [Documentação oficial](https://docwiki.embarcadero.com/RADStudio/Florence/en/DUnitX_Overview).
- Desacoplar os textos e remover `TLanguage`/`DM` quando não forem mais usados.

**Saída:** regras executáveis sem controles visuais; a janela encaminha entrada e apresenta o resultado. O jogo permanece testável pela IDE.

### Etapa 3 — Corrigir o tempo e a física

- Introduzir passo fixo, relógio medido, acumulador e velocidades por segundo.
- Extrair as funções geométricas e implementar resolução pelo primeiro impacto, incluindo cantos, contatos simultâneos e tempo restante.
- Reproduzir e corrigir o caso relatado de destruir um bloco pelo lado sem ricochete horizontal. Cobrir as faces esquerda e direita com aproximações subindo e descendo; distinguir contatos de face dos de canto.
- Implementar resposta contínua da raquete e limite inferior de perda de vida.
- Acrescentar testes determinísticos para as colisões e para diferentes agendas de atualização do mesmo tempo simulado.
- Validar o adaptador visual existente antes de trocar a renderização, separando defeitos de mecânica dos de desenho.

**Saída:** comportamento estável em diferentes cadências, com testes de colisão, ausência de pontuação duplicada e uma única vida perdida por queda.

### Etapa 4 — Compor e desenhar o quadro

- Adicionar superfície única, buffer persistente e cache de recursos; retirar os `TImage` de cada entidade depois de conferir equivalência visual.
- Integrar pintura, transformação de coordenadas, HUD e mensagens; retirar o adaptador temporário.
- Preservar os sprites, corrigir alinhamento e testar DPI. Adicionar interpolação apenas se a avaliação de movimento justificar.
- Medir simulação e desenho separadamente, além dos intervalos entre pinturas; atualizar o diagnóstico em torno de 5 vezes por segundo enquanto aberto, sem limitar a física.

**Saída:** movimento visualmente mais fluido, repintura correta e nenhuma criação/destruição de controles durante a partida.

### Etapa 5 — Completar a progressão e o feedback

- Preservar o gerador atual como primeira fase e acrescentar duas fases pequenas definidas por dados, com distribuição compreensível.
- Implementar `LevelComplete` e `Victory`; carregar a próxima fase somente por transição explícita.
- Propor aumento inicial de velocidade de 5% por fase, limitado pela configuração e revisado após jogar. Pontos e vidas continuam entre fases; F2 restaura tudo.
- Adicionar feedback visual limitado e mensagens claras de pronto, pausa, fim de jogo e vitória.
- Considerar teclado com setas/A/D como melhoria posterior, usando o mesmo comando de movimento do mouse e uma política definida para entradas simultâneas.

**Saída:** ciclo completo de partida, de início até derrota ou vitória, sem acrescentar complexidade desnecessária ao motor.

### Etapa 6 — Consolidar projeto e documentação

- Separar saídas, por exemplo `build/Win32/Debug` e `build/Win64/Release`, e DCUs por plataforma/configuração, evitando mistura entre compilações.
- Revisar os imports duplicados e configurações antigas do `.dproj` com um build antes/depois; preservar recursos necessários como `.res` e ícone.
- Manter fontes novos em UTF-8 e evitar alterações de encoding/terminadores em massa nos legados.
- Atualizar o README com comandos e estrutura efetivamente implementados, incorporando as alterações locais existentes.
- Executar builds limpos Debug/Release em Win32/Win64, testes do motor e a matriz manual. Registrar a configuração e as medições finais.

**Saída:** projeto fácil de abrir, compilar, testar e compreender em outra instalação compatível.

## 7. Validação de cada entrega

Testes automatizados devem cobrir regras e geometria, não reproduzir detalhes internos de handlers ou testar mecanicamente cada renomeação.

| Área | Casos mínimos e resultado esperado |
| --- | --- |
| Estados | Pronto → jogando → pausado → jogando; clique/espaço não reiniciam durante pausa; F2 funciona em todos os estados; F1 respeita diagnóstico e pausa. |
| Vidas | Uma queda desconta exatamente uma vida; zero vidas impede lançamento; nenhuma movimentação extra acontece após reposicionar. |
| Pontuação | Cada bloco pontua uma vez; F2 zera; formatação de 0, 42, 999999999 e 1000000000 não duplica nem trunca dígitos. |
| Paredes | Contatos laterais e superiores mantêm a bola dentro da área e refletem o componente correto. |
| Blocos | Bola descendo contra a face superior deve sair subindo; bola subindo contra a inferior deve sair descendo. Em contato isolado com a face esquerda, a bola que vai para a direita deve sair para a esquerda; na face direita, o inverso. Repetir esses dois casos com a bola subindo e descendo: inverter somente a velocidade horizontal, preservar a vertical e destruir/pontuar o bloco uma vez. Esses casos devem reproduzir e impedir o defeito relatado de destruir o bloco sem ricochete lateral. Cobrir também cantos, emendas e alta velocidade, sem travamento por sobreposição nem colisão com bloco inativo. |
| Raquete | Extremos, centro e posições intermediárias devem produzir ângulos proporcionais ao impacto, com velocidade total constante para a dificuldade definida; extremos simétricos produzem saídas espelhadas. Cobrir bola já abaixo da raquete e bola subindo, evitando reflexão indevida. |
| Tempo | Com mesma semente e entradas por passo, agendas de 30, 60 e 144 acionamentos por segundo produzem o mesmo estado para o mesmo número de passos; atraso acima do limite segue a política de descarte. |
| Fases | Mesma semente gera mesma fase; último bloco aciona conclusão uma vez; progressão preserva vidas/pontos; última fase leva à vitória. |
| Recursos | Repetir F2 e abrir/fechar diagnóstico não produz crescimento contínuo de objetos/handles; fechamento libera motor e recursos gráficos. |

Para testes temporais, injetar o tempo decorrido no controlador do loop, sem depender do relógio real. Para regras, chamar `Step` com passo e entrada conhecidos. Para ponto flutuante, comparar com tolerância definida. A reprodução exige semente, configuração e sequência de entradas, não somente a semente.

Roteiro manual no Delphi 13:

1. Abrir `DelphiBlocks.groupproj` ou `Breakout.dproj`, selecionar Win32/Debug, executar Build e rodar.
2. Mover a raquete até os extremos, lançar por clique e espaço e confirmar a posição inicial da bola.
3. Pausar por F3, testar clique/espaço, retomar por F3, alternar para outro aplicativo e verificar a pausa por perda de foco.
4. Perder as três vidas, tentar lançar após game over, reiniciar por F2 e repetir reinícios durante movimento e pausa.
5. Abrir F10, pausar e usar F1 para inspecionar um impacto por vez; mudar a janela de posição e conferir que isso não altera a física.
6. Usar um cenário de diagnóstico com poucos blocos para testar conclusão de fase e vitória, sem precisar limpar a grade inteira manualmente.
7. Minimizar/restaurar e cobrir/descobrir a janela em jogo e em pausa; verificar repintura e ausência de saltos na retomada.
8. Conferir escalas de DPI e, quando houver mais de um monitor, arrastar a janela entre eles; conferir correspondência entre cursor e raquete.
9. Rodar uma partida de pelo menos 10 minutos com e sem diagnóstico; registrar fluidez, uso de CPU, memória e contagem de recursos.
10. Repetir o roteiro essencial em Win64 e em Release, distinguindo erros de configuração daqueles de comportamento.

Metas iniciais de desempenho: aproximar a pintura de 60 quadros/s na máquina de referência, medir o percentil 95 do custo combinado de simulação/desenho com objetivo abaixo de 16,7 ms e eliminar pausas visíveis associadas a colisões e descarte de controles. Cadência real entre pinturas e tempo gasto no processamento são métricas diferentes; ambas devem ser registradas. Esses valores são metas a validar, não resultados já obtidos nem garantia de sincronização com o monitor.

## 8. Critérios de conclusão e ordem recomendada

A entrega principal corresponde às etapas 0 a 4: código organizado, motor separado, física previsível e renderização fluida. As etapas 5 e 6 completam a experiência e consolidam a distribuição.

- O evento de timer coordena medição, passos e invalidação; não contém regras de colisão nem varredura de componentes.
- Estado do jogo e geometria não dependem de `TImage`, `TPanel`, labels ou posição da janela.
- Há uma única regra para cada comando e transição, com testes dos casos críticos.
- A bola não atravessa blocos ou raquete nos cenários testados, não pontua repetidamente um bloco e perde uma vida por queda.
- A pintura não altera regras; pausa, foco, DPI e repintura funcionam nos cenários previstos.
- A apresentação preserva os recursos gráficos existentes, com melhorias de fluidez demonstradas por comparação e medição.
- Builds e testes passam nas configurações declaradas, com evidência registrada e sem sobrescrever alterações locais do usuário.

Com E0, E1 e E2 concluídas, prosseguir pela E3. A migração para canvas deve acontecer depois que estados e física tiverem limites claros, para permitir identificar a origem de qualquer regressão. Os parâmetros de velocidade, ângulo, cadência e dificuldade são pontos de ajuste durante os testes de jogabilidade.
