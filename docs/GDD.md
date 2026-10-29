# Vitrine City — GDD v0.2 (29/10/2026)

## Fantasia de jogo
Começar numa pequena loja de rua e aprender a operar um negócio. Os jogadores disputam a atenção dos NPCs; as consequências das decisões explicam economia de forma orgânica, não por palestras ou caixas de tutorial.

## Loop principal
Alugar ponto -> comprar estoque -> colocar na prateleira -> definir preço -> observar cliente -> receber venda -> pagar contas -> expandir / ajustar mix de produtos.

## Modo normal — Rua Livre
- Sem concorrência real pela mesma compra: consumidor procura primeiro um estabelecimento sorteado.
- Atacado ilimitado, ritmo casual, fechamento com possibilidade de recomeço.
- Na experiência publicada: DataStore mantém caixa, despesas, vendas, preços e estoque; após reconexão, o jogador escolhe um novo ponto e recupera o inventário sem pagar segunda taxa de abertura. Em Studio o progresso é temporário por padrão.

## Modo ranqueado — Guerra Comercial
- NPC único compara ofertas de todas as lojas ativas do servidor.
- Ofertas consideram preços, preferência de marca, reputação e distância.
- Estoque compartilhado dos fornecedores e entregas periódicas.
- Contratos pré-pagos com prêmio de 0, 20, 40% que dão prioridade na remessa.
- Fim por tempo: patrimônio líquido = caixa + estoque ao custo + valor reservado em contratos - penalidades.
- Ainda sem matchmaking nem proteção contra entrada tardia.

## Modo Guerra de Preços
- Mesma competição de consumidores e fornecedores do ranqueado.
- Se uma loja ficar dois ciclos sem pagar contas, ela fecha e o jogador é eliminado.
- Com pelo menos dois participantes e após período de entrada, se só uma empresa sobreviver a rodada termina. Limite de tempo aplica critério de sobrevivência e patrimônio.
- Este modo já tem regra básica, mas falta balanceamento e teste com múltiplos clientes.

## Clientes e economia
- Há 240 moradores como dados (configurável), cada um com profissão, renda, tamanho de família e carteira.
- Cada cliente recebe uma necessidade, categoria, marca preferida e tolerância a preço.
- O dinheiro da compra sai da carteira do morador e entra na loja. Sem saldo suficiente não existe transação.
- Despesas e salário são atualizados em períodos econômicos, não a cada frame.
- Quando a loja contrata um repositor, um morador desempregado ganha o emprego e recebe os salários cobrados do proprietário. Em falência/desligamento o morador volta ao desemprego.
- Só até 12 clientes ganham avatar 3D na rua simultaneamente. O limite é configurável e depende dos resultados em dispositivos reais.

## Itens, administração e falência
- Catálogo inicial: dois queijos, duas camisetas, pão e arroz.
- Compra em lotes de cinco, reposição de dez por clique ou por funcionário.
- Prateleira tem limite de 18 unidades por item.
- Contabilidade reconhece estoque como ativo histórico e custo de mercadoria vendida na venda.
- Contas: aluguel e folha salarial por ciclo; dois atrasos fecham a loja.
- O aluguel inicial é cobrado na primeira locação; não é cobrado uma segunda vez ao restaurar uma loja. Saldo e inventário persistem somente na Rua Livre publicada com DataStore acessível.

## Segurança e limites
Servidor valida eventos, preço, estoque, dinheiro, posse da loja, quantidade e proposta de contratos. O cliente não envia valor final de caixa nem venda. NPCs são modelos geométricos simples, sem família física, casa, jornada de trabalho ou IA generativa. O protótipo **não foi testado em Roblox Studio**.

## Próximas entregas
1. Playtest técnico Studio e mobile; telemetria de desempenho.
2. Testar persistência, falhas de rede e reconexão real; implementar recuperação de sessões travadas com observabilidade.
3. Lobby e Places separados; matchmaking e isolamento de partidas.
4. Negociação direta entre comerciantes com escrow bilateral seguro.
5. Vitrines personalizadas, decoração, expansão de imóveis, identidade visual.
6. Sazonalidade, choque de oferta, empregos e produção, painel de mercado.
7. Cosméticos e monetização após avaliação de segurança, experiência e retenção.
