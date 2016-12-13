global with sharing class MigratorComparator {
	public MigratorComparator() {
		
	}
	public static String s = 'migrator__Migration_Object__c';
//TODO create a scenario - that is tied to an org and series of objects
	public PageReference Save() {
		List<migrator__Object_Mapping__c> ObjectMappingList = new List<migrator__Object_Mapping__c>();
		for(sObjectWrapper tmpWrapper: SourceSobjects) {
			if(tmpWrapper.Selected || tmpWrapper.RecordId != null) {
				ObjectMappingList.add(new migrator__Object_Mapping__c(
					Id = tmpWrapper.RecordId,
					migrator__Migration_Order_Number__c = tmpWrapper.OrderNumber,
					migrator__Source_Object_Name__c = tmpWrapper.Name,
					migrator__Source_Object_Namespace__c = tmpWrapper.NameSpace,
					migrator__Active__c = tmpWrapper.Selected
				));
			}
		}
		upsert ObjectMappingList;
		return null;
	}
	global class sObjectWrapper implements Comparable{
		public Boolean Selected {get; set;}
		public String Name {get; set;}
		public String NameSpace {get; set;}
		public Decimal OrderNumber {get; set;}
		public Id RecordId {get; set;}
		public sObjectWrapper(String NameValue, Boolean selectedValue, String NameSpaceValue, Decimal OrderNumberValue, Id RecordIdValue) {
			Name = nameValue;
			Selected = SelectedValue;
			NameSpace = NameSpaceValue;
			OrderNumber = OrderNumberValue;
			RecordId = RecordIdValue;
		}
		public sObjectWrapper(String NameValue, Boolean selectedValue, String NameSpaceValue, Decimal OrderNumberValue) {
			Name = nameValue;
			Selected = SelectedValue;
			NameSpace = NameSpaceValue;
			OrderNumber = OrderNumberValue;
		}
		public sObjectWrapper(String NameValue, Boolean selectedValue, String NameSpaceValue) {
			Name = nameValue;
			Selected = SelectedValue;
			NameSpace = NameSpaceValue;
		}
		public sObjectWrapper(String NameValue, Boolean selectedValue) {
			Name = nameValue;
			Selected = SelectedValue;
		}
		public sObjectWrapper(String NameValue) {
			Name = nameValue;
		}
		public sObjectWrapper() {
		
		}
	    // Implement the compareTo() method
	    global Integer compareTo(Object compareTo) {
	        sObjectWrapper compareToWrapper = (sObjectWrapper)compareTo;
	        if(NameSpace < compareToWrapper.NameSpace) { 
	        	return -1;
	        } else if(NameSpace > compareToWrapper.NameSpace) { 
	        	return 1;
	        } else {
		        if (Name == compareToWrapper.Name) { 
		        	return 0;
	        	} else if (Name > compareToWrapper.Name) {
	        		return 1;	
        		} 
	        }
	        return -1;        
	    }
	}
	
	public List<sObjectWrapper> SourceSobjects { get{ 
		if(SourceSobjects == null) {
			Map<String, migrator__Object_Mapping__c> sObjectMap = new Map<String, migrator__Object_Mapping__c>();
			for(migrator__Object_Mapping__c	 tmpSobj: [SELECT Id, migrator__Migration_Order_Number__c, migrator__Source_Object_Name__c, migrator__Source_Object_Namespace__c FROM migrator__Object_Mapping__c]) {
				String ObjString; //migrator__Source_Object_Namespace__c
				if(tmpSobj.migrator__Source_Object_Namespace__c != '' && tmpSobj.migrator__Source_Object_Namespace__c != null) {
					ObjString = tmpSobj.migrator__Source_Object_Namespace__c + '__' + tmpSobj.migrator__Source_Object_Name__c;
				} else {
					ObjString = tmpSobj.migrator__Source_Object_Name__c;
				}
				sObjectMap.put(ObjString, tmpSobj);
			}

	        List<sObjectWrapper> sObjList = new List<sObjectWrapper>();
	        MetadataService.MetadataPort service = createService();
	        List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();
	        MetadataService.ListMetadataQuery queryCustomObject = new MetadataService.ListMetadataQuery();
	        queryCustomObject.type_x = 'CustomObject';
	        queries.add(queryCustomObject);
	        MetadataService.FileProperties[] fileProperties = service.listMetadata(queries, 37);
	        for(MetadataService.FileProperties fileProperty : fileProperties) {
	        	String ObjString;
	        	sObjectWrapper sObj;
	        	if(fileProperty.namespacePrefix != '' && fileProperty.namespacePrefix != null) {
	        		ObjString = fileProperty.namespacePrefix + '__' + fileProperty.fullName;
	        	} else {
	        		ObjString = fileProperty.fullName;
	        	}
	        	if(sObjectMap.get(ObjString) != null) {
	        		migrator__Object_Mapping__c tmpSobj = sObjectMap.get(ObjString);
					sObj = new sObjectWrapper(fileProperty.fullName, true, fileProperty.namespacePrefix, tmpSobj.migrator__Migration_Order_Number__c, tmpSobj.Id);
	    		} else {
	    			sObj = new sObjectWrapper(fileProperty.fullName, false, fileProperty.namespacePrefix);
	    		}
	        	sObjList.add(sObj);
	        }
	        sObjList.sort();
	        SourceSobjects = sObjList;
        }
    	return SourceSobjects;
	} set; }

    public static MetadataService.MetadataPort createService() { //no sessionId is currentOrg
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;
    }
    public static MetadataService.MetadataPort createService(String sessionId) { 
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = sessionId;
        return service;
    }
    public static MetadataService.CustomObject readCustomObject(String objName) {
        MetadataService.MetadataPort service = createService();

        MetadataService.CustomObject customObject =
            (MetadataService.CustomObject) service.readMetadata('CustomObject',
                new String[] { objName }).getRecords()[0];
        /*for(MetadataService.CustomField field : customObject.fields)
            System.debug(field.fullName);*/
        return customObject;
    }
    public static List<MetadataService.CustomObject> readCustomObject(List<String> objName) {
        MetadataService.MetadataPort service = createService();

        List<MetadataService.CustomObject> customObjectList =
            (List<MetadataService.CustomObject>) service.readMetadata('CustomObject',
                objName).getRecords();
        /*for(MetadataService.CustomField field : customObject.fields)
            System.debug(field.fullName);*/
        return customObjectList;
    }
	public class Org {
		//TODO setup authorization and endpoint to make it configuration driven
		private String username = 'tim.barsotti.dev4@gmail.com';
		private String password = 'Vampires1e5Ob9GGYLrBOK0ohiCXxPj2wx';
		private String endpoint = 'https://na30.salesforce.com';
		public String TargetSessionId; //{get {if(TargetSessionId == null) {getAuthorizationToken();} return TargetSessionId;} set;}
		public void getAuthorizationToken() {
			try {
				ToolingAPIWSDL t = new ToolingAPIWSDL();
				ToolingAPIWSDL.SforceService conn = new ToolingAPIWSDL.SforceService();
				conn.endpoint_x = endpoint + '/services/Soap/T/33.0';
				ToolingAPIWSDL.LoginResult lr = conn.login(username, password);
				if(lr.passwordExpired) {
					//TODO throw error that password is expired
				}
				TargetSessionId = lr.SessionID;
			} catch (exception e) {
				//TODO error handling
			}
		}
	}
	public String getTargetObject() {
		HttpRequest req = new HttpRequest();
        Http http = new Http();
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint('https://na30.salesforce.com/services/data/v36.0/sobjects/'+ s + '/describe/fields');
        req.setMethod('GET');
        HTTPResponse res = http.send(req);  

        System.debug(res.toString());
        return res.getBody();
	}
	public String getSourceObject() {
		return String.ValueOf(Schema.getGlobalDescribe().get(s).getDescribe());
	}
	public Boolean getObjectsAreTheSame() {
		String target = getTargetObject();
		String source = getSourceObject();
		if(target == source) {
			return true;
		} else {
			return false;
		}
	}
  
}