# Lobby e separação de modos — Vitrine City v0.5

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
4. Abra `src/ReplicatedStorage/ModeRoutes.luau`; substitua os **quatro** `placeId = 0` pelos PlaceIds reais: o do próprio **Lobby**, da **Rua Livre**, da **Guerra Comercial** e da **Guerra de Preços**. O ID do Lobby é obrigatório para que o botão **VOLTAR AO LOBBY** funcione. IDs zerados desabilitam o teleporte de propósito.
5. Para testes locais: abra o arquivo `VitrineCity-Lobby.rbxlx`, pressione Play e confira quiosques, botões, filas e avisos. **TeleportService não funciona no Studio**.
6. Para testes reais: publique o lobby e os Places, inicie **no cliente Roblox** com 2+ contas, entre na fila e confirme que os usuários foram enviados à mesma partida reservada e que os saldos são exclusivos da rodada.
7. Faça o mesmo com o jogo de produção somente após validar o ambiente de teste. Não habilite `StudioPersistence` com dados de produção.

## Regras implementadas
- Jogadores podem entrar na Rua Livre individualmente. Esse destino é um servidor público, sujeito a matchmaking padrão do Roblox.
- No jogo publicado, as filas de Guerra Comercial e Guerra de Preços usam o MemoryStore para agrupar 2 a 8 jogadores de lobbies diferentes. No Studio, permanece o modo de fila local, com contagem de 12 segundos.
- Cada partida competitiva recebe um `ReservedServerId` compartilhado pelos tickets selecionados. Os lobbies enviam seus próprios jogadores para esse mesmo servidor reservado, sem misturar as economias.
- O servidor controla fila, cancelamento e teleporte. Clientes apenas solicitam ações, sem fornecer PlaceIds e sem enviar dinheiro.
- Falhas síncronas de teleporte e `TeleportInitFailed` têm tratamento. Na fila global, o jogador recebe aviso e pode solicitar nova entrada; não há reentrada automática infinita.
- Fora do Studio, o Place competitivo rejeita acesso direto por servidor público. Somente sessões reservadas são aceitas.
- A interface do lobby funciona em telas móveis e PC; há quiosques 3D com ProximityPrompts.

## Retorno ao lobby (v0.4)
- Todas as lojas e modos competitivos exibem **VOLTAR AO LOBBY** na interface. O jogador confirma a saída com um segundo toque para evitar saídas acidentais.
- A navegação é solicitada ao **servidor**, nunca a um PlaceId fornecido pelo cliente.
- Na Rua Livre, o servidor congela novas transações, captura um snapshot do perfil e chama `ProfileStore.Save` antes do teleporte. Se a gravação falhar, o retorno é cancelado e a operação comercial volta a ficar disponível.
- Quando o teleporte começa, a sessão antiga é liberada no `PlayerRemoving`; o próximo servidor recupera os dados como em uma reconexão normal.
- No competitivo, o retorno abandona aquela sessão. Moeda, contratos e estoque do ranqueado não são levados ao lobby ou à Rua Livre.
- Os eventos `TeleportInitFailed` e um prazo de recuperação de 50 segundos evitam, quando possível, que o botão permaneça bloqueado após uma falha.
- Nenhum teleporte funciona em testes locais do Studio: publicar os Places e testar no **cliente Roblox**.

### Checklist de retorno
- [ ] Em Rua Livre publicada: comprar mercadorias -> retornar ao lobby -> entrar na Rua Livre novamente -> validar saldo e inventário.
- [ ] Alterar o preço e retornar imediatamente; conferir se o salvamento foi feito antes da saída.
- [ ] Falha de DataStore: teleporte deve ser cancelado e dinheiro/estoque permanecem no servidor atual.
- [ ] Falha de TeleportAsync e de TeleportInitFailed: botão é reativado e jogador recebe mensagem.
- [ ] No ranqueado, sair no meio da partida não afeta os saldos de outros jogadores.
- [ ] Em Studio, botão informa que o teleporte deve ser testado em jogo publicado.
- [ ] Repetir testes em celular.

## Limitações conhecidas
- O matchmaking global beta já está codificado com MemoryStore e tickets por sessão, mas ainda depende de testes em múltiplos servidores publicados. Ver `docs/MATCHMAKING_GLOBAL.md`.
- O sistema não possui equipes, grupos de amigos, reconexão a partida nem preenchimento de vagas após início da rodada.
- Se um membro falhar no teleporte global, a reconexão à mesma partida ainda não é garantida; ele pode entrar novamente na fila.
- É obrigatório configurar PlaceIds, publicar os Places e validar teleporte no Roblox real; builds Rojo e sintaxe Luau não provam o funcionamento em runtime.
- A Guerra de Preços ainda precisa de balanceamento e testes de justiça, principalmente para início com atrasos de conexão.

## Testes pendentes
- [ ] Quatro arquivos `.rbxlx` compilados e abertos no Studio sem erros.
- [ ] UI responsiva em Android e PC.
- [ ] Com dois jogadores em lobbies publicados distintos: fila global, destino reservado comum e saldo independente. No Studio testar apenas fila local e cronômetro.
- [ ] Com oito jogadores: partida cheia e sem jogador duplicado.
- [ ] Cancelar fila / desconectar / falha de teleporte não deixam participantes presos.
- [ ] Nenhum cliente altera reserva, saldo, estoque ou PlaceId.
- [ ] Login competitivo por servidor público é recusado.
