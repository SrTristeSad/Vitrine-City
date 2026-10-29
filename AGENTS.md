# Vitrine City — instruções para Codex

## Objetivo
Jogo Roblox **original** em Luau. Uma rua comercial multiplayer com locação de lojas, estoque, fornecedores e clientes autônomos. Não transformar em idle tycoon de dinheiro automático: cada venda exige um comprador com necessidade, orçamento e mercadoria efetivamente disponível.

## Regras que não podem regredir
1. O servidor é autoridade sobre caixa, estoque, preços, aluguel, salário, pedidos e vendas.
2. No modo normal não existe mercado de fornecedor escasso compartilhado. No ranqueado, NPCs comparam as lojas da mesma partida e fornecedor é finito.
3. População virtual não é a mesma coisa que NPC 3D. Manter registros compactos e colocar poucos avatares na rua; evitar loops por residente a cada frame.
4. Salários e despesas das famílias influenciam o poder de compra. Sem criar dinheiro infinito por NPC a cada compra.
5. A Guerra de Preços elimina jogadores por falência; não vender vantagens com Robux nas partidas competitivas.
6. Simulação, contratos e partidas ficam isolados por servidor. Não usar DataStore como estado de transação em tempo real.
7. Não declarar testes no Studio se não foram executados.
8. Rua Livre salva via ProfileStore e `UpdateAsync` com lease e autosave; não ligar StudioPersistence para jogos publicados.
9. Não sobrescrever dados reais em falha de carregamento nem misturar dados competitivos com perfis persistidos.
10. Cada modo possui projeto Rojo próprio. O servidor determina o modo, nunca confie em argumentos do cliente.
11. Competitivo publicado aceita apenas servidor reservado. O módulo GlobalMatchmaker usa MemoryStore em ambiente publicado; fila local somente no Studio. Não declarar esse modo testado em múltiplos servidores antes de realizar teste real.
12. IDs zero em ModeRoutes desativam teleportes. Nunca inventar PlaceIds.
13. A Rua Livre salva o perfil antes de voltar ao Lobby. Falha de Save cancela teleporte, e falha de teleporte deve liberar o bloqueio de ações.
14. O lobby rejeita nomes de modo não permitidos pelo servidor. Testar retornos reais no cliente Roblox, não apenas em Studio.
15. Claims atômicos, nonce por usuário, ticket com TTL e confirmação de match ready são invariantes importantes do matchmaking global. Não substituir por fila local sem avisar.
16. MemoryStore pode sofrer throttling; documentar vazão e consumo antes de aumentar frequência. Ver docs/MATCHMAKING_GLOBAL.md.
17. Eventos econômicos são modificadores por categoria, não NPCs extras nem alteração de estoque já possuído. Configurar em MarketEvents.luau.
18. Otimizar HUD: não recriar todos os cartões quando o inventário não mudou. Evitar luzes dinâmicas e criação contínua de Parts nos ciclos de clientes.
19. Relatório da loja mede apenas visitas concluídas e validação de vendas no servidor. Uma visita cancelada por troca de dono ou rodada não deve aparecer no histórico do novo proprietário.
20. O painel v0.7 mostra diagnóstico de perda e ledger sem equiparar lucro bruto a lucro líquido. KPIs de lojas salvos devem ser sanitizados. Rodar testes/analytics.spec.luau no CI.
21. O layout visual fica isolado em StoreVisuals.luau. Não confundir itens cenográficos das vitrines com mercadorias vendáveis; gôndolas reagem ao estoque real e etiquetas aos preços.
22. Preservar corredor central e entrada com passagem sem colisão, prompt de aluguel junto à fachada e nomes dos lotes. Ver docs/REFORMA_VISUAL_LOJAS.md.
23. Clientes devem ir de calçada → porta → gôndola → caixa → saída, com percurso definido por CustomerRoute.luau; validar em ambos os lados da rua.
24. Nunca creditar venda por animação; somente `sale()` valida orçamento, estoque e dono quando o NPC chega ao caixa.
25. O prompt físico de gerenciamento na caixa só pode abrir o inventário para o proprietário, validado no servidor. Executar `tests/customer_route.spec.luau` no CI.
26. ShopGuide é apenas leitura da situação comercial. Não entregar dinheiro nem mercadoria ao jogador para completar tutorial.
27. O painel inicia fechado, abre no aluguel e continua acessível pelo botão/caixa. No celular, esconder guia quando o painel estiver visível.
28. Venda bem-sucedida gera confirmação e recibo curto de sessão apenas após a validação server-side em sale(). Rodar `tests/shop_guide.spec.luau` na CI.
29. CustomerMotion implementa matemática de caminhada sem gerar humanoides extras; os membros usam no máximo 12,5 atualizações/s por NPC e retornam à pose neutra nas paradas.
30. O indicador +$ no caixa é um único BillboardGui reutilizável por loja. Cada venda válida atualiza saldo e recibos imediatamente; troca de dono deve ocultar o indicador. Ver `docs/CLIENTES_MOVIMENTO_V11.md`.

## Estrutura
- `src/ReplicatedStorage/Shared`: Config, Catalog, Economy, Population.
- `src/ServerScriptService`: servidor e mundo.
- `src/StarterPlayer/StarterPlayerScripts`: cliente HUD.
- `docs`: GDD, economia, monetização, testes.

## Próximo trabalho
O lobby, os quatro Places e o **matchmaking global beta** já estão codificados. Prioridade: configurar os PlaceIds reais no ModeRoutes, publicar em experiência de teste e validar teleportes no cliente Roblox, além de corrigir erros reais do Studio e verificar DataStore. Depois, validar no Roblox Studio a nova fachada/porta/corredores, aluguel, NPCs, compra/visita e relatório no Android, além do DataStore e matchmaking publicados. Não adicionar seis modos superficiais antes de estabilizar o principal.

## Padrão de entrega
Em cada alteração: resumo do comportamento, arquivos alterados, testes efetivamente rodados e limitações. Proteger eventos remotos contra dados falsificados e compras duplicadas. Documentar qualquer mudança de configuração econômica em `docs/ECONOMIA.md`.
