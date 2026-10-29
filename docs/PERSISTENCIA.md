# Rua Livre — persistência de perfil (v0.2)

## Dados salvos
- Saldo, vendas, despesas, receitas e penalidades.
- Depósito, prateleiras, preços, custo do estoque, reputação, contratação de repositor e estatísticas de visitas/vendas da loja (a partir da v0.7).
- Livro de despesas por categoria (aluguéis, salários, contratação, custo das mercadorias vendidas e baixas de estoque), acrescentado na v0.7. Valores históricos anteriores não podem ser detalhados retroativamente.
- O lote físico não é reservado entre servidores: após reconectar, o jogador escolhe uma loja vaga para recuperar o estoque sem pagar outra taxa inicial.

## Arquitetura
- A persistência usa DataStoreService apenas na Rua Livre publicada, configurada com SaveEnabled = true.
- StudioPersistence = false por padrão, inclusive se o Studio tiver autorização para serviços de API. Não testar a base de produção em Studio.
- Nome do DataStore: VitrineCity_RuaLivre_V1; chaves player_v1_<UserId>; schema 1.
- Carregamento e gravação usam UpdateAsync com lease renovável de 180 segundos. A sessão bloqueia acesso concorrente, prevenindo gravações cruzadas.
- Autosave a cada 45 segundos e liberação do lease ao sair. BindToClose tenta salvar na parada do servidor.
- Falha de carregamento não cria perfil substituto. Se o lock for perdido, as operações são congeladas. Erros de gravação são registrados e comunicados.

## Teste de integração (ainda pendente)
1. Abrir artefato .rbxlx do GitHub Actions no Roblox Studio e testar alugueis, compras, reposição, preços e clientes.
2. Verificar mensagem TESTE LOCAL SEM SALVAR em Studio.
3. Publicar uma **cópia isolada de teste** em outro universo Roblox. Não compartilhar DataStore com produção.
4. Entrar, alugar, comprar e repor mercadorias, sair e entrar novamente. Conferir saldo e restauração em outro lote.
5. Testar desconexão durante salvamento e duas sessões concorrentes do mesmo perfil.
6. Testar falha de acesso ao DataStore: bloquear transações e não sobrescrever dados.
7. Medir número de chamadas e performance em dispositivos Android.

## Limitações
- CI verificou sintaxe Luau, estrutura e build Rojo; **a execução no Roblox Studio e o DataStore real ainda não foram testados**.
- Falhas de rede podem fazer o último intervalo de jogo não gravado se perder.
- Após crash, o lease pode bloquear um novo login por aproximadamente 180 segundos.
- Não há backup automatizado, migração de esquema posterior à versão 1 ou várias lojas por jogador.
- O dinheiro da Rua Livre é separado de todas as partidas competitivas.
