trigger LeadTrigger on Lead (after insert, after update) {
    new LeadTriggerHandler().run();
}