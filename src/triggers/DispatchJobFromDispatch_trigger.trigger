trigger DispatchJobFromDispatch_trigger on dispconn__Job__c (after update) {

  if (Trigger.isUpdate && Trigger.isAfter) {
    if (DispatchTriggerHandler.triggersEnabled()) {
      DispatchTriggerHandler.disableTriggers();
      DispatchTriggerHandler.DispatchJobFromDispatch(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
      DispatchTriggerHandler.enableTriggers();
    }
  } 
}