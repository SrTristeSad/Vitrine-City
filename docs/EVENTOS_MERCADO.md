# Eventos econômicos e vida comercial — v0.6

## Objetivo
Ensinar economia pela consequência das decisões. O jogador não recebe uma aula: ele percebe que o custo e a disponibilidade de mercadorias e a procura dos consumidores mudam com acontecimentos da cidade.

## Funcionamento
O servidor guarda somente o evento atual como dados. A cada **2 dias econômicos** (configuração `MarketEventEveryDays`, um dia = 90 s na versão atual), sorteia outro evento sem repetir o anterior imediatamente. Não há novas famílias físicas, rotas de trabalho, IA generativa ou população extra.

O evento altera duas coisas:
- **Demanda**: pesos relativos por categoria ao sortearem necessidades dos moradores. Uma feira de moda aumenta as chances de alguém sair para comprar roupa, mas não obriga a compra se o preço estiver acima do orçamento.
- **Oferta**: unidades adicionadas ao atacadista em cada remessa, somente nos modos competitivos. O modo normal mantém o atacado ilimitado para preservar sua experiência casual.

## Notícias disponíveis

| Evento | Efeito de demanda | Efeito na entrega |
|---|---|---|
| Dia comum | Sem alteração | Sem alteração |
| Leite em falta | Queijo: x1,25 | Queijo: x0,45 |
| Festival da moda | Roupas: x1,80 | Sem alteração |
| Safra abundante | Arroz: x1,10 | Arroz: x1,80 |
| Manhã na padaria | Pão: x1,65 | Sem alteração |

Os números são parâmetros de gameplay, não previsões de economia real. O jogador precisa decidir se deve estocar, ajustar preços ou trocar o foco comercial. Os eventos são iguais para todos os comerciantes no servidor da partida, sem vantagens pagas.

## Como aparece para jogadores
- Jornal físico na rua mostra o nome do evento.
- HUD mostra notícia e descrição.
- Clientes possuem a categoria desejada visível sobre a cabeça e, após uma compra validada pelo servidor, saem com sacola e nome do produto comprado.
- Cada prateleira usa três peças geométricas simples para representar mercadoria em vez de uma caixa gigante. Atualizações de quantidade apenas alteram transparência; não criam novos objetos a cada venda.

## Otimização
- O sistema de demanda executa somente quando nasce uma oportunidade de compra; nenhum loop por morador por frame.
- Remessas são recalculadas apenas em ciclos de fornecimento.
- O HUD usa assinatura do inventário, evitando destruir e recriar cartões a cada atualização de estado sem alterações de produtos, loja ou ranking.
- Árvores e postes são estáticos e os postes não têm luz dinâmica.
- Continua obrigatório medir FPS, rede e memória no Roblox Studio e em Android real.

## Testes pendentes
- [ ] Verificar que cada evento altera a distribuição de categorias conforme os multiplicadores.
- [ ] Verificar que a queda de oferta de queijo afeta apenas as remessas futuras e não retira mercadorias das lojas.
- [ ] Confirmar que o modo normal mantém fornecedores ilimitados.
- [ ] Confirmar que a compra de um NPC só ocorre com dinheiro, produto em prateleira e preço correspondente; sem compra, não aparece sacola.
- [ ] Verificar leitores de tela e cortes da notícia em celulares pequenos.
- [ ] Medir atualizações de UI e quantidade de Parts / BillboardGuis após vários dias econômicos.
- [ ] Testar competição real entre duas lojas com produtos substitutos.

## Arquivos
`src/ReplicatedStorage/Shared/MarketEvents.luau`, `Economy.luau`, `Population.luau`, `Config.luau`, `VitrineServer.server.luau` e `VitrineClient.client.luau`.

> Compilação Luau/Rojo não é teste funcional: comportamento, balanceamento, layout e desempenho ainda precisam ser validados dentro do Roblox Studio e em servidores publicados.
