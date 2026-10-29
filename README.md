# Vitrine City 🏪

Simulador econômico original em **Roblox (Luau)**. Jogadores alugam pontos comerciais, compram mercadorias, gerenciam preços e contratam funcionários; clientes têm necessidades, orçamento e preferências próprias.

## Visão
- **Rua Livre:** administração sem disputa eliminatória e fornecedores amplos.
- **Guerra Comercial:** consumidores e estoques de fornecedores compartilhados por partida.
- **Guerra de Preços:** regra inicial de falência eliminatória e último sobrevivente, ainda sem matchmaking.
- **População virtual:** profissões, renda e consumo calculados sem renderizar uma cidade inteira.
- **Monetização justa:** cosméticos, sem vender vantagens econômicas no ranqueado.

## Início
O código fonte é sincronizável com [Rojo](https://rojo.space/). Após instalar Rojo e Roblox Studio:

```sh
rojo build default.project.json -o VitrineCity.rbxlx
```

Abra `VitrineCity.rbxlx` no Roblox Studio e pressione **Play**. O mapa é gerado por scripts.

O GitHub Actions verifica a sintaxe Luau, valida a estrutura e disponibiliza o artefato `VitrineCity-place` compilado. Esses testes não substituem testes de execução no Studio.

### Persistência e segurança
A Rua Livre salva caixa, vendas, despesas, preços e inventário em `DataStoreService`. O perfil só é aberto após uma leitura válida: falhas ou trava de outra sessão bloqueiam a entrada no comércio, sem inventar uma conta vazia. Atualizações usam `UpdateAsync` e reserva de sessão temporária. No Studio, o salvamento permanece desabilitado (`Config.StudioPersistence = false`) para proteger dados de produção. Leia `docs/PERSISTENCIA.md`.

> **Estado:** protótipo em desenvolvimento. Ainda não testado no Roblox Studio nem publicado. Na Rua Livre **publicada**, o progresso é persistido com DataStore; no Studio, o modo de testes é temporário por padrão. Nas partidas competitivas, a economia reinicia a cada rodada. Veja `docs/GDD.md` e `docs/TESTES.md`.
