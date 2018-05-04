public class DispatchTriggerHandler 
{
    public static boolean firstRun = true;
    private static Boolean runTriggers = true;
    /* Method to disable triggers by setting boolean to false */
    public static void disableTriggers() { runTriggers = false; }
    /* Method to enable triggers by setting boolean to true */
    public static void enableTriggers() { runTriggers = true; }
    /* Method that returns the value of boolean to determine if trigger is run or not */
    public static Boolean triggersEnabled() { return runTriggers; }
    public class spException extends Exception {}
    public class techException extends Exception {}
    public class jobException extends Exception {}    

    public static void DispatchServiceProviderToDispatch(List<Account> newList,List<Account> oldList, Map<Id,Account> newMap, Map<Id,Account> oldMap){
        if (!firstRun) { return; }
        firstRun = false;

        List<Account> newListRelevant = new List<Account>();
        Set<Id> locationIds = new Set<Id>();
        for(Account loc: newList) {
            String recordType = Account.sObjectType.getDescribe().getRecordTypeInfosById().get(loc.recordTypeID).getName();
            if (recordType == 'Vendor') {
                locationIds.add(loc.Id);
                newListRelevant.add(loc);
            }
        }        

        List<dispconn__Service_Provider__c> dispSPs = [SELECT Id, Ext_Service_Provider__c 
                                                        FROM dispconn__Service_Provider__c 
                                                        WHERE Ext_Service_Provider__c IN :locationIds];
        map<string, dispconn__Service_Provider__c> mapDispSPs = new map<string, dispconn__Service_Provider__c>();
        for(dispconn__Service_Provider__c sp: dispSPs) {
            mapDispSPs.put(sp.Ext_Service_Provider__c, sp);
        } 
        
        // Create a list for updating
        List<dispconn__Service_Provider__c> dispSPsUpdate = new List<dispconn__Service_Provider__c>();

        for (Account extSP : newListRelevant) {

            dispconn__Service_Provider__c dispSP;
            dispSP = mapDispSPs.get(extSP.Id);
            if (dispSP == Null) {
                // SP not found insert
                dispSP = new dispconn__Service_Provider__c(); 
            }    
            dispSP.Ext_Service_Provider__c = extSP.Id;   


            dispSP.Name = extSP.Name;
            dispSP.dispconn__Phone__c = extSP.Phone;
            dispSP.dispconn__Email__c = extSP.Email__c;
            dispSP.dispconn__Usage__c = 'normal';
            if (!String.isBlank(extSP.ShippingStreet) && !String.isBlank(extSP.ShippingCity) && !String.isBlank(extSP.ShippingState) && !String.isBlank(extSP.ShippingPostalCode) ) {
                dispSP.dispconn__Address_Street__c = extSP.ShippingStreet;
                dispSP.dispconn__Address_City__c = extSP.ShippingCity;
                dispSP.dispconn__Address_State__c = extSP.ShippingState;
                dispSP.dispconn__Address_Postal_Code__c = extSP.ShippingPostalCode;
                /*if (!String.isBlank(extSP.ShippingCountry)) {
                    if (extSP.ShippingCountry = 'USA') {
                        dispSP.dispconn__Address_Country__c = 'United States';
                    }
                    else {
                        dispSP.dispconn__Address_Country__c = extSP.ShippingCountry;   
                    }
                }*/
            }    
            // Add Service Provider to the list
            dispSPsUpdate.add(dispSP);            

            //dispSP.dispconn__Address_Street__c = 
            /*if (extSP... == 'DispatchLite') {
                dispSP.dispconn__Usage__c = 'lite';
            } 
            else {
                dispSP.dispconn__Usage__c = 'normal';
            }*/
        }

        // If there are Service Provider records, then apply updates
        if(dispSPsUpdate.size() > 0) {
            upsert dispSPsUpdate;
        }        
    }   

    public static void DispatchJobToDispatch(List<Case> newList,List<Case> oldList, Map<Id,Case> newMap, Map<Id,Case> oldMap){
        if (!firstRun) { return; }
        firstRun = false;

        Set<Id> jobIds = new Set<Id>();    
        Set<Id> accountIds = new Set<Id>();    
        Set<Id> locationIds = new Set<Id>();    
        Set<Id> propertyIds = new Set<Id>();    
        List<Case> newListRelevant = new List<Case>();
        for(Case cas: newList) {
            if (cas.Ready_To_Schedule__c) {
                jobIds.add(cas.Id);
                newListRelevant.add(cas);
                if (cas.Vendor__c != null) {
                    locationIds.add(cas.Vendor__c);
                }   
                if (cas.AccountId != null) {
                    accountIds.add(cas.AccountId);
                }     
                if (cas.Property__c != null) {
                    propertyIds.add(cas.Property__c);
                }                                     
            }
        }       

        if (newListRelevant.size() > 0 ) {
            List<dispconn__Job__c> dispJobs = [SELECT Id, Ext_Job__c, dispconn__Field_Tech__c FROM dispconn__Job__c WHERE Ext_Job__c IN :jobIds];
            map<string, dispconn__Job__c> mapDispJobs = new map<string, dispconn__Job__c>();
            for(dispconn__Job__c j: dispJobs) {
                mapDispJobs.put(j.Ext_Job__c, j);
            }             

            List<dispconn__Service_Provider__c> dispSPs = [SELECT Id, Ext_Service_Provider__c 
                                                           FROM dispconn__Service_Provider__c 
                                                           WHERE Ext_Service_Provider__c IN :locationIds];
            map<string, dispconn__Service_Provider__c> mapDispSPs = new map<string, dispconn__Service_Provider__c>();
            for(dispconn__Service_Provider__c sp: dispSPs) {
                mapDispSPs.put(sp.Ext_Service_Provider__c, sp);
            }

            List<Account> accounts = [SELECT Name, First_Name__c, Last_Name__c, Phone,Email__c
                                       FROM Account WHERE Id IN :accountIds];
            map<Id, Account> mapAccounts = new map<Id, Account>(accounts);            

            List<Property__c> properties = [SELECT Name,Street_Address__c, Street_Address_2__c, City__c, State__c, Zip_Code__c, Country__c
                                            FROM Property__c WHERE Id IN :propertyIds];
            map<Id, Property__c> mapProperties = new map<Id, Property__c>(properties);

            List<WorkOrderLineItem> lineItems = [SELECT Job__c, WorkOrder.Description,Description,Space__c,Area__c,Vendor_Notes__c,Owner_Notes__c,Quantity,PriceBookEntry.Name
                                                   FROM WorkOrderLineItem WHERE Job__c IN :jobIds];

            List<dispconn__Job__c> dispJobsUpdate = new List<dispconn__Job__c>();

            for (Case extJob : newListRelevant) {
                try {
                    dispconn__Job__c dispJob;
                    dispJob = mapDispJobs.get(extJob.Id);
                    if (dispJob == Null) {
                        // job not found insert
                        dispJob = new dispconn__Job__c();
                        dispJob.dispconn__Status__c = 'New';
                    }
                    dispJob.Ext_Job__c = extJob.Id;
                    dispJob.dispconn__Last_Sync_Response__c = 'Pending Sync:'+DateTime.now();
                    dispJob.dispconn__Synced__c = False;    

                    dispconn__Service_Provider__c sp = mapDispSPs.get(extJob.Vendor__c);
                    if (sp == null) {  // not a valid dispatch territory
                        throw new jobException('Dispatch: not a valid dispatch territory 2');
                    }                        
                    dispJob.dispconn__Service_Provider__c = sp.Id;                                                    

                    /* CONTACT NAME, EMAIL AND PHONE */
                    try {
                        Account account = mapAccounts.get(extJob.AccountId);                    
                        if (string.isBlank(account.First_Name__c) && string.isBlank(account.Last_Name__c)) {
                            dispJob.dispconn__First_Name__c = account.Name;
                        } else {
                            dispJob.dispconn__First_Name__c = account.First_Name__c;
                            dispJob.dispconn__Last_Name__c = account.Last_Name__c;
                        }
                        if (!String.isBlank(account.Phone)) {
                            dispJob.dispconn__Mobile__c = account.Phone;
                        }
                        if (!String.isBlank(account.Email__c)) {
                            dispJob.dispconn__Email__c = account.Email__c;
                        }
                    }
                    catch (Exception ex) {
                        extJob.addError('Dispatch: Account must be assigned');
                    }       

                    /* JOB ADDRESS */
                    Property__c property;
                    try {
                        property = mapProperties.get(extJob.Property__c);     
                    }
                    catch (Exception ex) {
                        extJob.addError('Dispatch: Property must be assigned');
                    }               
                    dispJob.dispconn__Title__c = extJob.CaseNumber + ':' + property.Name;
                    dispJob.dispconn__Address_Street__c = property.Street_Address__c;
                    if (!String.isBlank(property.Street_Address_2__c)) {
                        dispJob.dispconn__Address_Street__c += '\n' + property.Street_Address_2__c;
                    }    
                    dispJob.dispconn__Address_City__c = property.City__c;
                    dispJob.dispconn__Address_State__c = property.State__c;
                    dispJob.dispconn__Address_Postal_Code__c = property.Zip_Code__c;
                    if (!String.isBlank(property.Country__c)) {
                        if (property.Country__c == 'USA' ) {
                            dispJob.dispconn__Address_Country__c = 'United States';  //This is done because spelling needs to be exact. If there are other variations
                        } 
                        else {
                            dispJob.dispconn__Address_Country__c = property.Country__c;
                        }
                    }
                            
                    /* JOB DESCRIPTION */
                    String descr = '';
                    if (!String.isBlank(extJob.Description)) {
                        descr += '\n* Case Description: ' + extJob.Description;
                    }
                    Boolean firstLine = true;
                    //for (WorkOrderLineItem li: [SELECT WorkOrder.Description, 
                    //                                 Description, Space__c, Area__c, Vendor_Notes__c, Owner_Notes__c, Quantity, PriceBookEntry.Name
                    //                            FROM WorkOrderLineItem where Job__c =: extJob.Id]) {
                    For (WorkOrderLineItem li : lineItems) {
                        if (li.Job__c == extJob.Id) {          // could be made slightly more efficient using a nested map          
                            if (firstLine) {
                                if (!String.isBlank(li.WorkOrder.Description)) {
                                    descr += '\n* Work Order Description: ' + li.WorkOrder.Description + '\n';
                                }    
                                firstLine = false;

                            }
                            if (!String.isBlank(li.Description)) {
                                descr += '\n* Line Item: ' + li.Description;
                            }    
                            if (li.Quantity != null) {
                                descr += '\n    * Quantity: ' + li.Quantity;
                            }    
                            if (!String.isBlank(li.Space__c)) {
                                descr += '\n    * Space: ' + li.Space__c;
                            }    
                            if (!String.isBlank(li.Area__c)) {
                                descr += '\n    * Area: ' + li.Area__c;
                            }    
                            if (!String.isBlank(li.Vendor_Notes__c)) {
                                descr += '\n    * Vendor Notes: ' + li.Vendor_Notes__c;
                            }    
                            if (!String.isBlank(li.Owner_Notes__c)) {
                                descr += '\n    * Owner Notes: ' + li.Owner_Notes__c;
                            }    
                        }    
                    }
                    dispJob.dispconn__Description__c = descr;

                    /* TITLE, SERVICE TYPE ETC. */
                    if (!String.isBlank(extJob.Type)) {
                        dispJob.dispconn__Service_Type__c = extJob.Type;
                    }    

                    /* LINK TO Job__c */
                    dispJob.Ext_Job__c = extJob.Id;

                    if (oldMap == null || (extJob.Job_Status__c != oldMap.get(extJob.Id).Job_Status__c)) {
                        if (extJob.Job_Status__c == 'Completed') {
                            dispJob.dispconn__Status__c = 'Completed';
                        }
                        else if (extJob.Job_Status__c == 'Canceled') { 
                            dispJob.dispconn__Status__c = 'Canceled';
                        }           
                        else if (oldMap != null) {
                            extJob.addError('Dispatch: Job Status can only be changed to Completed or Canceled.');
                        }
                        /*else if (extJob.Job_Status__c == 'Open') {
                            
                            if (oldMap == null || (extJob.Scheduled_Date_Time__c != oldMap.get(extJob.Id).Scheduled_Date_Time__c || 
                                                   extJob.Service_Duration__c != oldMap.get(extJob.Id).Service_Duration__c )) {

                                dispJob.dispconn__Status__c = 'Scheduled';
                                dispJob.dispconn__Scheduled_Date__c = extJob.Scheduled_Date_Time__c;
                                dispJob.dispconn__Estimated_Duration__c = extJob.Service_Duration__c/60/60; 
                            }   
                            
                        }  */             
                    }    
                    dispJobsUpdate.add(dispJob);
                } catch (jobException e) {
                    System.debug('Dispatch: updateJob exception: '+e.getMessage());
                }                    
            }  
            if (!dispJobsUpdate.isEmpty()) {
                upsert dispJobsUpdate;
                // now set up the inverse relationship
                List<Case> extJobsUpdate = new List<Case>();
                for (dispconn__Job__c dispJob : dispJobsUpdate) {
                    Case extJob = new Case(Id=dispJob.Ext_Job__c,Job__c=dispJob.Id);
                    extJobsUpdate.add(extJob);
                }
                if (!extJobsUpdate.isEmpty()) {
                    update extJobsUpdate;
                }                  
            }              
        }    
    }  

    public static void DispatchJobFromDispatch(List<dispconn__Job__c> newList,List<dispconn__Job__c> oldList, Map<Id,dispconn__Job__c> newMap, Map<Id,dispconn__Job__c> oldMap){
        if (!firstRun) { return; }
        firstRun = false;

        List<Case> extJobsUpdate = new List<Case>();
        for(dispconn__Job__c dispJob: newList) {        
            /*if (dispJob.Ext_Job__c == null) {
              try {
                extJob = [SELECT Id from Case WHERE Dispatch_Job__c =: dispJob.Id LIMIT 1][0];
              }
              catch (Exception e) {
                extJob = new Case(); 
                extJob.Status = 'Open';
              }          
            }
            else {
            */    
            Case extJob = new Case(Id=dispJob.Ext_Job__c);
            //} 

            // handle job being rescinded from external source
            if (dispJob.dispconn__Status__c == 'Canceled' && 
               (oldMap == null || (dispJob.dispconn__Status__c != oldMap.get(dispJob.Id).dispconn__Status__c))) { 
                extJob.Job_Status__c = 'Canceled';
            }
            else if (dispJob.dispconn__Status__c == 'Scheduled') { 
                extJob.Job_Status__c = 'Scheduled';
              // if schedule has changed
              /*if (oldMap == null || (dispJob.dispconn__Scheduled_Date__c != oldMap.get(dispJob.Id).dispconn__Scheduled_Date__c || 
                                    dispJob.dispconn__Estimated_Duration__c != oldMap.get(dispJob.Id).dispconn__Estimated_Duration__c) 
                                 // || dispJob.dispconn__Field_Tech__c != oldMap.get(dispJob.Id).dispconn__Field_Tech__c 
                 ) {

                  if (dispJob.dispconn__Dispatch_Job_Id__c != null) {
                    if (dispJob.dispconn__Dispatch_Last_Appointment_ID__c == null && (dispJob.dispconn__Scheduled_Date__c != null && 
                        dispJob.dispconn__Estimated_Duration__c != null)) {
                      extJob.Scheduled_Date_Time__c = dispJob.dispconn__Scheduled_Date__c;
                      extJob.Service_Duration__c = dispJob.dispconn__Estimated_Duration__c;
                    } else if (dispJob.dispconn__Dispatch_Last_Appointment_ID__c != null) {
                      extJob.Scheduled_Date_Time__c = dispJob.dispconn__Scheduled_Date__c;
                      extJob.Service_Duration__c = dispJob.dispconn__Estimated_Duration__c;
                    }
                  } 
              }*/

            }
            else if (dispJob.dispconn__Status__c == 'Completed' && 
               (dispJob.dispconn__Status__c != oldMap.get(dispJob.Id).dispconn__Status__c)) { 
                extJob.Job_Status__c = 'Completed';
            }    
            else if (oldMap == null || (dispJob.dispconn__Status__c != oldMap.get(dispJob.Id).dispconn__Status__c)) { 
                extJob.Job_Status__c = dispJob.dispconn__Status__c;
            }    
            extJobsUpdate.add(extJob);
        }   
        if (!extJobsUpdate.isEmpty()) {
            upsert extJobsUpdate;
        }                 
    }

    public static void DispatchNoteFromToDispatch(List<Note> newList){
        if (!firstRun) { return; }
        firstRun = false;
        
        // Gather Note Parent Ids 
        map<string, Note> mapDispNotes = new map<string, Note>();
        map<string, Note> mapExtNotes = new map<string, Note>();
        for(Note note: newList) {
            if (note.Id != Null && note.ParentId != Null) {
                Schema.sObjectType entityType = note.parentId.getSObjectType();
                system.debug('Note Entity: '+entityType);
                if (entityType == dispconn__Job__c.sObjectType) {
                    mapDispNotes.put(note.ParentId, note);
                }
                if (entityType == Case.sObjectType) {
                    mapExtNotes.put(note.ParentId, note);
                }                
            }
        }
        if (mapDispNotes.size()>0) {
            // Get Dispatch Job records based on Note Parent Ids
            List<dispconn__Job__c> dispJobs = [SELECT Ext_Job__c FROM dispconn__Job__c WHERE Id IN :mapDispNotes.KeySet()];
            List<Note> extNoteList = new List<Note>();  

            // This section copies notes from the Dispatch job to the source job
            for(dispconn__Job__c dj: dispJobs) {
                // Go back and get the Note record
                Note dispNote = mapDispNotes.get(dj.Id);
                
                Note n = new Note();
                n.ParentId = dj.Id;
                n.Title = dispNote.Title;
                n.Body = dispNote.Body;

                // Add new Note to the list
                extNoteList.add(n);            
            }
            if(extNoteList.size() > 0) {
                insert extNoteList;
            }            
        }    

        if (mapExtNotes.size()>0) {

            // Get Source Job records based on Note Parent Ids
            List<dispconn__Job__c> extJobs = [SELECT Id FROM dispconn__Job__c WHERE Ext_Job__c IN :mapExtNotes.KeySet()];
            List<Note> dispNoteList = new List<Note>();

            // This section copies notes from the source job to the Dispatch job
            for(dispconn__Job__c ej: extJobs) {
                // Go back and get the Note record
                Note extNote = mapExtNotes.get(ej.Ext_Job__c);
                Note n = new Note();
                n.ParentId = ej.Ext_Job__c;
                n.Title = extNote.Title;
                n.Body = extNote.Body;

                // Add new Note to the list
                dispNoteList.add(n);            
            }        
            if(dispNoteList.size() > 0) {
                insert dispNoteList;
            }     
        }       
    }    
}