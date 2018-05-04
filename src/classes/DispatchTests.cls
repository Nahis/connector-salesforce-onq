@isTest
private class DispatchTests
{
      public static void createProductionSettings(String dispatchMethod) {
        Map<String,String> newSettings = new Map<String,String>();
        newSettings.put('DISPATCH_API_PROD_OR_SANDBOX','PRODUCTION');
        newSettings.put('DISPATCH_API_CLIENT_SECRET', 'asdf');
        newSettings.put('DISPATCH_API_CLIENT_ID', 'dsaf');
        newSettings.put('DISPATCH_API_PASSWORD','asfed');
        newSettings.put('DISPATCH_API_WEBHOOK_DEBUG','ON');
        newSettings.put('INTEGRATION_USER_DOMAIN','example.com');
        newSettings.put('DISPATCH_ASSIGN_METHOD', dispatchMethod);
        newSettings.put('LOGGING_KEY', 'xxx');
                
        system.assertNotEquals(newSettings, null);
        Map<String, dispconn__Dispatch_CS__c> settings = dispconn__Dispatch_CS__c.getall();
        List<dispconn__Dispatch_CS__c> updates = new List<dispconn__Dispatch_CS__c>();
        for (String key : newSettings.keySet()) {
            dispconn__Dispatch_CS__c setting = new dispconn__Dispatch_CS__c(Name=key);
            if (settings.containsKey(key)) {
              setting = settings.get(key);
            }
          setting.dispconn__Value__c = newSettings.get(key);
          updates.add(setting);
        }
        upsert updates;

      }

	public static Account createVendorAccount() {
    	String rtId = [select Id from RecordType where SObjectType = 'Account' and DeveloperName = 'Vendor'][0].Id;
    	Account a = new Account(name='Vendor',
    		                    RecordTypeId=rtId,
    		                    Email__c = 'customer@abc.com',
    		                    Phone='5552321244',
                                ShippingStreet='1 Beacon St',
                                ShippingState='MA',
                                ShippingCity='Boston',
                                ShippingPostalCode='03312');
    	system.assertNotEquals(a, null);
    	return a;
    }

    public static Account createCustomerAccount() {
    	String rtId = [select Id from RecordType where SObjectType = 'Account' and DeveloperName = 'Person'][0].Id;
    	Account a = new Account(name='Customer',
    		                    RecordTypeId=rtId,
    		                    Email__c = 'customer@abc.com',
    		                    Phone='5552321244',
    		                    First_Name__c='John',
    		                    Last_Name__c='Davis');
    	system.assertNotEquals(a, null);
    	return a;
    }

    public static Property__c createProperty() {
    	Property__c p = new Property__c(
    							   Street_Address__c='49 Marion St', 
    							   Street_Address_2__c='#2',
    							   City__c='Brookline',
    							   State__c='MA',
    							   Zip_Code__c='01581',
    							   Country__c='United States');
    	system.assertNotEquals(p, null);
    	return p;

    }

    public static WorkOrder createWO() {
    	WorkOrder wo = new WorkOrder(Description='xxx');
    	system.assertNotEquals(wo, null);
    	return wo;
    }

    public static Case createCase(String vendorId, String customerId, String propertyId) {
    	Case c = new Case(Description='xxx', Vendor__c=vendorId, AccountId=customerId, Property__c=propertyId);
    	system.assertNotEquals(c, null);
    	return c;
    }

    public static WorkOrderLineItem createWOLineItem(String woId, String caseId) {
    	WorkOrderLineItem li = new WorkOrderLineItem(WorkOrderId=woId,Job__c=caseId,
    	                                               Description='xxx', Space__c='Kitchen', Area__c='Whole Room', Vendor_Notes__c='xxx', Owner_Notes__c='xxx', Quantity=1);
    	system.assertNotEquals(li, null);
    	return li;
    }

    public static Note createNote(String jobId) {
        Note n = new Note(ParentId=jobId,
                          Title='test Note title Here',
                          Body='this is a test note body');
        
        system.assertNotEquals(n, null);
        return n;
    }
    
    public static Attachment createAttachment(String jobId) {
        Attachment att = new Attachment(ParentId=jobId,
                            Name='test Attachment here',
                            Body=Blob.valueOf('this is a test message here'));
        
        system.assertNotEquals(att, null);
        return att;
    }    

	@isTest
	static void itShould()
	{
        
        createProductionSettings('SPOFFER');
        Account vendor = createVendorAccount();
		insert vendor;

        Account customer = createCustomerAccount();
		insert customer;

		Property__c property = createProperty();
		insert property;

		WorkOrder wo = createWO();
		insert wo;

		Case cas = createCase(vendor.Id,customer.Id,property.Id);
		insert cas;

		WorkOrderLineItem li = createWOLineItem(wo.Id,cas.Id);
		insert li;

		DispatchTriggerHandler.firstRun = true;
		cas.Ready_To_Schedule__c = true;
		update cas;

        dispconn__Job__c dispJob = [SELECT Id FROM dispconn__Job__c WHERE Ext_Job__c =: cas.Id LIMIT 1][0];

        DispatchTriggerHandler.firstRun = true;        
        cas.Job_Status__c = 'Completed';
        update cas;

        DispatchTriggerHandler.firstRun = true;
        cas.Job_Status__c = 'Canceled';
        update cas;

        DispatchTriggerHandler.firstRun = false;
        update cas;

        DispatchTriggerHandler.firstRun = true;
        dispJob.dispconn__Status__c = 'Canceled';
        update dispJob;

        DispatchTriggerHandler.firstRun = true;
        dispJob.dispconn__Status__c = 'Completed';
        update dispJob;

        /*DispatchTriggerHandler.firstRun = true;
        dispJob.dispconn__Status__c = 'Enroute';
        update dispJob;*/

        DispatchTriggerHandler.firstRun = true;
        dispJob.dispconn__Status__c = 'Scheduled';
        dispJob.dispconn__Scheduled_Date__c = DateTime.now();
        dispJob.dispconn__Estimated_Duration__c = 2;
        update dispJob;

        DispatchTriggerHandler.firstRun = true;
        Note dispNote = createNote(dispJob.Id);
        insert dispNote;

        DispatchTriggerHandler.firstRun = true;
        Attachment dispAtt = createAttachment(dispJob.Id);
        insert dispAtt;


 
		//dispconn__Job__c job = [select Id from dispconn__Job__c where Ext_Job__c = :cas.Id][0];

		//system.assertNotEquals(null, job.Id);



	}
}