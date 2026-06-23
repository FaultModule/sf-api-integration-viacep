@isTest
private class TriggerHandlerTest {

    private class EmptyMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            return new HttpResponse();
        }
    }
    @isTest
    static void run_afterInsert_dispatchesToAfterInsert() {
        Test.setMock(HttpCalloutMock.class, new EmptyMock());
        Test.startTest();
        insert new Lead(LastName = 'Test', CEP__c = '25250536', Company = 'Heletech');
        Integer jobs = Limits.getQueueableJobs();
        Test.stopTest();
        System.assertEquals(1, jobs);
    }
    @isTest
    static void run_afterUpdate_dispatchesToAfterUpdate() {
        Test.setMock(HttpCalloutMock.class, new EmptyMock());
        Lead lead = new Lead(LastName = 'Test', Company = 'Heletech', CEP__c = '01001000');
        insert lead;
        Test.startTest();
        lead.CEP__c = '25250536';
        update lead;
        Integer jobs = Limits.getQueueableJobs();
        Test.stopTest();
        System.assertEquals(1, jobs);
    }
}
