public class AddressUpdaterQueueable implements Queueable, Database.AllowsCallouts {
    private List<SObject> updateRecords;
    private List<Id> ids;
    public AddressUpdaterQueueable(List<SObject> updateRecords) {
        this.updateRecords = updateRecords;
    }

    public void execute(QueueableContext context) {
        AddressUpdaterService.viaCepUpdateLead(updateRecords);
    }

    private takeIds(List<SObject> updateRecords){
        for(Sobject record : updateRecords){

        }
    }
}