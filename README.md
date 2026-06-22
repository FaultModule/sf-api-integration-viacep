# Preenchimento Automático de Endereço via CEP — Salesforce + BrasilAPI

Integração assíncrona com a [BrasilAPI](https://brasilapi.com.br/) para preenchimento automático dos campos de endereço no Salesforce a partir do CEP, acionada na criação ou atualização de registros.

> **Limitação:** A BrasilAPI cobre apenas CEPs brasileiros. A integração não suporta endereços internacionais.

---

## Funcionalidade

Quando um registro é criado ou atualizado com o campo `CEP__c` preenchido, o sistema realiza uma chamada assíncrona à API e preenche os campos de endereço nativos do objeto com os dados retornados:

| Campo BrasilAPI  | Campo Salesforce |
|------------------|------------------|
| `cep`            | `PostalCode`     |
| `street`         | `Street`         |
| `city`           | `City`           |
| `state`          | `StateCode`      |
| `neighborhood`   | *(retornado, não mapeado)* |

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
        │   ├── LeadTriggerHandler.cls
        │   ├── AddressUpdaterQueueable.cls
        │   ├── AddressUpdaterService.cls
        │   ├── AddressUpdaterIntegration.cls
        │   └── AddressUpdaterTest.cls          ← em desenvolvimento
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
      ▼  (enfileira job assíncrono)
AddressUpdaterQueueable
      │
      ▼  (orquestra a atualização)
AddressUpdaterService
      │
      ▼  (chamada HTTP GET à BrasilAPI)
AddressUpdaterIntegration
      │
      ▼  (atualiza o registro via DML)
   SObject (campos de endereço)
```

### Descrição das Classes

**`TriggerHandler`**  
Classe abstrata base que define o ciclo de vida dos eventos de trigger (`afterInsert`, `afterUpdate`). Centraliza o ponto de entrada `run()`, separando a lógica de contexto da lógica de negócio.

**`LeadTriggerHandler`**  
Estende `TriggerHandler` e implementa o disparo do job assíncrono de atualização de endereço quando um Lead é criado ou quando o campo `CEP__c` é alterado.

**`AddressUpdaterQueueable`**  
Implementa `Queueable` para processar as atualizações de forma assíncrona, respeitando os limites de chamadas HTTP do Salesforce (não é permitido realizar callouts síncronos em triggers).

**`AddressUpdaterService`**  
Orquestra a lógica de negócio: itera sobre os registros, solicita os dados de endereço à camada de integração e aplica o mapeamento de campos antes de executar o DML de atualização.

**`AddressUpdaterIntegration`**  
Responsável exclusivamente pela comunicação HTTP com a BrasilAPI. Realiza o GET no endpoint `/api/cep/v1/{cep}`, desserializa a resposta JSON no wrapper `ViaCepWrapper` e o retorna ao serviço.

**`LeadTrigger`**  
Trigger no objeto Lead que escuta os eventos `after insert` e `after update` e delega a execução ao `LeadTriggerHandler`.

---

## Pré-requisitos e Configuração

### 1. Remote Site Settings

Autorize o domínio da BrasilAPI para chamadas HTTP externas:

1. Acesse **Setup → Security → Remote Site Settings**
2. Clique em **New Remote Site**
3. Preencha:
   - **Remote Site Name:** `ViaCep`
   - **Remote Site URL:** `https://brasilapi.com.br`
4. Salve.

### 2. Campo Customizado CEP__c

Certifique-se de que o campo `CEP__c` existe no objeto de destino:

- **Field Label:** CEP
- **API Name:** `CEP__c`
- **Data Type:** Text
- **Length:** 8
- **Required:** true

O campo já está incluído no pacote para o objeto **Lead** (`objects/Lead/fields/CEP__c.field-meta.xml`).

---

## Testes

Os testes estão em desenvolvimento na classe `AddressUpdaterTest.cls`.

### Executar os Testes

Via Salesforce CLI:
```bash
sf apex run test --class-names AddressUpdaterTest --result-format human
```

Via Developer Console:
1. Acesse **Developer Console → Test → New Run**
2. Selecione `AddressUpdaterTest`
3. Clique em **Run**

> **Cobertura mínima exigida para deploy:** 75%

---

## Tratamento de Erros

| Situação | Comportamento |
|---|---|
| CEP não encontrado (404) | Registro salvo sem atualização de endereço |
| API indisponível / timeout | Exceção capturada; registro não é bloqueado |
| CEP em branco | Job assíncrono não é enfileirado |
| Erro HTTP (5xx) | Nenhuma atualização realizada |

Erros são registrados via `System.debug` e podem ser acompanhados em **Setup → Apex Jobs**.

---

## Deploy

### Via Salesforce CLI

```bash
# Autenticar na org
sf org login web --alias minha-org

# Validar sem fazer deploy
sf project deploy validate --source-dir force-app --test-level RunSpecifiedTests --tests AddressUpdaterTest

# Deploy completo
sf project deploy start --source-dir force-app --test-level RunSpecifiedTests --tests AddressUpdaterTest
```

### Via Change Set

Inclua os seguintes componentes:

- Apex Class: `TriggerHandler`
- Apex Class: `LeadTriggerHandler`
- Apex Class: `AddressUpdaterQueueable`
- Apex Class: `AddressUpdaterService`
- Apex Class: `AddressUpdaterIntegration`
- Apex Class: `AddressUpdaterTest`
- Apex Trigger: `LeadTrigger`
- Custom Field: `Lead.CEP__c`
- Remote Site Setting: `ViaCep`

---

## Referências

- [BrasilAPI — Documentação CEP v1](https://brasilapi.com.br/docs#tag/CEP-V1)
- [Salesforce — Queueable Apex](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_queueing_jobs.htm)
- [Salesforce — Callouts from Apex](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_callouts.htm)
- [Salesforce — Remote Site Settings](https://help.salesforce.com/s/articleView?id=sf.configuring_remoteproxy.htm)
