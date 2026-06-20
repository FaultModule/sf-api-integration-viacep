public class ViaCepQueueable implements Queueable, Database.AllowsCallouts {
    private List<Lead> leads;

    public ViaCepQueueable(List<Lead> leads) {
        this.leads = leads;
    }

    public void execute(QueueableContext context) {
        ViaCepService.viaCepUpdateLead(leads);
    }
}