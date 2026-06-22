public with sharing class AddressUpdaterService {

    public static List<SObject> viaCepPopulateRecord(List<SObject> updateRecords) {
        List<SObject> populated = new List<SObject>();
        for (SObject record : updateRecords) {
            String cep = (String) record.get('CEP__c');
            if (String.isBlank(cep)) continue;
            AddressUpdaterIntegration.ViaCepWrapper endereco = AddressUpdaterIntegration.integration(cep);
            if (endereco == null) continue;
            record.put('City', endereco.city);
            record.put('PostalCode', endereco.cep);
            record.put('Street', endereco.street);
            record.put('StateCode', endereco.state);
            populated.add(record);
        }
        return populated;
    }

    public static void viaCepUpdateLead(List<SObject> updateRecords) {
        List<SObject> toUpdate = viaCepPopulateRecord(updateRecords);
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
    
}