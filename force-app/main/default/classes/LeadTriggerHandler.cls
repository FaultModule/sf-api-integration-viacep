public class LeadTriggerHandler extends TriggerHandler {
    protected override void afterInsert() {
        System.enqueueJob(new AddressUpdaterQueueable(Trigger.new));
    }

    protected override void afterUpdate() {
        List<SObject> changed = cepIsChanged();
        if (changed != null) {
            System.enqueueJob(new AddressUpdaterQueueable(changed));
        }
    }

    private static List<SObject> cepIsChanged(){
        List<SObject> cepChanged = new List<SObject>();
        for (SObject record : Trigger.new) {
            String newCep = (String) record.get('CEP__c');
            String oldCep = (String) Trigger.oldMap.get(record.Id).get('CEP__c');
            if (String.isNotBlank(newCep) && newCep != oldCep) {
                cepChanged.add(record);
            }
        }
        if (!cepChanged.isEmpty()) {
            return cepChanged;
        }
        return null;
    }
}