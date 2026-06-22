public abstract class TriggerHandler {
    
    public void run() {
        if (Trigger.isAfter) {
            if (Trigger.isInsert)this.afterInsert();
            if (Trigger.isUpdate)this.afterUpdate();
        }
    }
    protected virtual void afterInsert()   {}
    protected virtual void afterUpdate()   {}
}