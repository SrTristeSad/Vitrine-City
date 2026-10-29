# Vitrine City — primeira loja e feedback de vendas (v1.0-preview)

## Objetivo
O protótipo precisa ser testável sem o jogador depender de instruções externas. A versão anterior abria um painel grande assim que o usuário entrava, ocupando a rua; após alugar, nem sempre ficava claro o que fazer para o NPC comprar.

## Mudanças implementadas
1. **HUD inicialmente fechado:** o cenário fica visível; botão MINHA LOJA permanece disponível. Após alugar, o servidor envia OpenShop ao proprietário e abre a gestão automaticamente.
2. **Guia contextual discreto:** aparece no canto esquerdo, fora do painel em desktop. Em celulares estreitos, desaparece quando o painel está aberto para não encobrir os controles.
3. **Etapas do guia:** alugar uma loja disponível; comprar pelo menos um lote; colocar no expositor; esperar um cliente; depois analisar relatórios e melhorar o negócio. O guia reage ao estoque e às vendas reais.
4. **Venda confirmada:** quando o servidor valida uma compra, mostra mensagem VENDA REALIZADA com produto e valor recebido.
5. **Recibos das últimas vendas:** a aba RELATÓRIO exibe as cinco vendas mais recentes, com preço e margem bruta estimada da mercadoria. É um histórico **somente da sessão da loja** (não persistido no DataStore). O histórico é esvaziado na falência e no fechamento da loja; o total acumulado das vendas continua no perfil.

## Integridade econômica
- Nenhum passo do tutorial concede moedas, cria estoque ou obriga um NPC a comprar.
- A mensagem de venda é disparada dentro da função de venda validada pelo **servidor**, depois do débito do consumidor e do estoque.
- A margem por recibo é preço menos custo histórico por unidade, sem descontar aluguel/salários. Portanto **não é lucro líquido**.
- Os dados enviados ao cliente são apenas para exibição e não alteram o caixa.
- Evitamos exibir um painel cheio sobre a rua antes do primeiro aluguel.

## Testes automáticos
- `tests/shop_guide.spec.luau`: cobre as cinco etapas do fluxo, estoque esgotado e estoque sem reposição.
- `tests/check_project.py`: garante que guia e confirmações estejam integrados e que o ShopGuide seja incluído nos três Places comerciais.
- O GitHub Actions executa essas verificações, testes de visitas e rotas dos NPCs, compila Luau e gera os quatro Places Roblox.

## Testes reais ainda necessários
1. Abrir a última versão de `VitrineCity-RuaLivre.rbxlx` no Studio; a rua deve aparecer **sem o painel sobreposto**.
2. Conferir o guia: alugar um ponto pelo E e verificar abertura automática do inventário.
3. Comprar cinco unidades e confirmar que o guia pede reposição.
4. Repor a gôndola e confirmar que o guia pede para esperar o cliente.
5. Aguardar uma venda real: mensagem com nome do produto e valor recebido. Depois, guia muda para a etapa de crescimento.
6. Abrir RELATÓRIO: venda aparece na lista das cinco últimas, com margem bruta correta.
7. Fechar o painel no Android: guia não deve encobrir os botões de movimento nem o joystick.
8. Verificar Output sem erros e observar eventuais notificações sobrepostas.
9. Testar que perder uma venda não dispara a mensagem de venda.

**Atenção:** nenhum teste de execução no Roblox Studio foi realizado nesta etapa; o pipeline verifica código e build, não a câmera, a renderização ou a economia de uma sessão real.
