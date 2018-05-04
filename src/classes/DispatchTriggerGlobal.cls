global class DispatchTriggerGlobal {

	/* Boolean that determines whether or not to execute triggers */
	private static Boolean runTriggers = true;

	/* Method to disable triggers by setting boolean to false */
	global static void disableTriggers() {
		runTriggers = false;
	}

	/* Method to enable triggers by setting boolean to true */
	global static void enableTriggers() {
		runTriggers = true;
	}

	/* Method that returns the value of boolean to determine if trigger is run or not */
	global static Boolean triggersEnabled() {
		return runTriggers;
	}

}