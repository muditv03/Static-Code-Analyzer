/*******************************************************************************************
* @Name         CPQCorpLegalTemplateController
* @Author       Yogeshwari Sharma
* @Description  Controller class for corpLegalContractTemplate
*******************************************************************************************/


public with sharing class CPQCorpLegalTemplateController {

      //Method to Initialize and render the Quote Data
    public String getRender() {
        init();
        return null;
    }
    
    // Wrapper for the quote record
    public QuoteWrapper quoteRec{get;set;}
    public String recordId{get;set;}
    public static String bundle{get;set;}
    public String region{ get; private set; }
    
    // Constructor that initializes the controller
    public CPQCorpLegalTemplateController(){
        init();
    }
    
    
 
    
    // Initializes the quote record and bundle information from the page parameters.
    public void init(){
        
        if(recordId == null){
            recordId = apexpages.currentpage().getparameters().get('qid'); 
            bundle = apexpages.currentpage().getparameters().get('bundle'); 
            region = apexPages.currentPage().getParameters().get('region');
        }
        // If a valid record ID is available, query the quote record,related line items and Add On Services
        if(recordId != null){
            quoteRec = new QuoteWrapper([
                SELECT Id,Account_Customer_Number__c ,Financial_Account_Number__c,SBQQ__Opportunity2__c,Name,SBQQ__Account__r.Customer_Class__c,SBQQ__Account__r.name,SBQQ__Account__r.Customer_Number__c,Account_Name__c, End_Free_Time__c,Start_Free_Time__c,Free_Time__c,SBQQ__FirstSegmentTermEndDate__c ,Account_Number__c,
                SBQQ__StartDate__c,Programs_and_Promos1__c,Term_Type__c,GCA_Start_Date__c,Has_GCA__c,SBQQ__BillingStreet__c,SBQQ__BillingCity__c,SBQQ__BillingState__c,SBQQ__BillingCountry__c,SBQQ__BillingPostalCode__c,SBQQ__RenewalTerm__c,AAR__c,SBQQ__PrimaryContact__c,SBQQ__PrimaryContact__r.Name,SBQQ__SubscriptionTerm__c, SBQQ__EndDate__c, 
                SBQQ__PrimaryContact__r.Email, SBQQ__PrimaryContact__r.Phone,SBQQ__PrimaryContact__r.MailingStreet,SBQQ__PrimaryContact__r.MailingCity,SBQQ__PrimaryContact__r.MailingState,SBQQ__PrimaryContact__r.MailingCountry,SBQQ__PrimaryContact__r.MailingPostalCode,Financial_Account_Name__r.VAT_Registration__c,
                
                (Select Id,SBQQ__Product__r.Name,SBQQ__Product__r.StockKeepingUnit, SBQQ__Quantity__c,  CurrencyIsoCode , SBQQ__Product__r.Product_Id__c,SBQQ__Product__r.ProductCode,SBQQ__SegmentIndex__c, SBQQ__StartDate__c  , SBQQ__RequiredBy__r.SBQQ__ProductCode__c,SBQQ__ProductCode__c, Users__c,Bronze__c,Platinum__c,Gold__c,Silver__c,Total_Investigations__c,Total_UBO_Docs__c,Total_Public_Record_Events__c,
                SBQQ__EndDate__c ,SBQQ__NetTotal__c,SBQQ__SegmentLabel__c, Feature__c, SBQQ__Description__c  ,Bundle_Name__c, Product_Id__c  , Net_Monthly__c   , SBQQ__ProductName__c , SBQQ__Product__r.Contract_Section__c, Prod_Code_with_Prod_Name__c,SBQQ__Hidden__c,Number_of_Tracks__c, Product_Option_Feature__c,SBQQ__ProductFamily__c, product_class__c,
                Add_On_Additional_Tracks__c,Add_On_Additional_Users__c,Newsdesk_Users__c,Total_Number_Permitted_per_Account__c,K_12_State_Content_Only__c,SBQQ__Product__r.SBQQ__SubscriptionType__c,Total_PR_Event_Usage_Allocation__c,Total_Doc_Access_Usage_Allocation__c , Total_Downloads__c, Nexis_Wealth_Navigator_User__c,Additional_Credits__c from SBQQ__LineItems__r WHERE Excluded__c = False and Bundle_Name__c != null and SBQQ__Product__r.Product_Id__c NOT IN ('1525172', '1530463', '1546617')  order by SBQQ__StartDate__c asc ),
                
                (SELECT Id,Product_Name__c,RecordType.Name, Additional_Allocation__c,Add_On_Monthly_Commitment__c,Quantity__c,SKU_Number__c,Add_On_User_Monthly_Rate__c,No_of_Investigation__c,No_of_Public_Record_Events__c,No_of_Users__c,No_of_UBO_Documents__c,Committed_Term__c,Monthly_License_Fee__c,Additional_Credits__c,Total_Monthly_Commitment__c,Total_One_Time_Charges__c FROM Add_On_Services__r)
                
                FROM SBQQ__Quote__c WHERE Id = :recordId LIMIT 1 ]);
        }
        
  
    }
    
    /*******************************************************************************************
* @Name         QuoteWrapper 
* @Author       Yogeshwari Sharma
* @Description  Wrapper Class for encapsulating quote data, line items and add-on services.
*******************************************************************************************/
    
    
    
    
    public Class QuoteWrapper{
        
        @AuraEnabled public String AccountCustomerClass{get;set;}
        @AuraEnabled public String AccountName{get;set;}
        @AuraEnabled public String CustomerNumber{get;set;}
        @AuraEnabled public String termType{get;set;}
        @AuraEnabled public Boolean isFixedTerm{get;set;}
        @AuraEnabled public Boolean isAAR{get;set;}  
        @AuraEnabled public Decimal SubscriptionTerm{get;set;}    
        @AuraEnabled public String QuoteStartDate{get;set;}
        @AuraEnabled public String QuoteEndDate{get;set;}
        @AuraEnabled public SBQQ__Quote__c quoteRec{get;set;}
        @AuraEnabled public List<ProductList> lstProducts{get;set;}
        @AuraEnabled public List<ProductList> lstProductsCorporateAndAcademic{get;set;}
        @AuraEnabled public boolean isNDPBundle{get;set;}
        @AuraEnabled public List<ProductList> lstTopFiveProductsCorporateAndAcademic { get; set; }
        @AuraEnabled public List<ProductList> lstRemainingProductsCorporateAndAcademic { get; set; }
        @AuraEnabled public List<ProductList> lstTopFiveProducts { get; set; }
        @AuraEnabled public List<ProductList> lstRemainingProducts { get; set; }
        @AuraEnabled public List<ProductList> lstOneTimeProducts { get; set; }
        @AuraEnabled public List<ProductList> lstWealthNexisOneTimeProducts { get; set; }
        @AuraEnabled public Integer totalInvestigations{get;set;}
        @AuraEnabled public Integer totalUBODocs{get;set;}
        @AuraEnabled public Integer totalDocAccessUsageAllocation{get;set;}
        @AuraEnabled public Integer totalPREventUsageAllocation{get;set;}
        @AuraEnabled public Integer totalNDPDocAccessUsageAllocation{get;set;}
        @AuraEnabled public Integer totalNDPPREventUsageAllocation{get;set;}
        @AuraEnabled public Integer totalNDPDownloadCredits{get;set;}
        @AuraEnabled public Integer CurrencySymbol{get;set;}
        @AuraEnabled public Integer totalPublicRecordEvents{get;set;} 
        @AuraEnabled public Integer trackDescription{get;set;}
        @AuraEnabled public Integer numberAdded{get;set;}
        @AuraEnabled public Decimal oneTimeProductFee{get;set;}
        @AuraEnabled public Decimal oneTimeNWProductFee{get;set;}
        List<SBQQ__QuoteLine__c> allQuoteLines = new List<SBQQ__QuoteLine__c>();
        @AuraEnabled public Boolean isTermTypeAAR { get; set; }
        @AuraEnabled public String contactName { get; set; }
        @AuraEnabled public String contactEmail { get; set; }
        @AuraEnabled public String contactPhone { get; set; }
        @AuraEnabled public String contactMailingAddress { get; set; }
        @AuraEnabled public String legalContactName { get; set; }
        @AuraEnabled public String legalContactEmail { get; set; }
        @AuraEnabled public String legalContactPhone { get; set; }
        @AuraEnabled public String legalContactMailingAddress { get; set; }
        @AuraEnabled public String billingContactName { get; set; }
        @AuraEnabled public String billingContactEmail { get; set; }
        @AuraEnabled public String billingContactPhone { get; set; }
        @AuraEnabled public String billingContactMailingAddress { get; set; }
        @AuraEnabled public String credentialContactName { get; set; }
        @AuraEnabled public String credentialContactEmail { get; set; }
        @AuraEnabled public String credentialContactPhone { get; set; }
        @AuraEnabled public String credentialContactMailingAddress { get; set; }
        @AuraEnabled public String billingStreet { get; set; }
        @AuraEnabled public String billingCity { get; set; }
        @AuraEnabled public String billingState { get; set; }
        @AuraEnabled public String billingCountry { get; set; }
        @AuraEnabled public String billingPostalCode { get; set; }
        @AuraEnabled public String accCustNumber { get; set; }
        @AuraEnabled public String faNumber { get; set; }
        @AuraEnabled public String faVATRegistration { get; set; }
        @AuraEnabled public Decimal renewalTerm { get; set; }
        @AuraEnabled public Decimal percentAAR { get; set; }
        @AuraEnabled public Boolean haveTransactionalAccess { get; set; }
        @AuraEnabled public String gcaStartDate { get; set; }
        @AuraEnabled public String bundleName { get; set; }
        @AuraEnabled public Boolean hasGCA { get; set;}
        @AuraEnabled public String currencyIsoCode { get; set;}
        @AuraEnabled public List<LineItems> lstSub{get;set;}
        @AuraEnabled public List<ProductList> courtlinkProductList { get; set; }
        @AuraEnabled public List<LineItems> courtlinkProductListCurrency{get;set;}
        @AuraEnabled public List<ProductList> diligenceProductList { get; set; }
        @AuraEnabled public List<ProductList> LAW360ProductList { get; set; }
        @AuraEnabled public List<ProductList> MLEXProductList { get; set; }
        @AuraEnabled public List<ProductList> LEXMachinaProductList { get; set; }
        @AuraEnabled public List<ProductList> LEXMachinaAPIProductList { get; set; }
        @AuraEnabled public List<ProductList> CreateProductList { get; set; }
        @AuraEnabled public List<ProductList> CreateDMSProductList { get; set; }
        
        

        
        
        // Constructor to initialize QuoteWrapper with quote record
        public QuoteWrapper(SBQQ__Quote__c quoteRec){
            try{
                this.quoteRec = quoteRec;
                initializeFields();  
                Map<String,List<SBQQ__QuoteLine__c>> lineItemsByDate = new Map<String,List<SBQQ__QuoteLine__c>>();
                 for(SBQQ__QuoteLine__c ql : quoteRec.SBQQ__LineItems__r){
                   processQuoteLine(ql,lineItemsByDate);
                    //Adding All Quoteline in this list
                    this.allQuoteLines.add(ql);
                }
                                
                if(!allQuoteLines.isEmpty()){
                    calculateTotals(allQuoteLines); // Calling calculateTotals
                }
              populateLineItemsList(lineItemsByDate); // Calling populateLineItemsList  
            }catch(Exception e){
                Nebula.Logger.error('Failed: in CPQBISQuoteTemplateController' + this.quoteRec + 'Error:' + e.getMessage());
                Nebula.Logger.saveLog();
            } 
            
            
            
        }
        //Method to Calculating total for the Bundle based on line items.
        private void calculateTotals(List<SBQQ__QuoteLine__c> quoteLine){

            
        }
        
        //Method to initialize fields
        private void initializeFields() {
            AccountCustomerClass = quoteRec.SBQQ__Account__r.Customer_Class__c;
            AccountName = quoteRec.SBQQ__Account__r.Name;
            CustomerNumber = quoteRec.SBQQ__Account__r.Customer_Number__c;
            billingStreet = quoteRec.SBQQ__BillingStreet__c;
            billingCity = quoteRec.SBQQ__BillingCity__c;
            billingState = quoteRec.SBQQ__BillingState__c;
            billingCountry = quoteRec.SBQQ__BillingCountry__c;
            billingPostalCode = quoteRec.SBQQ__BillingPostalCode__c;
            accCustNumber = quoteRec.Account_Customer_Number__c;
            faNumber = quoteRec.Financial_Account_Number__c;
            faVATRegistration = quoteRec.Financial_Account_Name__r.VAT_Registration__c;
            haveTransactionalAccess = false;
            renewalTerm = quoteRec.SBQQ__RenewalTerm__c;
            percentAAR = quoteRec.AAR__c;
            termType = quoteRec.Term_Type__c;
            SubscriptionTerm = quoteRec.SBQQ__SubscriptionTerm__c;
            lstProducts = new List<ProductList>();
            lstSub = new List<LineItems>();
            courtlinkProductListCurrency = new List<LineItems>();
            lstProductsCorporateAndAcademic = new List<ProductList>();
            lstTopFiveProductsCorporateAndAcademic = new List<ProductList>();
            lstRemainingProductsCorporateAndAcademic = new List<ProductList>();
            lstOneTimeProducts = new List<ProductList>();
            lstWealthNexisOneTimeProducts = new List<ProductList>();
            lstTopFiveProducts = new List<ProductList>();
            lstRemainingProducts = new List<ProductList>();
            allQuoteLines = new List<SBQQ__QuoteLine__c>();
            courtlinkProductList = new List<ProductList>();
            diligenceProductList = new List<ProductList>();
            LAW360ProductList = new List<ProductList>();
            MLEXProductList = new List<ProductList>();
            LEXMachinaProductList = new List<ProductList>();
            LEXMachinaAPIProductList = new List<ProductList>();
            CreateProductList = new List<ProductList>();
            CreateDMSProductList = new List<ProductList>();
            oneTimeProductFee = 0;
            oneTimeNWProductFee = 0;
            totalInvestigations = 0;
            totalUBODocs = 0;
            totalDocAccessUsageAllocation = 0;
            totalPREventUsageAllocation = 0;
            totalNDPDocAccessUsageAllocation = 0;
            totalNDPPREventUsageAllocation = 0;
            totalNDPDownloadCredits = 0;
            totalPublicRecordEvents = 0;
            numberAdded = 0;
            trackDescription = 0;
            hasGCA = quoteRec.Has_GCA__c;
            isNDPBundle = false;
            bundleName = '';
            isAAR = (termType == 'AAR');
            isFixedTerm = (termType == 'Fixed Term');
            QuoteStartDate = '';
            QuoteEndDate = '';
            gcaStartDate = '';
            if(quoteRec.GCA_Start_Date__c != null){
                gcaStartDate = quoteRec.GCA_Start_Date__c.Month()+'/'+quoteRec.GCA_Start_Date__c.Day()+'/'+quoteRec.GCA_Start_Date__c.Year();
            }
            if(quoteRec.SBQQ__StartDate__c != null){
                QuoteStartDate = quoteRec.SBQQ__StartDate__c.Month()+'/'+quoteRec.SBQQ__StartDate__c.Day()+'/'+quoteRec.SBQQ__StartDate__c.Year();
            }
            if(quoteRec.SBQQ__EndDate__c != null){
                QuoteEndDate = quoteRec.SBQQ__EndDate__c.Month()+'/'+quoteRec.SBQQ__EndDate__c.Day()+'/'+quoteRec.SBQQ__EndDate__c.Year();
            }
            
            System.debug('### DEBUG: initializeFields() — termType = ' + termType);
             System.debug('### DEBUG: isAAR = ' + isAAR + ' | isFixedTerm = ' + isFixedTerm);
        } 
        
     

        
        //Method to Process each Quote line and adding them in two Lists: lstProductsCorporateAndAcademic and lstProducts
        private void processQuoteLine(SBQQ__QuoteLine__c ql, Map<String, List<SBQQ__QuoteLine__c>> lineItemsByDate){
            //Adding line items of Research Bundle and Academic Bundle in lstProductsCorporateAndAcademic
            if(ql.SBQQ__SegmentIndex__c == 1 ){
                ProductList pl  = new ProductList();
                pl.Name = ql.SBQQ__Product__r.Name;
                pl.quantity = Integer.valueOf(ql.SBQQ__Quantity__c);
                pl.code = ''+(ql.SBQQ__Product__r.Product_Id__c != null ? ql.SBQQ__Product__r.Product_Id__c:ql.SBQQ__Product__r.ProductCode);
                pl.code2 = ql.Product_Id__c;
                pl.feature = ql.Feature__c;
                pl.description = ql.SBQQ__Description__c;
                pl.productName = ql.SBQQ__ProductName__c;
                pl.bundleName = ql.Bundle_Name__c;
                this.lstProductsCorporateAndAcademic.add(pl);
            }  
            System.debug('lstProductsCorporateAndAcademic'+lstProductsCorporateAndAcademic);
            
            // --- Populate courtlinkProductList  ---
    if((ql.Bundle_Name__c == 'Courtlink' || ql.Product_Option_Feature__c == 'Courtlink')  && ql.SBQQ__SegmentIndex__c == 1){
        ProductList pl  = new ProductList();
                pl.Name = ql.SBQQ__Product__r.Name;
                pl.quantity = Integer.valueOf(ql.SBQQ__Quantity__c);
                pl.code = ''+(ql.SBQQ__Product__r.Product_Id__c != null ? ql.SBQQ__Product__r.Product_Id__c:ql.SBQQ__Product__r.ProductCode);
                pl.code2 = ql.Product_Id__c;
                pl.feature = ql.Feature__c;
                pl.description = ql.SBQQ__Description__c;
                pl.productName = ql.SBQQ__ProductName__c;
                pl.bundleName = ql.Bundle_Name__c;
                this.courtlinkProductList.add(pl);
    }
            
                     // --- Populate diligenceProductList  ---
    if((ql.Bundle_Name__c == 'Diligence+' || ql.Product_Option_Feature__c == 'Diligence+' || ql.product_class__c == 'Diligence')  && ql.SBQQ__SegmentIndex__c == 1){
        ProductList pl  = new ProductList();
                pl.Name = ql.SBQQ__Product__r.Name;
                pl.quantity = Integer.valueOf(ql.SBQQ__Quantity__c);
                pl.code = ''+(ql.SBQQ__Product__r.Product_Id__c != null ? ql.SBQQ__Product__r.Product_Id__c:ql.SBQQ__Product__r.ProductCode);
                pl.code2 = ql.Product_Id__c;
                pl.TotalInvestigations = ql.Total_Investigations__c;
                pl.feature = ql.Feature__c;
                pl.description = ql.SBQQ__Description__c;
                pl.productName = ql.SBQQ__ProductName__c;
                pl.bundleName = ql.Bundle_Name__c;
                this.diligenceProductList.add(pl);
    }
            
            // --- Populate LAW360ProductList  ---
    if((ql.Bundle_Name__c == 'LAW360' || ql.Product_Option_Feature__c == 'LAW360' || ql.SBQQ__ProductFamily__c == 'LAW360' || ql.product_class__c == 'LAW360' )  && ql.SBQQ__SegmentIndex__c == 1){
        ProductList pl  = new ProductList();
                pl.Name = ql.SBQQ__Product__r.Name;
                pl.quantity = Integer.valueOf(ql.SBQQ__Quantity__c);
                pl.code = ''+(ql.SBQQ__Product__r.Product_Id__c != null ? ql.SBQQ__Product__r.Product_Id__c:ql.SBQQ__Product__r.ProductCode);
                pl.code2 = ql.Product_Id__c;
                pl.feature = ql.Feature__c;
                pl.description = ql.SBQQ__Description__c;
                pl.productName = ql.SBQQ__ProductName__c;
                pl.bundleName = ql.Bundle_Name__c;
                this.LAW360ProductList.add(pl);
    }
            
            // --- Populate MLEXProductList  ---
    if( ql.product_class__c == 'MLEX' && ql.SBQQ__SegmentIndex__c == 1){
        ProductList pl  = new ProductList();
                pl.Name = ql.SBQQ__Product__r.Name;
                pl.quantity = Integer.valueOf(ql.SBQQ__Quantity__c);
                pl.code = ''+(ql.SBQQ__Product__r.Product_Id__c != null ? ql.SBQQ__Product__r.Product_Id__c:ql.SBQQ__Product__r.ProductCode);
                pl.code2 = ql.Product_Id__c;
                pl.feature = ql.Feature__c;
                pl.description = ql.SBQQ__Description__c;
                pl.productName = ql.SBQQ__ProductName__c;
                pl.bundleName = ql.Bundle_Name__c;
                this.MLEXProductList.add(pl);
    }
            
                   // --- Populate LEXMachinaProductList  ---
    if( ql.product_class__c == 'LexMachina' && ql.SBQQ__SegmentIndex__c == 1){
        ProductList pl  = new ProductList();
                pl.Name = ql.SBQQ__Product__r.Name;
                pl.quantity = Integer.valueOf(ql.SBQQ__Quantity__c);
                pl.code = ''+(ql.SBQQ__Product__r.Product_Id__c != null ? ql.SBQQ__Product__r.Product_Id__c:ql.SBQQ__Product__r.ProductCode);
                pl.code2 = ql.Product_Id__c;
                pl.feature = ql.Feature__c;
                pl.description = ql.SBQQ__Description__c;
                pl.productName = ql.SBQQ__ProductName__c;
                pl.bundleName = ql.Bundle_Name__c;
                this.LEXMachinaProductList.add(pl);
    }
            
             // --- Populate LEXMachinaAPIProductList  ---
    if(ql.Product_Option_Feature__c == 'API'){
        ProductList pl  = new ProductList();
                pl.Name = ql.SBQQ__Product__r.Name;
                pl.quantity = Integer.valueOf(ql.SBQQ__Quantity__c);
                pl.code = ''+(ql.SBQQ__Product__r.Product_Id__c != null ? ql.SBQQ__Product__r.Product_Id__c:ql.SBQQ__Product__r.ProductCode);
                pl.code2 = ql.Product_Id__c;
                pl.feature = ql.Feature__c;
                pl.description = ql.SBQQ__Description__c;
                pl.productName = ql.SBQQ__ProductName__c;
                pl.bundleName = ql.Bundle_Name__c;
                this.LEXMachinaAPIProductList.add(pl);
    }
            
                          // --- Populate CreateProductList  ---
    if( ql.product_class__c == 'Lexis Create' && ql.SBQQ__SegmentIndex__c == 1){
        ProductList pl  = new ProductList();
                pl.Name = ql.SBQQ__Product__r.Name;
                pl.quantity = Integer.valueOf(ql.SBQQ__Quantity__c);
                pl.code = ''+(ql.SBQQ__Product__r.Product_Id__c != null ? ql.SBQQ__Product__r.Product_Id__c:ql.SBQQ__Product__r.ProductCode);
                pl.code2 = ql.Product_Id__c;
                pl.feature = ql.Feature__c;
                pl.description = ql.SBQQ__Description__c;
                pl.productName = ql.SBQQ__ProductName__c;
                pl.bundleName = ql.Bundle_Name__c;
                this.CreateProductList.add(pl);
    }
            
             // --- Populate CreateDMSProductList  ---
    if( ql.Product_Option_Feature__c == 'Lexis Create & DMS' && ql.SBQQ__SegmentIndex__c == 1){
        ProductList pl  = new ProductList();
                pl.Name = ql.SBQQ__Product__r.Name;
                pl.quantity = Integer.valueOf(ql.SBQQ__Quantity__c);
                pl.code = ''+(ql.SBQQ__Product__r.Product_Id__c != null ? ql.SBQQ__Product__r.Product_Id__c:ql.SBQQ__Product__r.ProductCode);
                pl.code2 = ql.Product_Id__c;
                pl.feature = ql.Feature__c;
                pl.description = ql.SBQQ__Description__c;
                pl.productName = ql.SBQQ__ProductName__c;
                pl.bundleName = ql.Bundle_Name__c;
                this.CreateDMSProductList.add(pl);
    }
            
            
            
            System.debug('LEXMachinaAPIProductList::'+LEXMachinaAPIProductList);
            // Populating key in the map : lineItemsByDate based on the start date and end date of Quote line
            // MODIFIED: Only add to lineItemsByDate if it's NOT a one-time subscription product
           
           if (quoteRec.Free_Time__c == CPQConstants.QUOTE_FREE_TIME_GIVEN && quoteRec.End_Free_Time__c != null && quoteRec.Start_Free_Time__c != null) {
                    String key = 'Activation To ' + quoteRec.End_Free_Time__c.Month() + '/' + quoteRec.End_Free_Time__c.Day() + '/' + quoteRec.End_Free_Time__c.Year();
                if(!lineItemsByDate.containsKey(key)){
                    lineItemsByDate.put(key,new List<SBQQ__QuoteLine__c>());
                }
                lineItemsByDate.get(key).add(ql);
            }
            
            if(ql.SBQQ__StartDate__c != null && ql.SBQQ__EndDate__c != null && 
               ql.SBQQ__Product__r.SBQQ__SubscriptionType__c != CPQConstants.PRODUCT_ONE_TIME_SUBSCRIPTION_TYPE){
                String key = ql.SBQQ__StartDate__c.Month()+'/'+ql.SBQQ__StartDate__c.Day()+'/'+ql.SBQQ__StartDate__c.Year() +' To '
                    +ql.SBQQ__EndDate__c.Month()+'/'+ql.SBQQ__EndDate__c.Day()+'/'+ql.SBQQ__EndDate__c.Year();
                if(!lineItemsByDate.containsKey(key)){
                    lineItemsByDate.put(key,new List<SBQQ__QuoteLine__c>());
                }
                lineItemsByDate.get(key).add(ql);
            }
            
            if(ql.SBQQ__Product__r.SBQQ__SubscriptionType__c == CPQConstants.PRODUCT_ONE_TIME_SUBSCRIPTION_TYPE &&  ql.Bundle_Name__c == CPQConstants.BUNDLE_NEWSDESK_BUNDLE){
                ProductList pl  = new ProductList();
                pl.Name = ql.SBQQ__Product__r.Name;
                pl.productName = ql.SBQQ__ProductName__c;
                pl.netMonthly = String.valueOf(ql.Net_Monthly__c);
                this.lstOneTimeProducts.add(pl);
            }  
            if(ql.SBQQ__Product__r.SBQQ__SubscriptionType__c == CPQConstants.PRODUCT_ONE_TIME_SUBSCRIPTION_TYPE && ql.Bundle_Name__c == CPQConstants.BUNDLE_NEXIS_WEALTH_NAVIGATOR_BUNDLE){
                ProductList pl  = new ProductList();
                pl.Name = ql.SBQQ__Product__r.Name;
                pl.netMonthly = String.valueOf(ql.Net_Monthly__c);
                this.lstWealthNexisOneTimeProducts.add(pl);
            }
        }
        
     

        
        private void populateLineItemsList(Map<String, List<SBQQ__QuoteLine__c>> lineItemsByDate){
            for(String key : lineItemsByDate.KeySet()){
                LineItems lineItem = new LineItems();
                lineItem.netMonthly = 0;
                
                for(SBQQ__QuoteLine__c qli : lineItemsByDate.get(key)){
                    if(lineItem.CurrencyIsoCode == null && qli.CurrencyIsoCode != null){
                    lineItem.CurrencyIsoCode = qli.CurrencyIsoCode;
                   }
         
                    System.debug('qli ::' +  qli);
                    System.debug('bundle ::' +  qli.Bundle_Name__c);

                    // Filter to exclude one-time subscription products from monthly commitment calculations
                    if(qli.SBQQ__Product__r.SBQQ__SubscriptionType__c != CPQConstants.PRODUCT_ONE_TIME_SUBSCRIPTION_TYPE){
                                lineItem.netMonthly += qli.Net_Monthly__c;                     
                        }        
                }
                
                // If Free Trial, force Net Monthly to 0
                    if (quoteRec.Free_Time__c == CPQConstants.QUOTE_FREE_TIME_GIVEN
                        && quoteRec.Start_Free_Time__c != null
                        && quoteRec.End_Free_Time__c != null
                        && key.startsWith('Activation To')) {
                    
                        lineItem.netMonthly = 0;
                    }
                
                lineItem.formattedNetMonthly = formatCurrency(lineItem.netMonthly, lineItem.CurrencyIsoCode);
                System.debug('lineItem.formattedNetMonthly'+lineItem.formattedNetMonthly);
                lineItem.dateKey = key;
                system.debug('lineItem.dateKey >>> '+lineItem.dateKey);
                this.lstSub.add(lineItem);
            }
            
            for (String key : lineItemsByDate.keySet()) {
           System.debug('Inside second loop');
        LineItems lineItem = new LineItems();
        lineItem.netMonthly = 0;

        for (SBQQ__QuoteLine__c qli : lineItemsByDate.get(key)) {

            // --- Process only Courtlink bundle items ---
            if (qli.Bundle_Name__c == 'Courtlink' || qli.Product_Option_Feature__c == 'Courtlink') {
                     System.debug('Inside second loop: '+ qli.Bundle_Name__c);
                if (lineItem.CurrencyIsoCode == null && qli.CurrencyIsoCode != null) {
                    lineItem.CurrencyIsoCode = qli.CurrencyIsoCode;
                }

                // Exclude one-time subscriptions from monthly calc
                if (qli.SBQQ__Product__r.SBQQ__SubscriptionType__c != CPQConstants.PRODUCT_ONE_TIME_SUBSCRIPTION_TYPE) {
                    lineItem.netMonthly += qli.Net_Monthly__c;
                }
            }
        }

        // Add only if this group had Courtlink lines
        if (lineItem.CurrencyIsoCode != null) {
            lineItem.formattedNetMonthly =
                formatCurrency(lineItem.netMonthly, lineItem.CurrencyIsoCode);
             System.debug('lineItem.formattedNetMonthlyCourtlink'+lineItem.formattedNetMonthly);
            lineItem.dateKey = key;
             system.debug('lineItem.dateKey courtlink >>> '+lineItem.dateKey);
            this.courtlinkProductListCurrency.add(lineItem);
        }
    }
           
            
            System.debug('list of subscriptions courtlinkProductListCurrency: ' +  this.courtlinkProductListCurrency);
          
        }
        
        
        }
        public static String formatCurrency(Decimal amount, String currencyIso) {

    if(amount == null) return '';

    Map<String, String> currencyMap = new Map<String, String>{
        'USD' => '$',
        'EUR' => '€',
        'AED' => 'AED ',
        'HKD' => 'HK$',
        'INR' => 'INR ',
        'JPY' => '¥',
        'MYR' => 'RM ',
        'SGD' => 'S$ ',
        'KRW' => '₩ ',
        'GBP' => '£ '
    };

    String symbol = currencyMap.containsKey(currencyIso) ? currencyMap.get(currencyIso) : '';

    // Format numbers with comma & 2 decimals
    String formatted = String.valueOf(amount.setScale(2));

    return symbol + formatted;
}



    
    /*******************************************************************************************
* @Name         ProductList 
* @Author       Yogeshwari Sharma 
* @Date         01/09/2024
* @Description  Wrapper Class for encapsulating product information in a quote.
*******************************************************************************************/
    
    public Class ProductList{
        @AuraEnabled
        public String Name{get;set;}
        @AuraEnabled
        public String code{get;set;}
        @AuraEnabled
        public String code2{get;set;}
        @AuraEnabled
        public Decimal TotalInvestigations{get;set;}
        @AuraEnabled
        public Integer quantity{get;set;}
        @AuraEnabled
        public String feature{get;set;} 
        @AuraEnabled
        public String description{get;set;}
        @AuraEnabled
        public String productName{get;set;}
        @AuraEnabled
        public String netMonthly{get;set;}
         @AuraEnabled
        public String formattedNetMonthly{get;set;}
        @AuraEnabled
        public String sku{get;set;}
        @AuraEnabled
        public String productNamesWithCodes{get;set;}
        @AuraEnabled
        public Integer newsDeskUser{get;set;}
        @AuraEnabled
        public String bundleName{get;set;}
        @AuraEnabled
        public Integer numberOfTrackers{get;set;}
        @AuraEnabled
        public Integer numberOfUsers{get;set;}
        @AuraEnabled
        public Integer totalNumberPermittedPerAccount{get;set;}
        @AuraEnabled
        public Integer totalKStateContentOnly{get;set;}
        
        @AuraEnabled
        public Integer creditAllocation{get;set;}
        @AuraEnabled
        public Decimal commitment{get;set;}
        public ProductList(){
        }
    }

    public class LineItems{
        @AuraEnabled
        public String dateKey {get;set;}
        @AuraEnabled
        public Integer months{get;set;}
        @AuraEnabled
        public Decimal netMonthly{get;set;}
        @AuraEnabled public String CurrencyIsoCode { get; set; }
        public String formattedNetMonthly { get; set; }

        public LineItems(){
            this.months = 1;    
        }
    }
    
}