# Vitrine City — v1.2 Preview: repositor em atividade e mercadorias identificáveis

## Problema corrigido
Até a v1.1, contratar um funcionário criava seu boneco dentro da loja, mas o estoque mudava sozinho a cada 11 segundos. Isso fazia o NPC parecer uma decoração, embora o jogador estivesse pagando contratação e salários.

## Comportamento implementado
- O repositor aparece próximo ao balcão da loja e aguarda serviço.
- A cada ciclo, o servidor consulta as gôndolas para identificar as que possuem unidades no depósito e espaço livre na prateleira.
- O **WorkerPlanner** escolhe a gôndola com menor estoque exposto. Um serviço movimenta até dez unidades, limitado à mercadoria realmente disponível e à capacidade de cada prateleira.
- O funcionário caminha pelo corredor central até a prateleira selecionada, para por um instante e **só depois transfere as unidades** do depósito à área de venda. Volta então para a região do caixa.
- O boneco leva uma caixa visual de mercadorias durante o percurso. É decoração, não um item de inventário adicional.
- O sistema limita a execução a **um serviço por funcionário por vez**, evitando múltiplas rotas simultâneas mesmo quando a viagem ultrapassar a duração de um ciclo.
- Se houver falência, fechamento, saída da sessão ou troca de proprietário durante o trajeto, a reposição não se completa para o novo dono.
- O HUD identifica **Repositor disponível** ou **Repositor abastecendo...**. O botão de contratar fica inativo quando já existe funcionário.

## Apresentação das mercadorias
As seis mercadorias já existiam economicamente, mas eram exibidas como caixas coloridas. Agora as peças já utilizadas na prateleira recebem formas e materiais por categoria:
- pão: formas arredondadas;
- queijo: pequenas peças cilíndricas;
- roupas e arroz: aparência de tecido;
- embalagens de outros produtos: peças low-poly convencionais.

Essas mudanças não aumentam o número de NPCs ou exigem modelos externos. Objetos cenográficos sem colisão deixam de projetar sombras para reduzir custo gráfico. O estoque e as etiquetas continuam representando os dados reais da loja.

## Economia e segurança
- Não existe bônus de estoque, compra automática ou moeda criada pelo funcionário.
- Contratação e salários não foram alterados.
- A seleção da gôndola é calculada por um módulo puro, mas a movimentação de inventário só acontece no servidor após o deslocamento válido.
- A decisão de trabalho não depende de comando do cliente; o jogador não fornece quantidades ou IDs arbitrários.
- O repositor ocupa uma única vaga de funcionário por loja, sem multiplicar modelos nas viagens.

## Testes automatizados
- `tests/worker_planner.spec.luau`: prioridade da gôndola mais vazia, estoque insuficiente, limite de dez unidades, prateleira cheia e depósito vazio.
- `tests/customer_route.spec.luau`: trajetos do repositor para cada uma das seis gôndolas, de ambos os lados da rua.
- `tests/check_project.py`: verifica referências nos três Places comerciais, controles de execução simultânea e o indicador no HUD.
- O workflow executa os testes, compila os fontes Luau e monta quatro arquivos Roblox.

## Teste manual ainda pendente
1. Abrir a compilação mais recente `VitrineCity-RuaLivre.rbxlx` no Roblox Studio.
2. Alugar uma loja e comprar mercadorias suficientes para abastecer mais de uma gôndola.
3. Contratar repositor; observar se ele começa próximo ao caixa.
4. Confirmar que o funcionário vai até a prateleira **antes** de aumentar a quantidade exposta.
5. Conferir que cada ciclo repõe um produto por vez, sem ultrapassar dez unidades ou capacidade da prateleira.
6. Simular loja sem produtos ou prateleiras cheias: ele deve permanecer aguardando.
7. Verificar a animação do funcionário, o carregamento da caixa, o retorno ao caixa e as atualizações do HUD.
8. Testar fechamento/troca de dono enquanto ele caminha: nenhum estoque poderá ser transferido ao novo proprietário.
9. Verificar o Output e medir FPS no Android real, especialmente quando há oito repositoras simultâneas.

**Limite:** os caminhos são fixos ao layout atual. Se as gôndolas se tornarem móveis, as rotas precisarão ser recalculadas. Nenhum teste de física/câmera dentro do Roblox Studio foi realizado nesta etapa.
