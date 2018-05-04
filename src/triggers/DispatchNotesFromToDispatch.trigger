trigger DispatchNotesFromToDispatch on Note (after insert) {
	if (Trigger.isInsert && Trigger.isAfter) {
		if (DispatchTriggerHandler.triggersEnabled()) {
			DispatchTriggerHandler.disableTriggers();
			DispatchTriggerHandler.DispatchNoteFromToDispatch(Trigger.new);
			DispatchTriggerHandler.enableTriggers();
		}
	}  
}