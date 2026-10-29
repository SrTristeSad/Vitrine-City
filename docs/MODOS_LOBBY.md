# Lobby e separação de modos — Vitrine City v0.3

## Quatro Places dentro de UMA experiência Roblox
| Ordem | Arquivo Rojo | Função |
|---|---|---|
| 1 | `lobby.project.json` | Place principal, praça e seleção de modos |
| 2 | `default.project.json` | Rua Livre (progressão persistente) |
| 3 | `ranked.project.json` | Guerra Comercial (partida temporária) |
| 4 | `price_war.project.json` | Guerra de Preços (partida eliminatória) |

Cada Place recebe um `.rbxlx` no artefato `VitrineCity-Places` do GitHub Actions. O arquivo `default.project.json` permanece compatível com a primeira versão.

## Preparação obrigatória para publicar
1. No **Roblox Studio / Creator Dashboard**, crie uma experiência de teste e quatro Places dentro dela; escolha o **Lobby** como Place de entrada (start place).
2. Faça build dos quatro arquivos com Rojo ou baixe o artefato da pipeline CI. Publique cada `.rbxlx` no **Place correspondente**, sem criar quatro experiências independentes.
3. Copie os **PlaceIds reais**, nunca os UniverseIds, de Rua Livre, Guerra Comercial e Guerra de Preços.
4. Abra `src/ReplicatedStorage/ModeRoutes.luau`; substitua os três `placeId = 0` pelos IDs da experiência de teste; commite para gerar o lobby atualizado. IDs zerados desabilitam a entrada de propósito.
5. Para testes locais: abra o arquivo `VitrineCity-Lobby.rbxlx`, pressione Play e confira quiosques, botões, filas e avisos. **TeleportService não funciona no Studio**.
6. Para testes reais: publique o lobby e os Places, inicie **no cliente Roblox** com 2+ contas, entre na fila e confirme que os usuários foram enviados à mesma partida reservada e que os saldos são exclusivos da rodada.
7. Faça o mesmo com o jogo de produção somente após validar o ambiente de teste. Não habilite `StudioPersistence` com dados de produção.

## Regras implementadas
- Jogadores podem entrar na Rua Livre individualmente. Esse destino é um servidor público, sujeito a matchmaking padrão do Roblox.
- Nas filas de Guerra Comercial e Guerra de Preços, aguardar ao menos dois jogadores e abrir partida até oito jogadores. Após atingir o mínimo, contagem regressiva de 12 segundos; atingir oito inicia imediatamente.
- Para cada partida competitiva, o lobby cria um novo `ReservedServerId` e chama `TeleportAsync` com o lote de jogadores, de forma que a economia da partida não se misture a outras partidas.
- O servidor controla fila, cancelamento e teleporte. Clientes apenas solicitam ações, sem fornecer PlaceIds e sem enviar dinheiro.
- Falhas síncronas de teleporte são tratadas com `pcall`; `TeleportInitFailed` reencaminha participantes de partidas para a fila local. Não há repetição infinita automática.
- Fora do Studio, o Place competitivo rejeita acesso direto por servidor público. Somente sessões reservadas são aceitas.
- A interface do lobby funciona em telas móveis e PC; há quiosques 3D com ProximityPrompts.

## Limitações conhecidas
- **A fila é por servidor de lobby**, não global: jogadores em lobbies diferentes não serão combinados. Matchmaking global precisará de MemoryStore e algoritmo de coordenação.
- O sistema não possui equipes, grupos de amigos, reconexão a partida nem preenchimento de vagas após início da rodada.
- Se um membro falhar enquanto o grupo se teleporta, ele retorna à fila local, não à partida anterior.
- É obrigatório configurar PlaceIds, publicar os Places e validar teleporte no Roblox real; builds Rojo e sintaxe Luau não provam o funcionamento em runtime.
- A Guerra de Preços ainda precisa de balanceamento e testes de justiça, principalmente para início com atrasos de conexão.

## Testes pendentes
- [ ] Quatro arquivos `.rbxlx` compilados e abertos no Studio sem erros.
- [ ] UI responsiva em Android e PC.
- [ ] Com dois jogadores: fila, cronômetro, servidor reservado e saldo inicial independente.
- [ ] Com oito jogadores: partida cheia e sem jogador duplicado.
- [ ] Cancelar fila / desconectar / falha de teleporte não deixam participantes presos.
- [ ] Nenhum cliente altera reserva, saldo, estoque ou PlaceId.
- [ ] Login competitivo por servidor público é recusado.
