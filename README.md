# 📮 API de Preenchimento de CEP — Salesforce + ViaCEP

Integração automática com a API pública [ViaCEP](https://viacep.com.br/) para preenchimento dos campos de endereço do objeto **Lead** no Salesforce, acionada no momento da criação do registro.

---

## 📋 Funcionalidade

Quando um novo **Lead** é criado com o campo `CEP__c` preenchido, o sistema realiza automaticamente uma chamada à API do ViaCEP e preenche os campos de endereço do Lead com os dados retornados:

| Campo ViaCEP | Campo Salesforce |
|---|---|
| `logradouro` | `Street` |
| `bairro` | `City` (bairro) |
| `localidade` | `City` |
| `uf` | `State` |
| `cep` | `PostalCode` |
| `pais` | `Country` |

---

## 🏗️ Estrutura do Projeto

```
force-app/
└── main/
    └── default/
        ├── triggers/
        │   └── LeadTrigger.trigger
        └── classes/
            ├── ViaCepQueueable.cls
            ├── ViaCepQueueable.cls-meta.xml
            ├── ViaCepService.cls
            ├── ViaCepService.cls-meta.xml
            ├── LeadTriggerTest.cls
            └── LeadTriggerTest.cls-meta.xml
```

### Fluxo de Execução

```
LeadTrigger.trigger
        │
        ▼ (after insert)
ViaCepQueueable.cls
        │
        ▼ (chamada HTTP assíncrona)
ViaCepService.cls
        │
        ▼ (atualiza o Lead)
     Lead (Address fields)
```

### Descrição das Classes

**`LeadTrigger.trigger`**
Acionado após a inserção (`after insert`) de um novo Lead. Filtra registros com `CEP__c` preenchido e enfileira o job assíncrono.

**`ViaCepQueueable.cls`**
Implementa `Queueable` para processar os leads de forma assíncrona, respeitando os limites de chamadas HTTP do Salesforce.

**`ViaCepService.cls`**
Responsável pela chamada HTTP à API do ViaCEP, mapeamento dos campos retornados e atualização dos registros de Lead.

---

## ⚙️ Pré-requisitos e Configuração

### 1. Remote Site Settings

Para permitir chamadas à API externa, adicione a URL do ViaCEP como site remoto autorizado:

1. Acesse **Setup → Security → Remote Site Settings**
2. Clique em **New Remote Site**
3. Preencha:
   - **Remote Site Name:** `ViaCEP`
   - **Remote Site URL:** `https://viacep.com.br`
4. Salve.

### 2. Campo Customizado no Lead

Certifique-se de que o campo `CEP__c` existe no objeto Lead:

- **Object:** Lead
- **Field Label:** CEP
- **API Name:** `CEP__c`
- **Data Type:** Text (8)

---

## 🧪 Testes

Os testes estão implementados na classe `LeadTriggerTest.cls` e cobrem os cenários principais:

| Cenário | Método |
|---|---|
| CEP válido retorna endereço preenchido | `testLeadWithValidCep()` |
| CEP inválido não quebra o fluxo | `testLeadWithInvalidCep()` |
| Lead sem CEP não aciona a integração | `testLeadWithoutCep()` |
| Timeout/erro de rede é tratado | `testApiTimeout()` |

### Executar os Testes

Via Salesforce CLI:
```bash
sf apex run test --class-names LeadTriggerTest --result-format human
```

Via Developer Console:
1. Acesse **Developer Console → Test → New Run**
2. Selecione `LeadTriggerTest`
3. Clique em **Run**

> **Cobertura mínima exigida para deploy:** 75%

---

## ⚠️ Tratamento de Erros

| Situação | Comportamento |
|---|---|
| CEP não encontrado (404) | Lead é salvo sem atualizar o endereço |
| API fora do ar / timeout | Exceção é capturada e logada; Lead não é bloqueado |
| CEP com formato inválido | Integração não é acionada |
| Erro de HTTP (5xx) | Log de erro gerado; nenhuma atualização realizada |

Erros são registrados via `System.debug` e podem ser monitorados em **Setup → Apex Jobs** ou via ferramentas de monitoramento como **Datadog** ou **Splunk**.

---

## 🚀 Deploy

### Via Salesforce CLI (SFDX)

```bash
# Autenticar na org
sf org login web --alias minha-org

# Validar sem fazer deploy
sf project deploy validate --source-dir force-app --test-level RunSpecifiedTests --tests LeadTriggerTest

# Deploy completo
sf project deploy start --source-dir force-app --test-level RunSpecifiedTests --tests LeadTriggerTest
```

### Via Change Set

1. Adicione ao change set os seguintes componentes:
   - Apex Class: `ViaCepQueueable`
   - Apex Class: `ViaCepService`
   - Apex Class: `LeadTriggerTest`
   - Apex Trigger: `LeadTrigger`
   - Custom Field: `Lead.CEP__c`
2. Envie o change set para a org de destino
3. Execute o deploy incluindo os testes

---

## 🔗 Referências

- [Documentação ViaCEP](https://viacep.com.br/)
- [Salesforce — Queueable Apex](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_queueing_jobs.htm)
- [Salesforce — Callouts from Apex](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_callouts.htm)
- [Salesforce — Remote Site Settings](https://help.salesforce.com/s/articleView?id=sf.configuring_remoteproxy.htm)
