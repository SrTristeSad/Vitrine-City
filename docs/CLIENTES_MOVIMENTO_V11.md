# Vitrine City — movimento de clientes e caixa (v1.1 Preview)

## Problema tratado
No protótipo, o NPC usava uma interpolação de CFrame entre pontos do percurso, mas sem movimento dos braços e pernas e com a rotação sendo interpolada ao mesmo tempo que a translação. Isso dava a impressão de deslizamento, especialmente ao entrar pela porta da loja.

## Mudanças de código
- **Orientação antes do passo:** o NPC vira para o destino antes de iniciar cada deslocamento.
- **Movimentação contínua:** mantém o TweenService com CFrameValue e Model:PivotTo; não teletransporta diretamente os personagens de um waypoint ao próximo.
- **Marcha leve:** braços e pernas oscilam conforme a distância percorrida. O movimento decorativo dos membros é limitado a aproximadamente **12,5 atualizações/s por NPC**, sem acrescentar um loop de Heartbeat por personagem.
- **Caminhos preservados:** calçada → entrada → gôndola → caixa → saída. O percurso de cada lote continua definido por CustomerRoute, preservando a conferência de vendas ao chegar ao caixa.
- **Indicador de venda no caixa:** cada loja possui **um único BillboardGui reutilizável** no registrador, que mostra o valor recebido. Compras posteriores atualizam o mesmo elemento; após 2,5 segundos ele desaparece.
- **Estado atualizado na hora da venda:** o proprietário recebe imediatamente novo saldo, conversão e últimas vendas, sem aguardar o próximo broadcast periódico.
- **Proteção ao trocar de dono:** o indicador do caixa é zerado em resetLot e o número de sequência impede um atraso anterior de apagar uma venda nova.

## Arquivos
- `src/ReplicatedStorage/Shared/CustomerMotion.luau`: matemática pura da distância, interpolação e oscilação de passos.
- `src/ServerScriptService/VitrineServer.server.luau`: pose do NPC, orientação, feedback de caixa e sincronização imediata.
- `tests/customer_motion.spec.luau`: distância euclidiana, destino e limite das oscilações.
- `tests/check_project.py`: integração de módulo nos Places e verificação de guardas de interface.
- GitHub Actions compila os quatro Places e executa testes Luau.

## Não alterado
Economia, aluguel, orçamento familiar, número de moradores simulados, limite de NPCs, sistema de salvamento e regras de competição. As animações não autorizam venda; as transações continuam validadas pelo servidor.

## O que testar no Roblox Studio
1. Abrir o artefato `VitrineCity-RuaLivre.rbxlx` mais recente.
2. Alugar loja, comprar mercadorias, abastecer.
3. Observar o cliente andando da calçada à gôndola, ao caixa e à saída. Confirmar que **se desloca continuamente** e vira sem atravessar paredes.
4. Verificar braços/pernas, especialmente ao mudar de direção; conferir o comportamento parado na gôndola.
5. Após compra real, confirmar o valor `+$N` acima do caixa e atualização instantânea no painel.
6. Confirmar que cliente sem compra **não** mostra valor de venda.
7. Fazer duas vendas em sequência e verificar que o indicador não some antes da segunda.
8. Testar dispositivo Android: FPS, CPU e rede (abrir Performance Stats). Caso o custo fique alto, reduzir frequência de pose ou migrar animação de membros para o cliente.
9. Conferir Output sem erros. A compilação Rojo/Luau valida o código, **mas não é teste de animação visual**.

## Limitação conhecida
Os clientes seguem caminhos geométricos fixos, não IA dinâmica de obstáculos; se móveis forem reposicionados no futuro, será preciso recalcular o percurso. O corpo ainda é low-poly e as animações são procedurais simples, não são rigs humanoides completos.
