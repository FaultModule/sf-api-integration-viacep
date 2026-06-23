@isTest
private class AddressUpdaterServiceTest {

    private class Mock200 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"cep":"25250536","street":"Rua Teste","neighborhood":"Centro","city":"Petropolis","state":"RJ"}');
            return res;
        }
    }

    private class Mock404 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(404);
            return res;
        }
    }
    @TestSetup
    static void setup() {
        insert new Lead(LastName = 'Test', Company = 'Heletech', CEP__c = '25250536');
    }
    @isTest
    static void viaCepPopulateRecord_validCep_populatesFields() {
        Test.setMock(HttpCalloutMock.class, new Mock200());
        Lead lead = [SELECT Id, CEP__c FROM Lead LIMIT 1];
        Test.startTest();
        List<SObject> result = AddressUpdaterService.viaCepPopulateRecord(new List<SObject>{ lead });
        Test.stopTest();
        System.assertEquals(1, result.size());
        System.assertEquals('Petropolis', (String) result[0].get('City'));
        System.assertEquals('25250536', (String) result[0].get('PostalCode'));
        System.assertEquals('Rua Teste', (String) result[0].get('Street'));
        System.assertEquals('RJ', (String) result[0].get('StateCode'));
    }
    @isTest
    static void viaCepPopulateRecord_blankCep_skipsRecord() {
        Lead lead = [SELECT Id, CEP__c FROM Lead LIMIT 1];
        lead.CEP__c = null;
        Test.startTest();
        List<SObject> result = AddressUpdaterService.viaCepPopulateRecord(new List<SObject>{ lead });
        Test.stopTest();
        System.assertEquals(0, result.size());
    }
    @isTest
    static void viaCepPopulateRecord_integrationReturnsNull_skipsRecord() {
        Test.setMock(HttpCalloutMock.class, new Mock404());
        Lead lead = [SELECT Id, CEP__c FROM Lead LIMIT 1];
        Test.startTest();
        List<SObject> result = AddressUpdaterService.viaCepPopulateRecord(new List<SObject>{ lead });
        Test.stopTest();
        System.assertEquals(0, result.size());
    }
    @isTest
    static void viaCepUpdateLead_validCep_updatesDatabase() {
        Test.setMock(HttpCalloutMock.class, new Mock200());
        Lead lead = [SELECT Id, CEP__c FROM Lead LIMIT 1];
        Test.startTest();
        AddressUpdaterService.viaCepUpdateLead(new List<SObject>{ lead });
        Test.stopTest();
        Lead updated = [SELECT City FROM Lead WHERE Id = :lead.Id];
        System.assertEquals('Petropolis', updated.City);
    }
    @isTest
    static void viaCepUpdateLead_blankCep_doesNotUpdate() {
        Lead lead = [SELECT Id, CEP__c FROM Lead LIMIT 1];
        lead.CEP__c = null;
        Test.startTest();
        AddressUpdaterService.viaCepUpdateLead(new List<SObject>{ lead });
        Test.stopTest();
        Lead unchanged = [SELECT City FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(null, unchanged.City);
    }
}
