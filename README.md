# Vitrine City 🏪

Simulador econômico original em **Roblox (Luau)**. Jogadores alugam pontos comerciais, compram mercadorias, gerenciam preços e contratam funcionários; clientes têm necessidades, orçamento e preferências próprias.

## Visão
- **Rua Livre:** administração sem disputa eliminatória e fornecedores amplos.
- **Guerra Comercial:** consumidores e estoques de fornecedores compartilhados por partida.
- **Guerra de Preços:** regra inicial de falência eliminatória e último sobrevivente, ainda sem matchmaking.
- **População virtual:** profissões, renda e consumo calculados sem renderizar uma cidade inteira.
- **Eventos econômicos:** escassez de queijo, feira de roupas, colheitas e mudanças de procura afetam NPCs e fornecedores.
- **Rua visual:** fachadas comerciais completas com vitrines, toldos, letreiros, portas e exposição de produtos; gôndolas laterais, balcões e clientes com sacolas após comprar.
- **Relatórios da loja:** conversão de visitas, perdas por preço/estoque, produtos procurados, vendas por item e despesas por categoria.
- **Clientes visitam lojas de verdade:** entram pela vitrine, examinam as gôndolas, seguem ao caixa e saem com a sacola após a compra. O dono administra o negócio também pela caixa registradora física.
- **Primeiros passos e vendas visíveis:** guia discreto de aluguel, compra e reposição; painel abre após alugar, notificações e cinco recibos recentes de vendas reais.
- **Monetização justa:** cosméticos, sem vender vantagens econômicas no ranqueado.

## Início
O código fonte é sincronizável com [Rojo](https://rojo.space/). Após instalar Rojo e Roblox Studio:

```sh
rojo build lobby.project.json -o VitrineCity-Lobby.rbxlx
rojo build default.project.json -o VitrineCity-RuaLivre.rbxlx
rojo build ranked.project.json -o VitrineCity-GuerraComercial.rbxlx
rojo build price_war.project.json -o VitrineCity-GuerraDePrecos.rbxlx
```

Abra cada arquivo `.rbxlx` no Roblox Studio para testar o mapa gerado por scripts. O GitHub Actions também cria os quatro arquivos em um único artefato.

O GitHub Actions verifica a sintaxe Luau, valida a estrutura e disponibiliza o artefato `VitrineCity-Places` com os quatro lugares compilados. A v0.6 também evita redesenhar cartões de inventário quando seus dados não mudaram. Na v0.7, o workflow passou a executar testes de indicadores econômicos em interpretador Luau. Confira [eventos econômicos](docs/EVENTOS_MERCADO.md), [relatórios comerciais](docs/RELATORIOS_COMERCIAIS.md) e a [reforma visual das lojas](docs/REFORMA_VISUAL_LOJAS.md) e [percursos NPC e caixa interativo](docs/CLIENTES_E_CAIXA.md) e [guia da primeira loja](docs/PRIMEIRA_LOJA.md). Esses testes não substituem testes de execução no Studio.

### Lobby e partidas reservadas
O lobby dispõe de três quiosques. Para publicar, configure os **quatro** PlaceIds (incluindo Lobby) em `src/ReplicatedStorage/ModeRoutes.luau` (**0 significa desabilitado**) e publique os quatro Places **na mesma experiência Roblox**. O Lobby deve ser a entrada principal. Os modos competitivos usam **matchmaking global beta**, permitindo reunir 2–8 jogadores de lobbies diferentes através de `MemoryStoreService` e partidas reservadas por `TeleportService`. No Roblox Studio permanece uma fila local para testes. Consulte [matchmaking global](docs/MATCHMAKING_GLOBAL.md). Todas as lojas possuem **VOLTAR AO LOBBY**, com confirmação e salvamento prévio na Rua Livre. Veja [o guia do lobby](docs/MODOS_LOBBY.md). Teleportes não funcionam no Studio.

### Persistência e segurança
A Rua Livre salva caixa, vendas, despesas, preços e inventário em `DataStoreService`. O perfil só é aberto após uma leitura válida: falhas ou trava de outra sessão bloqueiam a entrada no comércio, sem inventar uma conta vazia. Atualizações usam `UpdateAsync` e reserva de sessão temporária. No Studio, o salvamento permanece desabilitado (`Config.StudioPersistence = false`) para proteger dados de produção. Leia `docs/PERSISTENCIA.md`.

> **Estado:** protótipo em desenvolvimento. Ainda não testado no Roblox Studio nem publicado. Na Rua Livre **publicada**, o progresso é persistido com DataStore; no Studio, o modo de testes é temporário por padrão. Nas partidas competitivas, a economia reinicia a cada rodada. Veja `docs/GDD.md` e `docs/TESTES.md`.
