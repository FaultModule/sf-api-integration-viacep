trigger LeadTrigger on Lead (after insert, after update) {
    if (Trigger.isAfter && Trigger.isInsert) {
        System.enqueueJob(new ViaCepQueueable([SELECT Id, CEP__c FROM Lead WHERE Id in: Trigger.new]));
    }
}