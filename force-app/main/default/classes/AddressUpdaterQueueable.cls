public class AddressUpdaterQueueable implements Queueable, Database.AllowsCallouts {
    private List<SObject> updateRecords;
    
    public AddressUpdaterQueueable(List<SObject> updateRecords) {
        this.updateRecords = updateRecords;
    }

    public void execute(QueueableContext context) {
        AddressUpdaterService.viaCepUpdateLead(takeIds(updateRecords));
    }

    private List<SObject> takeIds(List<SObject> updateRecords){
        if (updateRecords == null || updateRecords.isEmpty()) return new List<SObject>();
        List<Id> ids = new List<Id>();
        String sObjectType = String.valueOf(updateRecords[0].getSObjectType());
        for(SObject record : updateRecords){
            ids.add(record.Id);
        }
        String query = 'SELECT Id, CEP__c FROM ' + sObjectType + ' WHERE Id IN :ids';
        return Database.query(query);
    }
}