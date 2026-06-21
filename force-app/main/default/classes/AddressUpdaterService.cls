public with sharing class AddressUpdaterService {

    public static ViaCepWrapper viaCepServiceIntegration(String cep) {
        if (String.isBlank(cep)) return null;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://brasilapi.com.br/api/cep/v1/' + cep);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            return (ViaCepWrapper) JSON.deserialize(response.getBody(), ViaCepWrapper.class);
        }
        return null;
    }

    public static void viaCepPopulateRecord(List<SObject> updateRecords) {
        for (SObject record : updateRecords) {
            String cep = (String) record.get('CEP__c');
            if (String.isBlank(cep)) continue;
            ViaCepWrapper endereco = viaCepServiceIntegration(cep);
            if (endereco == null) continue;
            record.put('City',endereco.city);
            record.put('PostalCode',endereco.cep);
            record.put('Street',endereco.street);
            record.put('StateCode',endereco.state);
        }
    }

    public static void viaCepUpdateLead(List<SObject> updateRecords) {
        viaCepPopulateLead(updateRecords);
        if (!updateRecords.isEmpty()) {
            update updateRecords;
        }
    }

    public class ViaCepWrapper {
        public String cep;
        public String street;
        public String neighborhood;
        public String city;
        public String state;
    }
}