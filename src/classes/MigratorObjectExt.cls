public with sharing class MigratorObjectExt {
	private sObject mysObject;
    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    private static List<migrator__Migration_Object__c> MOList = [SELECT migrator__sObject__c, migrator__Order_Number__c FROM migrator__Migration_Object__c ORDER BY migrator__Order_Number__c DESC];


    public MigratorObjectExt(ApexPages.StandardController stdController) {
        this.mysObject = (sObject)stdController.getRecord();
        //if there is no order number already, preset the value to current value + 100
        if(this.mysObject.get('migrator__Order_Number__c') == '' || this.mysObject.get('migrator__Order_Number__c') == null) {
            this.mysObject.put('migrator__Order_Number__c', getOrderNumber());
        }
        //if this is a new record, have the active checkbox set to true by default
        if(this.mysObject.get('id') == null) {
            this.mysObject.put('migrator__Active__c', true);
        }
    }
    private static Integer getOrderNumber(){ //method to automatically populate the order number
        if(MOList.size() == 0) {
            return 100;
        } else {
            return (Integer)(MOList[0].migrator__Order_Number__c + 100);
        }
    }
    public List<SelectOption> getObjects() {
        //set to hide the values from the picklist if there is already a record existing
        Set<String> sobjectSet = new Set<String>();
        for(migrator__Migration_Object__c mo: MOList) {
            sobjectSet.add(mo.migrator__sObject__c);
        }

        List<SelectOption> options = new List<SelectOption>();
        
        //add standard objects
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        List<Schema.PicklistEntry> pickList = gd.get('ApexTrigger').getDescribe().fields.getMap().get('TableEnumOrId').getDescribe().getPicklistValues();
        for(Schema.PicklistEntry s: pickList) {
            if(s.isActive() && !sObjectSet.contains(s.getValue())){
                options.add(new SelectOption(s.getValue(), s.getValue()));
            }
        }
        //add custom objects
        for(string s: Schema.getGlobalDescribe().keySet()) {
            if(Schema.getGlobalDescribe().get(s).getDescribe().isCustom() && !sObjectSet.contains(Schema.getGlobalDescribe().get(s).getDescribe().getName())) {
                string n = Schema.getGlobalDescribe().get(s).getDescribe().getName();
                options.add(new SelectOption(n, n));
            }
        }
        
        options.sort();
        return options;
    }
}