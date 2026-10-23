# Sprites incorporados

Os seis streams em `provenance.json` foram extraídos, byte a byte, do `UMain.dfm` da revisão `2611ded`. Os BMPs removem apenas o invólucro de propriedade `TPicture` da VCL; a imagem não foi redesenhada. `Bricks.imagelist` conserva o atlas e a máscara originais do `TImageList`.

`Breakout.Sprites.res` é versionado para compilar um clone sem arquivos externos em tempo de execução. O renderer carrega esses recursos uma vez e prepara alfa a partir da transparência preta original. Para reconstruir o recurso após alterar um sprite, execute dentro desta pasta, com `brcc32` do Delphi no PATH:

```powershell
brcc32.exe -fo Breakout.Sprites.res Breakout.Sprites.rc
```

A raquete mantém os três BMPs: 7×15, 36×15 e 7×15. A largura fornecida por `TPaddle` estende apenas o centro com linhas horizontais; as extremidades mantêm a proporção. O teste de largura 100 compara os pixels das pontas com os da largura original 50 e verifica cada coluna do centro.
