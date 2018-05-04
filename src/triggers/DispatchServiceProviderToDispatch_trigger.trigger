trigger DispatchServiceProviderToDispatch_trigger on Account (before insert, after insert, after update) {
  if (DispatchTriggerGlobal.triggersEnabled()) {
		DispatchTriggerGlobal.disableTriggers();
	    if(trigger.isBefore) {
	    	if(trigger.isAfter) {
				for(Account extSP : Trigger.new) {
					String recordType = Account.sObjectType.getDescribe().getRecordTypeInfosById().get(extSP.recordTypeID).getName();
					if (recordType == 'Vendor') {						
						if (extSP.Phone == null || extSP.Email__c == null) {
							extSP.addError('The account must have an email and phone specified.');
						} 
					}	
				}
	    	}	
		} else if (Trigger.isAfter) {
			DispatchTriggerHandler.DispatchServiceProviderToDispatch(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
		}
   }
   DispatchTriggerGlobal.enableTriggers();   

}