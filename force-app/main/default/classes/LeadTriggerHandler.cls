public class LeadTriggerHandler extends TriggerHandler {
    protected override void afterInsert() {
        System.enqueueJob(new AddressUpdaterQueueable(Trigger.new));
    }
}