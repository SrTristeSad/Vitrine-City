# Vitrine City — Matchmaking global beta (v0.5)

## Finalidade
Unir comerciantes em **Guerra Comercial** e **Guerra de Preços** mesmo quando estão em servidores de lobby diferentes, sem transferir saldo ou inventário persistente.

## Arquitetura implementada
- Arquivo: `src/ServerScriptService/GlobalMatchmaker.luau`; só roda no Place do lobby.
- Serviço: `MemoryStoreService` / SortedMaps (`VC_MM_v1_ranked`, `VC_MM_v1_price_war` e `VC_MM_v1_matches`).
- Cada ticket contém UserId, `game.JobId`, nonce aleatório, modo, data de entrada, prazo e estado (`waiting`, `claimed`, `assigned`, `cancelled`).
- `UpdateAsync` faz claims atômicos com validação de nonce e servidor. Para criar a partida, o coordenador reúne entre 2 e 8 tickets, atribui o mesmo GUID de servidor reservado e só depois publica o match como **ready** em um segundo mapa.
- Cada lobby consulta periodicamente seus jogadores na fila e, após confirmar o match ready, usa `TeleportOptions.ReservedServerId` com `TeleportService:TeleportAsync`.
- Não dependemos de mensagens de entrega não garantida do MessagingService para saber se a partida existe. A descoberta é por polling de MemoryStore.
- Tickets têm TTL curto e renovações; claims e partidas inacabadas podem expirar e ser liberados. Cancelamento e falhas verificam a identidade do ticket antes de alterá-lo.
- Teleportes com falha assíncrona são tratados com `TeleportInitFailed`; se a conexão demorar mais que 50s, o jogador recebe um aviso e pode tentar novamente.

## Como ativar
- `src/ReplicatedStorage/ModeRoutes.luau`: `GlobalMatchmakingEnabled = true`.
- **Studio:** usa automaticamente a fila local de teste (MemoryStore global e teleportes reais não são exercitados localmente).
- **Experiência publicada:** usa fila compartilhada se os PlaceIds estiverem configurados e MemoryStore estiver disponível; **não converte falhas de memória em partidas locais silenciosas**. O jogador recebe mensagem de indisponibilidade.
- Os PlaceIds de **Lobby**, **Rua Livre**, **Guerra Comercial** e **Guerra de Preços** precisam ser os quatro Places dentro da MESMA experiência (não IDs de universos distintos). Veja `docs/MODOS_LOBBY.md`.

## Testes imprescindíveis (AINDA NÃO EXECUTADOS)
1. Publicar os quatro Places em experiência de teste isolada e preencher seus PlaceIds.
2. Abrir **dois servidores diferentes de lobby**, com jogadores distintos. Cada um entra na Guerra Comercial. Verificar que os dois chegam à **mesma instância reservada** do Place ranqueado.
3. Repetir com Guerra de Preços, 3+ lobbies e até oito jogadores no mesmo servidor de partida.
4. Dois coordenadores tentando dar claim ao mesmo ticket: nenhum usuário deve entrar em dois jogos.
5. Cancelar fila antes e depois do claim; desconectar durante a preparação; simular falha no MemoryStore e no teleporte.
6. Em um servidor, desligar o lobby no meio do matchmaking; tickets sem heartbeat devem expirar e um novo usuário deve conseguir entrar depois.
7. Testar contagem aproximada da fila no HUD e confirmar ausência de tickets permanentemente presos.
8. Monitorar o Memory Store Observability Dashboard: requisições, memória, throttling, limites de partição e tempo até encontrar partida.
9. Testar em Android e validar que os botões de entrar e cancelar continuam acessíveis.

## Limites e cuidados
- É um sistema **beta não validado com servidores reais**. A compilação Luau e o build Rojo confirmam apenas sintaxe e montagem.
- A fila global atualmente consulta até 24 tickets por modo por rodada. Um mapa ordenado muito carregado pode precisar de **sharding** por região, faixa ou horário para manter vazão.
- Leituras `GetRangeAsync` têm custo proporcional aos itens retornados; não aumentar frequência ou limite sem medir as cotas do Roblox.
- Um jogador desconectado durante a atribuição pode fazer uma partida começar com menos do que os tickets previstos. Ainda falta um protocolo de confirmação de chegada e reconexão.
- Não existe garantia de matchmaking em tempo fixo. Prioridade de rank, filtro por latência, grupos de amigos, anti-abandono e MMR ainda não foram implementados.
- `MessagingService` não é utilizado nesta versão; foi evitado por ser uma entrega best-effort, inadequada como única fonte de verdade da partida.

## Documentação Roblox
- Memory Stores: https://create.roblox.com/docs/cloud-services/memory-stores
- Sorted Map: https://create.roblox.com/docs/reference/engine/classes/MemoryStoreSortedMap
- TeleportOptions: https://create.roblox.com/docs/reference/engine/classes/TeleportOptions
- Melhores práticas: https://create.roblox.com/docs/cloud-services/memory-stores/best-practices
