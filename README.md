# Preenchimento Automático de Endereço via CEP — Salesforce + BrasilAPI

Integração assíncrona com a [BrasilAPI](https://brasilapi.com.br/) para preenchimento automático dos campos de endereço no Salesforce a partir do CEP, acionada na criação ou atualização de registros.

> **Limitação:** A BrasilAPI cobre apenas CEPs brasileiros. A integração não suporta endereços internacionais.

---

## Funcionalidade

Quando um registro é criado ou atualizado com o campo `CEP__c` preenchido, o sistema realiza uma chamada assíncrona à API e preenche os campos de endereço nativos do objeto com os dados retornados:

| Campo BrasilAPI | Campo Salesforce |
|---|---|
| `cep` | `PostalCode` |
| `street` | `Street` |
| `city` | `City` |
| `state` | `StateCode` |
| `neighborhood` | *(retornado, não mapeado)* |

No `afterUpdate`, o job só é enfileirado se o valor de `CEP__c` efetivamente mudou — atualizações em outros campos não disparam a integração.

---

## Compatibilidade de Objetos

A integração pode ser usada em qualquer objeto Salesforce que possua os **campos de endereço nativos** (`Street`, `City`, `PostalCode`, `StateCode`) e um campo customizado `CEP__c` (Text, tamanho 8).

Por padrão, o projeto vem configurado para o objeto **Lead**. Para aplicar a outros objetos, basta estender `TriggerHandler` e criar um trigger correspondente.

---

## Estrutura do Projeto

```
force-app/
└── main/
    └── default/
        ├── triggers/
        │   └── LeadTrigger.trigger
        ├── classes/
        │   ├── TriggerHandler.cls
        │   ├── TriggerHandlerTest.cls
        │   ├── LeadTriggerHandler.cls
        │   ├── LeadTriggerHandlerTest.cls
        │   ├── AddressUpdaterQueueable.cls
        │   ├── AddressUpdaterQueueableTest.cls
        │   ├── AddressUpdaterService.cls
        │   ├── AddressUpdaterServiceTest.cls
        │   ├── AddressUpdaterIntegration.cls
        │   └── AddressUpdaterIntegrationTest.cls
        ├── objects/
        │   └── Lead/fields/CEP__c.field-meta.xml
        └── remoteSiteSettings/
            └── ViaCep.remoteSite-meta.xml
```

### Fluxo de Execução

```
LeadTrigger
      │  (after insert / after update)
      ▼
LeadTriggerHandler  ──extends──▶  TriggerHandler
      │
      │  after insert: sempre enfileira
      │  after update: somente se CEP__c mudou
      ▼
AddressUpdaterQueueable
      │  (re-query dos registros para contexto mutável)
      ▼
AddressUpdaterService
      │  (itera registros, chama integração, aplica DML)
      ▼
AddressUpdaterIntegration
      │  (HTTP GET → BrasilAPI → deserializa JSON)
      ▼
   SObject (campos de endereço atualizados)
```

### Descrição das Classes

**`TriggerHandler`**
Classe abstrata base que define o ciclo de vida dos eventos de trigger (`afterInsert`, `afterUpdate`). Centraliza o ponto de entrada `run()`, separando a lógica de contexto da lógica de negócio.

**`LeadTriggerHandler`**
Estende `TriggerHandler` e implementa o disparo do job assíncrono. No `afterInsert` sempre enfileira; no `afterUpdate` verifica se `CEP__c` mudou antes de enfileirar.

**`AddressUpdaterQueueable`**
Implementa `Queueable` e `Database.AllowsCallouts` para processar as atualizações de forma assíncrona. Re-faz a query dos registros para obter instâncias mutáveis antes de repassar ao serviço.

**`AddressUpdaterService`**
Orquestra a lógica de negócio: itera sobre os registros, solicita os dados de endereço à camada de integração e aplica o mapeamento de campos antes de executar o DML de atualização.

**`AddressUpdaterIntegration`**
Responsável exclusivamente pela comunicação HTTP com a BrasilAPI. Realiza o GET no endpoint `/api/cep/v1/{cep}`, desserializa a resposta JSON no wrapper `ViaCepWrapper` e o retorna ao serviço. Erros de conexão e JSON malformado são capturados e retornam `null`.

**`LeadTrigger`**
Trigger no objeto Lead que escuta os eventos `after insert` e `after update` e delega a execução ao `LeadTriggerHandler`.

---

## Pré-requisitos e Configuração

### 1. Remote Site Settings

Autorize o domínio da BrasilAPI para chamadas HTTP externas. O arquivo `ViaCep.remoteSite-meta.xml` já está incluído no projeto e é implantado automaticamente via CLI.

Para configuração manual:
1. Acesse **Setup → Security → Remote Site Settings**
2. Clique em **New Remote Site**
3. Preencha:
   - **Remote Site Name:** `ViaCep`
   - **Remote Site URL:** `https://brasilapi.com.br`
4. Salve.

### 2. Campo Customizado CEP__c

O campo já está incluído no pacote para o objeto **Lead** (`objects/Lead/fields/CEP__c.field-meta.xml`).

| Propriedade | Valor |
|---|---|
| Field Label | CEP |
| API Name | `CEP__c` |
| Data Type | Text |
| Length | 8 |
| Required | true |

Para outros objetos, crie o campo manualmente com as mesmas configurações.

---

## Testes

O projeto possui **5 classes de teste unitário**, uma por classe de produção, com cobertura de todos os caminhos de execução.

| Classe de Teste | Classe Testada | Cenários |
|---|---|---|
| `TriggerHandlerTest` | `TriggerHandler` | Roteamento para `afterInsert` e `afterUpdate` |
| `LeadTriggerHandlerTest` | `LeadTriggerHandler` | Insert, update com CEP mudado, CEP inalterado, CEP limpo |
| `AddressUpdaterQueueableTest` | `AddressUpdaterQueueable` | Execução com registros, lista vazia |
| `AddressUpdaterServiceTest` | `AddressUpdaterService` | Campos populados, CEP blank, API indisponível, DML exception |
| `AddressUpdaterIntegrationTest` | `AddressUpdaterIntegration` | Resposta 200, 404, timeout, JSON inválido, CEP blank |

### Executar os Testes

Via Salesforce CLI:
```bash
sf apex run test \
  --class-names TriggerHandlerTest,LeadTriggerHandlerTest,AddressUpdaterQueueableTest,AddressUpdaterServiceTest,AddressUpdaterIntegrationTest \
  --result-format human
```

Via Developer Console:
1. Acesse **Developer Console → Test → New Run**
2. Selecione todas as classes `*Test`
3. Clique em **Run**

> **Cobertura para deploy:** 100%

---

## Tratamento de Erros

| Situação | Comportamento |
|---|---|
| CEP em branco no insert | Job assíncrono não é enfileirado |
| CEP não alterado no update | Job assíncrono não é enfileirado |
| CEP não encontrado (404) | Registro salvo sem atualização de endereço |
| API indisponível / timeout | Exceção capturada em `AddressUpdaterIntegration`; registro não é bloqueado |
| Resposta JSON malformada | Exceção capturada; `integration()` retorna `null`; registro não atualizado |
| Erro HTTP (5xx) | `null` retornado; nenhuma atualização realizada |

Erros são registrados via `System.debug` e podem ser acompanhados em **Setup → Apex Jobs**.

---

## Deploy

### Via Salesforce CLI

```bash
# Autenticar na org
sf org login web --alias minha-org

# Validar sem fazer deploy
sf project deploy validate \
  --source-dir force-app \
  --test-level RunSpecifiedTests \
  --tests TriggerHandlerTest,LeadTriggerHandlerTest,AddressUpdaterQueueableTest,AddressUpdaterServiceTest,AddressUpdaterIntegrationTest

# Deploy completo
sf project deploy start \
  --source-dir force-app \
  --test-level RunSpecifiedTests \
  --tests TriggerHandlerTest,LeadTriggerHandlerTest,AddressUpdaterQueueableTest,AddressUpdaterServiceTest,AddressUpdaterIntegrationTest
```

### Via Change Set

Inclua os seguintes componentes:

- Apex Class: `TriggerHandler` + `TriggerHandlerTest`
- Apex Class: `LeadTriggerHandler` + `LeadTriggerHandlerTest`
- Apex Class: `AddressUpdaterQueueable` + `AddressUpdaterQueueableTest`
- Apex Class: `AddressUpdaterService` + `AddressUpdaterServiceTest`
- Apex Class: `AddressUpdaterIntegration` + `AddressUpdaterIntegrationTest`
- Apex Trigger: `LeadTrigger`
- Custom Field: `Lead.CEP__c`
- Remote Site Setting: `ViaCep`

---

## Referências

- [BrasilAPI — Documentação CEP v1](https://brasilapi.com.br/docs#tag/CEP-V1)
- [Salesforce — Queueable Apex](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_queueing_jobs.htm)
- [Salesforce — Callouts from Apex](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_callouts.htm)
- [Salesforce — Remote Site Settings](https://help.salesforce.com/s/articleView?id=sf.configuring_remoteproxy.htm)
- [Salesforce — Database.stripInaccessible](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_with_security_stripInaccessible.htm)
