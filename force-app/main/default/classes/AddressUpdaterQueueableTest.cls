@isTest
private class AddressUpdaterQueueableTest {

    private class Mock200 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"cep":"25250536","street":"Rua Teste","neighborhood":"Centro","city":"Petropolis","state":"RJ"}');
            return res;
        }
    }
    @isTest
    static void execute_withLeads_updatesAddressFields() {
        Test.setMock(HttpCalloutMock.class, new Mock200());
        Lead lead = new Lead(LastName = 'Test', Company = 'Heletech', CEP__c = '25250536');
        insert lead;
        List<SObject> leads = [SELECT Id, CEP__c FROM Lead WHERE Id = :lead.Id];
        Test.startTest();
        System.enqueueJob(new AddressUpdaterQueueable(leads));
        Test.stopTest();
        Lead result = [SELECT City FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('Petropolis', result.City);
    }
    @isTest
    static void execute_withEmptyList_doesNotUpdateRecords() {
        Lead lead = new Lead(LastName = 'Test', Company = 'Heletech', CEP__c = '25250536');
        insert lead;
        Test.startTest();
        System.enqueueJob(new AddressUpdaterQueueable(new List<SObject>()));
        Test.stopTest();
        Lead result = [SELECT City FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(null, result.City);
    }
}
