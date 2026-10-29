# Vitrine City — reforma visual das lojas (v0.8)

## Problema observado no primeiro teste humano
As lojas originais eram galpões abertos de blocos e não pareciam pontos comerciais. O jogador viu a Rua Livre no Studio e pediu fachadas comerciais reconhecíveis. A prioridade desta etapa é legibilidade e identidade de loja, não apenas mais detalhes decorativos.

## Mudanças implementadas
- Cada uma das oito lojas mantém sua posição, ID, áreas de estoque e aluguel.
- Fachada completa com **vitrines de vidro**, porta central atravessável, molduras de metal, toldo, letreiro grande e indicador visual de loja aberta/disponível.
- Oito paletas/nomes de fachada. O letreiro muda do texto de disponibilidade para a identificação do proprietário ao alugar.
- Cenografia de vitrine, com **manequim e exposição de amostras**. Esses itens são apenas decoração, não contam como estoque vendável.
- Piso, paredes, cobertura, balcão de atendimento com caixa registradora, tapete, cartaz e gôndolas com etiquetas de preço.
- As seis mercadorias ficam nas laterais em racks de dois níveis; **o corredor central permanece livre** para a entrada e circulação de jogadores e NPCs.
- Rua com asfalto, faixa de pedestres, calçadas contínuas, guias, canteiros com árvores, postes estáticos e sinalização de entrada.
- Objetos cenográficos são Parts simples/ancoradas e materiais nativos. Não dependemos de modelos da Toolbox, downloads, iluminação dinâmica ou texturas externas.

## Segurança funcional
`StoreVisuals.luau` separa cenografia de regras econômicas. `VitrineServer.server.luau` continua autoritativo sobre aluguel, compras, posse, remessas, salário e vendas. A gôndola mostra quantidade real da prateleira e etiqueta dinâmica do preço. Os NPCs ainda atravessam a porta central não-colisível.

A mudança NÃO altera custos, saldo, probabilidade de compra, número de moradores virtuais ou o limite de NPCs simultâneos.

## Validação necessária no Roblox Studio
1. Baixar a compilação **posterior** ao redesenho visual na aba Actions do GitHub, artefato `VitrineCity-Places`.
2. Extrair `VitrineCity-RuaLivre.rbxlx`, abrir com Arquivo → Abrir do arquivo, clicar em Play.
3. Confirmar: aparecem 8 fachadas com letreiros, portas e vitrines; rua e árvores; personagem nasce em local transitável.
4. Chegar à placa amarela e apertar `E` para alugar. Verificar que o letreiro muda para o proprietário.
5. Abrir o painel e comprar 5 produtos, repor a prateleira, ajustar preço. A etiqueta física deve acompanhar a mudança e os produtos aparecerem no rack.
6. Observar cliente NPC atravessando a porta e tentar vender. Validar Output sem mensagem vermelha.
7. Caminhar entre prateleiras e balcão e testar câmera no interior.
8. Testar versão Android, medindo FPS e se telhados, vitrines e etiqueta de preços ficam legíveis na tela pequena.
9. No modo Guerra Comercial e Guerra de Preços, verificar mesmo visual e diferenças de economia.

## Ainda não validado
- A compilação CI de Luau/Rojo não executa o jogo nem renderiza as vitrines; verificar visualmente no Studio.
- A aparência low-poly é um primeiro redesenho, não arte final. Talvez sejam necessárias melhorias de iluminação, materiais, escala e câmera após screenshots reais do Studio.
- Alguns objetos cenográficos não possuem animações nem interações de personalização.
