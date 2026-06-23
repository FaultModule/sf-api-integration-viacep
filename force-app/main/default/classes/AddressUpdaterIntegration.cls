public with sharing class AddressUpdaterIntegration {

    public static ViaCepWrapper integration(String cep) {
        if (String.isBlank(cep)) return null;
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://brasilapi.com.br/api/cep/v1/' + cep);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                return (ViaCepWrapper) JSON.deserialize(response.getBody(), ViaCepWrapper.class);
            }
            return null;
        } catch (Exception e) {
            System.debug('AddressUpdaterIntegration error: ' + e.getMessage());
            return null;
        }
    }

    public class ViaCepWrapper {
        public String cep;
        public String street;
        public String neighborhood;
        public String city;
        public String state;
    }

}