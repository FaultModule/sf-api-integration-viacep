public with sharing class ViaCepService {

    public static ViaCepWrapper viaCepServiceIntegration(String cep) {
        if (String.isBlank(cep)) return null;

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://viacep.com.br/ws/' + cep + '/json');
        request.setMethod('GET');
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            return (ViaCepWrapper) JSON.deserialize(response.getBody(), ViaCepWrapper.class);
        }

        return null;
    }

    public static void viaCepPopulateLead(List<Lead> leads) {
        for (Lead lead : leads) {
            if (String.isBlank(lead.CEP__c)) continue;

            ViaCepWrapper endereco = viaCepServiceIntegration(lead.CEP__c);
            if (endereco == null) continue;

            lead.City       = endereco.localidade;
            lead.PostalCode = endereco.cep;
            lead.Street     = endereco.logradouro;
            lead.State      = endereco.estado;
        }
    }

    public static void viaCepUpdateLead(List<Lead> leadsToUpdate) {
        viaCepPopulateLead(leadsToUpdate);
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }

    public class ViaCepWrapper {
        public String cep;
        public String logradouro;
        public String complemento;
        public String unidade;
        public String bairro;
        public String localidade;
        public String uf;
        public String estado;
        public String regiao;
        public String ibge;
        public String gia;
        public String ddd;
        public String siafi;
    }
}