@isTest
private class AddressUpdaterIntegrationTest {

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

    private class MockCalloutError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Simulated timeout');
        }
    }

    private class MockInvalidJson implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('not valid json {{');
            return res;
        }
    }

    @isTest
    static void integration_blankCep_returnsNull() {
        AddressUpdaterIntegration.ViaCepWrapper result = AddressUpdaterIntegration.integration('');

        System.assertEquals(null, result);
    }

    @isTest
    static void integration_200Response_returnsPopulatedWrapper() {
        Test.setMock(HttpCalloutMock.class, new Mock200());

        Test.startTest();
        AddressUpdaterIntegration.ViaCepWrapper result = AddressUpdaterIntegration.integration('25250536');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('25250536', result.cep);
        System.assertEquals('Rua Teste', result.street);
        System.assertEquals('Petropolis', result.city);
        System.assertEquals('RJ', result.state);
    }

    @isTest
    static void integration_404Response_returnsNull() {
        Test.setMock(HttpCalloutMock.class, new Mock404());

        Test.startTest();
        AddressUpdaterIntegration.ViaCepWrapper result = AddressUpdaterIntegration.integration('25250536');
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @isTest
    static void integration_calloutException_returnsNull() {
        Test.setMock(HttpCalloutMock.class, new MockCalloutError());

        Test.startTest();
        AddressUpdaterIntegration.ViaCepWrapper result = AddressUpdaterIntegration.integration('25250536');
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @isTest
    static void integration_invalidJson_returnsNull() {
        Test.setMock(HttpCalloutMock.class, new MockInvalidJson());

        Test.startTest();
        AddressUpdaterIntegration.ViaCepWrapper result = AddressUpdaterIntegration.integration('25250536');
        Test.stopTest();

        System.assertEquals(null, result);
    }
}
