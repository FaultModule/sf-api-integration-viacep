public with sharing class ViaCepService {
    public static void viaCepServiceIntegration() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('viacep.com.br/ws/25250597');
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        if(response.getStatusCode() == 200) {
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> animals = (List<Object>) results.get('animals');
            System.debug('Received the following animals:');
            for(Object animal: animals) {
                System.debug(animal);
            }
        }
    }
}