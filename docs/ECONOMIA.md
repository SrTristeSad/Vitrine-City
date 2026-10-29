# Especificação econômica inicial

## Unidade monetária
Dinheiro **fictício do jogo**, independente de Robux. O cliente não controla nenhum saldo.

## Consumidores
Os habitantes existem como tabelas em servidor. O morador possui carteira, profissão, renda por ciclo e tamanho de família. Uma tentativa de compra ocupa um morador por vez (\`busy\`) para que ele não compre simultaneamente em lojas diferentes.

\`CustomerDirector\` simplificado: consumidor aleatório solvente -> demanda por categoria e marca -> orçamento até 65% da carteira -> seleção de oferta -> visita visual -> confirmação server-side. Se a loja vende, o orçamento do cliente é debitado uma única vez.

Profissões de base: professor, enfermeiro, motorista, cozinheiro, técnico, escriturário e desempregado. Repositor contratado sai do desemprego, recebe salário do comércio e é demitido quando o estabelecimento fecha.

## Modelo de oferta
Modo normal: NPC escolhe uma loja antes de ver seus itens. Não redireciona automaticamente para concorrentes.
Modo competitivo: lojas com estoque em prateleira e preço acessível disputam a mesma visita, usando marca, preço relativo, reputação, distância e variação leve.

## Atacado
Normal: compra ilimitada.
Competitivo: estoque real por item, compras deduzem disponibilidade imediatamente. Entregas periódicas abastecem o fornecedor. Contratos usam reserva integral de dinheiro (\`escrow\`), atendem prêmios maiores primeiro e devolvem valores remanescentes em cancelamento.

## Patrimônio
Caixa + valor original do estoque + reservas de contratos - penalidades.
O custo de mercadoria entra em \`costValue\` no recebimento e sai proporcionalmente na venda. Ao fechar a loja, estoque restante é baixado.

## Riscos e balanceamento
Esta versão não modela inflação monetária, compras entre jogadores, impostos, empréstimos ou custo de transporte. A renda dos empregos externos é injetada por ciclo como aproximação da economia maior. O mercado ainda não é um circuito completamente fechado. A demanda não é garantida para cada loja. Ajustar parâmetros somente após observar partidas reais e anotar medidas.
