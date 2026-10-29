# Vitrine City — clientes percorrendo lojas e caixa interativo (v0.9)

## O que mudou
Antes os clientes iam diretamente a um único ponto dentro do imóvel, e uma compra surgia sem passagem visível pelo caixa. Agora os NPCs passam por uma sequência simples de pontos que respeitam o interior das lojas nos dois lados da rua:

1. Caminhar pela calçada em direção ao estabelecimento.
2. Passar pela porta central de vidro sem colisão.
3. Seguir pelo corredor interno até a gôndola da categoria desejada.
4. Observar o produto por alguns instantes.
5. Retornar ao corredor central e se dirigir ao caixa registrador.
6. **Somente no caixa**: o servidor valida dono da loja, rodada, preço, orçamento do morador e estoque disponível.
7. Após sucesso, exibir sacola e nome do item comprado; caso contrário, indicar que não encontrou o produto.
8. Retornar pela porta e continuar pela calçada antes de desaparecer.

As rotas são coordenadas leves em `CustomerRoute.luau`. Não adicionam PathfindingService por cliente, novas famílias físicas, física de colisão, consultas externas ou NPCs permanentes. Os NPCs agora incluem braços e cabelo e viram-se na direção do deslocamento.

## Caixa interativo
- Após o aluguel, a caixa registradora recebe o prompt **Administrar loja (E)**.
- O servidor verifica se quem ativou o prompt é o proprietário e se está perto da caixa.
- O servidor envia `OpenShop` somente ao dono; o cliente abre a aba de estoque e mantém o botão **MINHA LOJA**.
- Outros usuários não conseguem administrar a loja pelo caixa.
- O prompt fica desativado quando a loja está disponível para alugar.
- O cliente continua sem poder informar quantidade de dinheiro nem executar vendas diretamente.

## Controles e otimização
- O número máximo de clientes visíveis continua definido por `MaxVisibleCustomers`, com valor inicial 12.
- O movimento usa interpolação de `CFrameValue` e `Model:PivotTo`; o percurso é uma lista curta, sem cálculo contínuo de caminho.
- Um morador virtual não pode iniciar duas compras simultâneas: `busy` é liberado em sucesso, falha ou saída.
- Uma visita que perder dono/rodada durante a caminhada não credita venda nem relatórios para o novo proprietário.
- O módulo geométrico é testado no interpretador Luau com `tests/customer_route.spec.luau`, verificando os seis itens e os dois lados da rua.

## Teste prático no Studio — pendente
1. Abrir a nova compilação `VitrineCity-RuaLivre.rbxlx` no Studio e pressionar Play.
2. Alugar um ponto comercial pelo prompt externo.
3. Caminhar até o balcão e pressionar **E** na caixa registradora. O inventário deve aparecer.
4. Comprar cinco unidades de queijo e usar **Repor** para colocá-las na gôndola.
5. Verificar se um NPC entra pela porta, olha a gôndola, vai ao caixa e só então sai com uma sacola se comprar.
6. Confirmar que a prateleira diminuiu, o saldo da loja aumentou e a carteira do cliente foi debitada.
7. Observar um cliente sem produto disponível: ele deve passar pela loja sem sacola e gerar uma visita perdida.
8. Testar duas lojas opostas (uma em cada lado da rua), especialmente o trajeto da entrada e saída.
9. Conferir a saída **Output**: sem mensagens vermelhas; medir FPS e memória no Android, evitando excesso de clientes.
10. Testar que um segundo jogador não pode abrir o inventário do primeiro pelo caixa.

## Limites
- Os modelos dos clientes continuam low-poly e sem animação de pernas; esta versão melhora posicionamento e orientação, mas **não equivale a navegação natural com rig humanoide completo**.
- O movimento ainda depende de caminhos fixos e pressupõe que as gôndolas e balcão permaneçam na posição atual. Se futuramente houver reposicionamento livre de móveis, será necessário recalcular as rotas ou introduzir navegação local.
- O interpretador Luau e o Rojo não executam um Roblox Studio com física, câmera e rede. **O comportamento visual e o multiplayer ainda precisam ser confirmados por playtest real.**
