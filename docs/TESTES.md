# Roteiro de testes — pendente de execução no Studio

## Primeira execução em Place não publicado
O arquivo `VitrineCity-RuaLivre.rbxlx` deve abrir em Play mesmo antes de publicar a experiência. Com `StudioPersistence = false`, o `ProfileStore` não deve obter `DataStoreService:GetDataStore` no momento do `require`. O `GetDataStore` é inicializado apenas quando há uma gravação/leitura real de perfil persistente.

Se o Output mostrar `You must publish this place to the web to access DataStore` apontando para `ProfileStore` durante a inicialização, provavelmente foi aberta uma compilação antiga (v0.7 anterior à correção). Baixar novamente o artefato mais recente gerado pela CI após o commit `8b57c9b`. O erro subsequente `VitrineRemotes` aguardando indefinidamente é consequência do servidor não chegar a criar os RemoteEvents.

Cenário de aceitação: abrir `.rbxlx` novo, Play, o mapa é gerado, surgem oito lojas, a interface aparece e o Output não contém o erro de DataStore. Isso ainda precisa de validação real no Studio.


## Preparação
Instalar Roblox Studio e Rojo 7 no computador; `rojo build default.project.json -o VitrineCity.rbxlx`; abrir o .rbxlx e dar Play. Confirmar Output sem erros. O pacote foi escrito e revisado estaticamente, **não executado no Roblox Studio**.

## Rua Livre
1. Spawn na rua; oito lojas aparecem com placas e prompts.
2. Pressionar E numa entrada próxima -> pagar $100 e tornar-se dono.
3. Segunda tentativa de aluguel deve ser rejeitada.
4. Comprar cinco queijos -> depósito +5, caixa -custo, prateleira inalterada.
5. Repor -> prateleira +5, depósito -5; vender reduz estoque e carteira do morador.
6. Alterar preço +/- -> atualizar placa e afetar comportamento dos consumidores.
7. Contratar funcionário -> selecionar morador desempregado e descontar custo; salário entra na carteira do repositor a cada ciclo.
8. Aguarde dias econômicos -> salários externos, despesas familiares, aluguel e possível falência.
9. No Studio com `StudioPersistence=false`, verificar indicador `TESTE LOCAL SEM SALVAR` e perda de progresso ao encerrar.
10. Em jogo de teste publicado com DataStore habilitado, ganhar dinheiro, comprar/estocar, sair e reentrar: saldo e estoque são restaurados após alugar outro ponto **sem pagar novamente** a taxa inicial.
11. Duas sessões simultâneas para o mesmo usuário devem receber bloqueio de lease e não duplicar caixa.
12. Em falha de leitura de DataStore, bloquear operações e não criar perfil substituto; em falha de autosave, exibir alerta. Em perda do lease, impedir compras e cobranças.

## Testes de persistência
Use **experiência de teste separada da produção**, porque a Roblox recomenda não habilitar acesso do Studio aos dados de produção. Testar salvamentos após a janela de 45 s, saída imediata e falha simulada, conferindo o estado entre sessões. Verificar que a trava de sessão expira após falha de servidor (aprox. 180 segundos), sem garantia de recuperação instantânea. Documentar prints/logs do Output.

## Matchmaking global beta
Reunir 2 a 8 jogadores **em lobbies de servidores diferentes** numa experiência de teste publicada, confirmar mesmo GUID de servidor reservado para todos, conferir tickets com prazo de validade, cancelamentos e comportamento após falha de MemoryStore. Validar por logs reais e Dashboard. Roteiro em `docs/MATCHMAKING_GLOBAL.md`.

## Lobby e quatro Places
Ver `docs/MODOS_LOBBY.md`. Abrir os quatro arquivos compilados no Studio, conferir a saída e a interface mobile. Configurar PlaceIds reais em uma experiência de teste com quatro Places; testar no **cliente Roblox** entrada solo na Rua Livre, partidas de 2 a 8 pessoas em servidores reservados, cancelamento, desconexão e falhas de teleporte. O Studio não executa teletransportes.

## Retorno seguro ao lobby
Validar em jogo publicado: botão de confirmação, PlaceId do Lobby, retorno da Rua Livre com save imediatamente anterior à saída, falha de DataStore impedindo o teleporte, falha de teleporte liberando a UI e abandono de partida competitiva sem transferir dinheiro. Conferir `docs/MODOS_LOBBY.md`.

## Relatórios comerciais — v0.7
Executar testes/analytics.spec.luau no CI e verificar em Studio: venda e compra perdida por cliente, conversão correta, categorias procuradas, atualização sem recriar cartões, troca de dono no trajeto, razão de preço fora do orçamento, depósito cheio com prateleira vazia e persistência após reconectar. Documentar evidência em docs/RELATORIOS_COMERCIAIS.md.

## Economia viva e visualização — v0.6
Consultar `docs/EVENTOS_MERCADO.md`. Confirmar notícias atualizadas a cada dois dias econômicos, distribuição da demanda, remessas menores de queijo na escassez, mercadorias não confiscadas, sacola após compra validada, três peças por item e ausência de criação contínua de Parts. Verificar FPS no Android e atualização de interface sem flicker.

## Competitivo
Trocar `Mode` em Config para `ranked` e testar servidor com 2 a 8 clientes.
1. Duas lojas vendendo queijo: um consumidor compra em apenas uma.
2. Confirmar estoque compartilhado do fornecedor e remessas.
3. Testar contratos com prêmio 0/20/40, prioridade, entrega parcial e cancelamento.
4. Gastar o dinheiro e confirmar falência após dois vencimentos sem pagamento.
5. Esperar 15 minutos e verificar classificação e novo round.

## Guerra de Preços
Usar `Mode = "price_war"`. Confirmar bloqueio de aluguel para falidos, último sobrevivente depois de período de entrada e encerramento por tempo.

## Segurança
Simular payloads remotos inválidos, repetição rápida, troca de dono durante trajeto de NPC e encerramento de rodada durante uma venda. Nenhuma movimentação de dinheiro ou estoque pode ficar negativa ou duplicada. Testar em celular com viewport estreito e Performance Stats para avaliar CPU, rede e FPS.

## Critérios de aceitação
Sem erro de runtime no Output, aluguel e gestão funcionais com dois jogadores, pagamentos e contratos contábeis coerentes, UI sem cortes graves no Android e limite de NPCs respeitado.
