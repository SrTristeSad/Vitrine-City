# Roteiro de testes — pendente de execução no Studio

## Preparação
Instalar Roblox Studio e Rojo 7 no computador; \`rojo build default.project.json -o VitrineCity.rbxlx\`; abrir o .rbxlx e dar Play. Confirmar Output sem erros. O pacote foi escrito e revisado estaticamente, **não executado no Roblox Studio**.

## Rua Livre
1. Spawn na rua; oito lojas aparecem com placas e prompts.
2. Pressionar E numa entrada próxima -> pagar $100 e tornar-se dono.
3. Segunda tentativa de aluguel deve ser rejeitada.
4. Comprar cinco queijos -> depósito +5, caixa -custo, prateleira inalterada.
5. Repor -> prateleira +5, depósito -5; vender reduz estoque e carteira do morador.
6. Alterar preço +/- -> atualizar placa e afetar comportamento dos consumidores.
7. Contratar funcionário -> selecionar morador desempregado e descontar custo; salário entra na carteira do repositor a cada ciclo.
8. Aguarde dias econômicos -> salários externos, despesas familiares, aluguel e possível falência.
9. Confirmar que não existe DataStore nesta fase: ao reconectar a loja recomeça.

## Competitivo
Trocar \`Mode\` em Config para \`ranked\` e testar servidor com 2 a 8 clientes.
1. Duas lojas vendendo queijo: um consumidor compra em apenas uma.
2. Confirmar estoque compartilhado do fornecedor e remessas.
3. Testar contratos com prêmio 0/20/40, prioridade, entrega parcial e cancelamento.
4. Gastar o dinheiro e confirmar falência após dois vencimentos sem pagamento.
5. Esperar 15 minutos e verificar classificação e novo round.

## Guerra de Preços
Usar \`Mode = "price_war"\`. Confirmar bloqueio de aluguel para falidos, último sobrevivente depois de período de entrada e encerramento por tempo.

## Segurança
Simular payloads remotos inválidos, repetição rápida, troca de dono durante trajeto de NPC e encerramento de rodada durante uma venda. Nenhuma movimentação de dinheiro ou estoque pode ficar negativa ou duplicada. Testar em celular com viewport estreito e Performance Stats para avaliar CPU, rede e FPS.

## Critérios de aceitação
Sem erro de runtime no Output, aluguel e gestão funcionais com dois jogadores, pagamentos e contratos contábeis coerentes, UI sem cortes graves no Android e limite de NPCs respeitado.
