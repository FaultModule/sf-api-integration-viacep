trigger LeadTrigger on Lead (after insert) {
    new LeadTriggerHandler().run();
}