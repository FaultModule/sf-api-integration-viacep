public class AddressUpdaterQueueable implements Queueable, Database.AllowsCallouts {
    private List<SObject> updateRecords;
    
    public AddressUpdaterQueueable(List<SObject> updateRecords) {
        this.updateRecords = updateRecords;
    }

    public void execute(QueueableContext context) {
        AddressUpdaterService.viaCepUpdateLead(takeIds(updateRecords));
    }

    private List<SObject> takeIds(List<SObject> updateRecords){
        List<Id> ids = new List<Id>();
        for(Sobject record : updateRecords){
            ids.add(record.Id);
        }
        return [SELECT Id, CEP__c FROM Lead WHERE Id IN: ids];
    }
}