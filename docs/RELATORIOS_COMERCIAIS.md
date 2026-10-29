# Relatórios comerciais — v0.7

## Objetivo
Ensinar tomada de decisão econômica sem tutoriais repetitivos. O comerciante entende o que procura a clientela da **sua loja**, descobre por que perdeu compras e compara receitas e despesas.

## Como medir
- Uma visita só é registrada quando o NPC **chega à loja ainda pertencente ao proprietário original**, na mesma rodada e na mesma geração de aluguel. Se a loja fechar ou trocar de dono durante a caminhada, a visita é descartada para evitar indicadores de outro jogador.
- Uma venda conta quando o servidor valida dono, produto, preço, prateleira e saldo do consumidor. Não contabilizar compra pela animação nem por comando vindo do cliente.
- A conversão é `compras concluídas / visitas concluídas * 100`. Não é a taxa de conversão de toda a cidade.
- Quando uma visita não termina em compra, o motivo é classificado a partir do **estado real do ponto comercial naquele momento**, não de suposições sobre outro estabelecimento.

## Diagnósticos
| Motivo | Significado |
|---|---|
| Prateleira vazia | A loja não possuía itens expostos da categoria procurada |
| Produto no depósito | Havia mercadoria guardada, mas nenhuma unidade da categoria exposta, ou a oferta selecionada ficou sem prateleira |
| Preço acima do orçamento | Havia produto exposto, mas nenhum item da categoria cabia no orçamento do NPC |
| Oferta alterada durante a visita | O preço do produto selecionado mudou enquanto o cliente caminhava |
| Compra não concluída | Uma oferta aparentemente viável não virou transação; exige investigação em testes |

O mesmo cliente nunca deve gerar uma venda e uma perda simultaneamente. Se o NPC mudar de servidor, a loja fechar ou a rodada terminar antes de ele chegar, não há conversão atribuída à loja.

## Painel
O botão **RELATÓRIO DA LOJA** alterna entre o gerenciamento normal e os indicadores, para evitar um painel com conteúdo excessivo em celulares. Mostra:
- Visitas, compras, perdas e conversão.
- Receita bruta, custo das mercadorias vendidas e lucro bruto.
- Categorias que os clientes visitaram procurando (queijo, pão, roupa, arroz).
- Unidades e faturamento por mercadoria.
- Despesas: aluguel inicial, aluguéis periódicos, salários, contratação, mercadorias vendidas e baixas de estoque.
- Sugestão contextual conforme o principal motivo de compra perdida.

**Importante:** `lucro bruto` só desconta o custo das mercadorias vendidas. O `resultado acumulado` do perfil desconta custos de aluguel, pessoal, compra já reconhecida nas vendas e baixas. Compras ao fornecedor que ainda estão no depósito ou na prateleira são estoque, não despesa integral do período.

## Persistência
Na Rua Livre publicada, as estatísticas da loja são salvas com o inventário e o livro de despesas com o perfil. A versão permanece com o mesmo `schema = 1`: campos opcionais ausentes em perfis antigos começam zerados, e as contagens são normalizadas pelo servidor. As métricas da loja são zeradas em falência/fechamento, mas o livro financeiro acumulado do perfil continua registrando os gastos.

**Não retroativo:** os valores antigos já acumulados em `revenue` e `expenses` permanecem, mas não conseguimos reconstruir as categorias dessas despesas nem as visitas anteriores à v0.7. O painel deve informar isso; não inventar o histórico.

Nas partidas competitivas, os indicadores e despesas reiniciam a cada rodada. Nada é compartilhado entre modos.

## Implementação e segurança
- `ShopAnalytics.luau`: classificação, contagem, sanitização de dados salvos, resumos ordenados.
- `VitrineServer.server.luau`: coleta apenas quando uma compra/visita acontece, sem loop extra por NPC.
- `ProfileStore.luau`: normalização de registros persistentes.
- `VitrineClient.client.luau`: relatório em aba própria, alternado com estoque, sem poder escrever no caixa da loja.
- `tests/analytics.spec.luau`: testes reais em interpretador Luau no GitHub Actions de conversão, causas, vendas, produtos e restauração de dados.
- `tests/check_project.py`: verificações de mapeamento, referências e guardas de posse/rodada.

## Pendências
- [ ] Executar o jogo no Roblox Studio com 2+ jogadores: uma compra e uma perda devem ser registradas uma única vez.
- [ ] Validar troca de proprietário e encerramento de rodada durante caminhada de NPC.
- [ ] Verificar tela Android estreita sem sobreposição de relatório e estoque.
- [ ] Testar DataStore real da Rua Livre após salvar, reconectar e alugar novo ponto.
- [ ] Analisar consistência do custo médio e arredondamento quando houver várias compras em lotes distintos.
- [ ] Comparar visão de dono da loja e ranking competitivo, com partidas reais.
- [ ] Instrumentar logs/telemetria anonimizados para balancear preços, demanda e frequência de visitas, sem dados pessoais.
