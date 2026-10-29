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

## Estrutura
- `src/ReplicatedStorage/Shared`: Config, Catalog, Economy, Population.
- `src/ServerScriptService`: servidor e mundo.
- `src/StarterPlayer/StarterPlayerScripts`: cliente HUD.
- `docs`: GDD, economia, monetização, testes.

## Próximo trabalho
Prioridade: executar e testar no Roblox Studio; corrigir erros reais do Output; validar DataStore em ambiente de teste publicado e só então criar lobby, matchmaking e teleporte para Places distintos. Persistência da Rua Livre já implementada, mas ainda sem playtest em produção. Não adicionar seis modos superficiais antes de estabilizar o principal.

## Padrão de entrega
Em cada alteração: resumo do comportamento, arquivos alterados, testes efetivamente rodados e limitações. Proteger eventos remotos contra dados falsificados e compras duplicadas. Documentar qualquer mudança de configuração econômica em `docs/ECONOMIA.md`.
