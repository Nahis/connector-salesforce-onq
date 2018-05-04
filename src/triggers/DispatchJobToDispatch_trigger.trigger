trigger DispatchJobToDispatch_trigger on Case (before insert, after update, after insert) {
  if (DispatchTriggerGlobal.triggersEnabled()) {
		DispatchTriggerGlobal.disableTriggers();
	    if(trigger.isInsert) {
	    	if (trigger.isBefore) {
				for(Case extJob : Trigger.new) {
					if (extJob.ContactId == null) {
						extJob.addError('The contact must be specified.');
					}	
				}	    		
	    	}
	    	else if(trigger.isAfter) {
	    		for(Case extJob : Trigger.new) {
		            DispatchTriggerHandler.DispatchJobToDispatch(extJob, trigger.oldMap);
	    		}	
	    	}	
	    } 
	    DispatchTriggerHandler.DispatchJobToDispatch(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);

		    
   }
   DispatchTriggerGlobal.enableTriggers();   	

}