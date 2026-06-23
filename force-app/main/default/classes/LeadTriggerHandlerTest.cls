@isTest
private class LeadTriggerHandlerTest {

    private class EmptyMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            return new HttpResponse();
        }
    }
    @TestSetup
    static void setup() {
        insert new Lead(LastName = 'Test', Company = 'Heletech', CEP__c = '25250536');
    }
    @isTest
    static void afterInsert_shouldEnqueueJob() {
        Test.setMock(HttpCalloutMock.class, new EmptyMock());
        Test.startTest();
        insert new Lead(LastName = 'Test', CEP__c = '25250536', Company = 'Heletech');
        Integer jobs = Limits.getQueueableJobs();
        Test.stopTest();
        System.assertEquals(1, jobs);
    }
    @isTest
    static void afterUpdate_cepChanged_shouldEnqueueJob() {
        Test.setMock(HttpCalloutMock.class, new EmptyMock());
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        Test.startTest();
        lead.CEP__c = '01001000';
        update lead;
        Integer jobs = Limits.getQueueableJobs();
        Test.stopTest();
        System.assertEquals(1, jobs);
    }
    @isTest
    static void afterUpdate_cepCleared_shouldNotEnqueueJob() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        Test.startTest();
        lead.CEP__c = null;
        update lead;
        Integer jobs = Limits.getQueueableJobs();
        Test.stopTest();
        System.assertEquals(0, jobs);
    }
}