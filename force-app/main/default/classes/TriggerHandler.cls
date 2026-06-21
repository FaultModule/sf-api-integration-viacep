public abstract class TriggerHandler {
    
    public void run() {
        if (Trigger.isAfter) {
            if (Trigger.isInsert)this.afterInsert();
        }
    }
    protected virtual void afterInsert()   {}
}