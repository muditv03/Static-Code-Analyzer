/*******************************************************************************************
* @Name         CPQSmallLawCalculationHelper 
* @Author       Naval Sharma
* @Description  Helper Class for CPQSmallLawCalculationHandler
*               - .
*               - .
*******************************************************************************************/
public class CPQSmallLawCalculationHelper {
    /**
*   Calculates various roll-up summary fields on a quote based on its associated quote line data.
*
*   This method processes a list of quote line items, aggregates different financial and categorical 
*   metrics, and updates the mapQuoteData with computed values. It considers multiple factors 
*   including product features, product codes, package types, and discounts to determine the final 
*   values for the quote.
*
*   Key Calculations:
* - Aggregates Net_Monthly__c values for different product features such as Core Offering, 
*   Productivity, Analytics, Public Records, and Litigation Tools.
* - Counts occurrences of specific products based on SBQQ__ProductCode__c and SBQQ__ProductName__c.
* - Calculates discounts, exclusions, and eligibility criteria for various product categories.
* - Identifies the presence of specific bundles (e.g., GOTC, CLE, Automated Forms).
* - Computes first-segment values for List__c and Negotiated_Disc_Amt__c.
* - Determines maximum standalone product quantities and product category counts.
* - Flags specific conditions like Has_Diligence__c, Has_Lex_Machina__c, and Has_CaseMapSanction__c.
**/
    
    public static void calculateRollupFieldsOnQuote(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata) {
        System.debug('quoteLinedata--'+quoteLinedata);
        Decimal sumOfNetMonthlyofSeondaryPracticalFeature = 0;
        Boolean hasSimplifiedPackageSkuPresent = false;
        Decimal sumOfNetMonthlyofCoreOfferingFeature = 0;
        Decimal sumOfCoreOfferingProductMixDiscount = 0;
        Integer countOfLexisPlatform = 0 ;
        Double law360PlatformPlanCount = 0;
        Decimal sumOfNetMonthlyofProductivityFeature = 0;
        Decimal sumOfNetMonthlyofAnalyticsFeature = 0;
        Double sumOfLMOProductCount = 0;
        Integer sumOfAutomatedFormCount = 0;
        Decimal sumOfNetMonthlyofNewFeature = 0;
        Decimal sumOfNetMonthlyofPublicRecordsFeature = 0;
        Decimal sumOfNetMonthlyofCourtMaterialsFeature = 0;
        Double countOfCLEProduct = 0;
        Double countOfPremierResearchSuite = 0; 
        Decimal sumOfNetMonthlyofLitigationToolsFeature = 0;
        Integer premierResearchSuiteDiscount = 0;
        Double countOfOnlineContentSmallLaw = 0;
        Decimal sumOfFirstSegmentListAmount2 = 0;
        Decimal sumOfFirstSegmentFreeProductList = 0;  
        Decimal sumOfNegotiatedDiscAmt = 0;
        Integer transactionalProductCount = 0;
        Double countOfGotcBundleAdded = 0;
        Double countOfCCHProduct = 0;
        Integer countOfCaseMap = 0;
        Integer countOfCourtlink = 0;
        Integer countOfLexisCreateforUSMarkets = 0;
        Integer countOfSanction = 0;
        Integer countofProductPublicRecordMin = 0;
        Double countOfExcludeQuoteLines = 0;
        Integer countOfContinuingLegalEducationOnDemand = 0;
        Double countAutomatedFormsBundleQuantity = 0;
        Double countOfLexisPracticalGuidance = 0;
        Double maxQuantityForStandalonePG = 0;
        Integer quantityOfFirmWideProduct = 0;
        Double transactionalDiscountPrice = 0;
        Double countDiligenceGoldAndDiligencePlatinum = 0;
        List<Double> maxQuantityForStandalonePGList = new List<Double>();
        Integer lexisPlatformCount=0;
        Integer lexisPlusPlatformCount=0;
        Integer lexisPlusAIPlatformCount=0;
        Double sanctionBundleCount=0;
        Integer cLEBundleCount=0;        
        Double countOfLexisPlusAIAsk = 0;
        Integer countOfOnlyCourtlinkProd = 0;
        Boolean isAdminAssemblyPresent = false;
        mapQuoteData.put('Has_Diligence__c', false);
        mapQuoteData.put('Is_Quantity_Same_As_Attorney_False__c', false);
        mapQuoteData.put('lncpq_Has_PG__c', false);
        mapQuoteData.put('Has_Automated_Forms__c',false);
        mapQuoteData.put('Has_CLE_OD__c', false);
        mapQuoteData.put('Has_Product_Public_Record_Min__c', false);
        mapQuoteData.put('Has_CaseMapSanction__c', false);
        mapQuoteData.put('Has_Lexis_Create_for_US_Markets__c', false);
        mapQuoteData.put('Has_Courtlink__c', false);
        mapQuoteData.put('Has_CaseMap__c', false);
        mapQuoteData.put('Has_CCH__c', false);
        mapQuoteData.put('Product_Mix_Discount_Eligible__c', false);
        mapQuoteData.put('Transactional_Discount_Addendum__c', false);
        mapQuoteData.put('GOTC_Bundle_Added__c', false);
        mapQuoteData.put('Has_Lex_Machina__c', false);
        mapQuoteData.put('hasOnlyCourtlinkProduct__c',false);
        mapQuoteData.put('Has_CreateUSMarkets_DMS',false);
        mapQuoteData.put('hasSimplifiedPackageSku__c',false);

        
        Set<String> coreOfferingProductsAdded = new Set<String>();
        
        for(Map<String,Object> line :quoteLinedata){
            String feature = CoreCPQCalculationService.convertToString(line, 'Feature__c');
            String productName = CoreCPQCalculationService.convertToString(line, 'SBQQ__ProductName__c');
            String ProductId   = CoreCPQCalculationService.convertToString(line, 'Product_Id__c');
            Double segmentIndex = CoreCPQCalculationService.convertToDouble(line, 'SBQQ__SegmentIndex__c');
            Decimal netMonthly = CoreCPQCalculationService.convertToDecimal(line, 'Net_Monthly__c');
            Double quantity = CoreCPQCalculationService.convertToDouble(line, 'SBQQ__Quantity__c');
            String productCode = CoreCPQCalculationService.convertToString(line, 'SBQQ__ProductCode__c');
            Integer netMonthlyRoundedToZero = CoreCPQCalculationService.convertToInteger(line,'Net_Monthly__c');
            Boolean excludedKey = CoreCPQCalculationService.convertToBoolean(line,'Excluded__c');
            if(CPQConstants.SetofSimplifiedPackageSku.contains(ProductId)){

                System.debug('hasSimplifiedPackageSkuPresent :::' + hasSimplifiedPackageSkuPresent);
                hasSimplifiedPackageSkuPresent = true;
            }
            if(CoreCPQCalculationService.convertToBoolean(line, 'FirstSegment_Free_Product__c') == true){
                sumOfFirstSegmentFreeProductList += CoreCPQCalculationService.convertToDecimal(line,'List__c');
            }
            if(segmentIndex == 1 ){
                sumOfFirstSegmentListAmount2 += CoreCPQCalculationService.convertToDecimal(line,'List__c');
                sumOfNegotiatedDiscAmt += CoreCPQCalculationService.convertToDouble(line,'Negotiated_Disc_Amt__c');
            }
            if(feature == 'Secondary & Practical'){
                sumOfNetMonthlyofSeondaryPracticalFeature += netMonthly;
            }
            
            if(feature == 'Core Offering'){
                if(netMonthly != null){
                    sumOfNetMonthlyofCoreOfferingFeature += netMonthly;
                }
                // Core offering state product mix discount - only add each product once
                if(!coreOfferingProductsAdded.contains(productCode) && netMonthly != null && netMonthly > 0){
                    if(productCode == 'SENP' || productCode == 'SPP' || productCode == 'urn:product:1554137'){
                        sumOfCoreOfferingProductMixDiscount += 0.1;
                        coreOfferingProductsAdded.add(productCode);
                    } else if(productCode == 'SESP' || productCode == 'urn:product:2029419'){
       
                        sumOfCoreOfferingProductMixDiscount += 0.02;
                        coreOfferingProductsAdded.add(productCode);
                    }

                    if(sumOfCoreOfferingProductMixDiscount > 0.1){
                        sumOfCoreOfferingProductMixDiscount = 0.1;
                    }
                }
            }
            if(productCode == 'urn:product:1531221'){
                countOfLexisPlatform += 1;
            }
            if(CoreCPQCalculationService.convertToString(line, 'Product_Code_and_Excluded__c') == 'urn:product:1541034 false'){
                law360PlatformPlanCount += quantity;
            }
            if(feature == 'Productivity'){
                sumOfNetMonthlyofProductivityFeature += netMonthly;
            }
            if(feature == 'Analytics'){
                sumOfNetMonthlyofAnalyticsFeature += netMonthly;
            }
            if(CoreCPQCalculationService.convertToBoolean(line,'LMO_Product__c')){
                sumOfLMOProductCount += quantity;
            }
            if(feature == 'News'){
                sumOfNetMonthlyofNewFeature += netMonthly;
            }
            if(feature == 'Public Records'){
                sumOfNetMonthlyofPublicRecordsFeature += netMonthly;
            }
            if(feature == 'Court Materials'){
                sumOfNetMonthlyofCourtMaterialsFeature += netMonthly;
            }
            if(productCode == 'urn:product:1520732'){
                countOfCLEProduct += quantity;
            }
            if(feature =='Litigation Tools'){
                sumOfNetMonthlyofLitigationToolsFeature += netMonthly;
            }
            if(productCode == 'urn:product:1539966' && netMonthly != null && netMonthly > 0){
                countOfPremierResearchSuite += 1;
            }
            if(productCode == 'LNSL'){
                countOfOnlineContentSmallLaw += quantity;
            }
            if(CoreCPQCalculationService.convertToBoolean(line,'Is_Transactional_Prod__c') && !excludedKey){
                transactionalProductCount += 1;
                transactionalDiscountPrice += CoreCPQCalculationService.convertToDecimal(line,'SBQQ__OriginalPrice__c');
                
            }
            if(productCode == 'SLOCGOTC'){
                countOfGotcBundleAdded += quantity;
            }
            if(productCode == 'LNLPCCH'){
                countOfCCHProduct += 1;
            }
            if(productName.contains('CaseMap')){
                countOfCaseMap += netMonthlyRoundedToZero;
            }
            if(productName.contains('Everything CourtLink')){
                countOfCourtlink += netMonthlyRoundedToZero;
            }
            if((productCode == 'urn:product:1546617') && !excludedKey){
                isAdminAssemblyPresent = true;
            }
            
            if(((productCode == 'urn:product:1545335') ||  (productCode == 'urn:product:1550166')) && !excludedKey ){
                countOfLexisCreateforUSMarkets += netMonthlyRoundedToZero;    
            }
            if(productCode == 'urn:product:1550166'){
                    mapQuoteData.put('Has_CreateUSMarkets_DMS', true);
             }
            if((productName.contains('Sanction') || productName.contains('CaseMap'))&& !excludedKey){
                countOfSanction += netMonthlyRoundedToZero;
            }
            if(CoreCPQCalculationService.convertToString(line,'Product_Public_Record_Min_Lvl__c') == 'Non-Regulated Public Records' || CoreCPQCalculationService.convertToString(line,'Product_Public_Record_Min_Lvl__c') == 'Regulated Public Records'){
                countofProductPublicRecordMin += netMonthlyRoundedToZero;
            }
            if(CoreCPQCalculationService.convertToBoolean(line,'Excluded__c')){
                countOfExcludeQuoteLines += quantity;
            }
            if(productName.contains('Continuing Legal Education (CLE) OnDemand')){
                countOfContinuingLegalEducationOnDemand += netMonthlyRoundedToZero;
            }
            if(productName == 'Automated forms'){
                countAutomatedFormsBundleQuantity += quantity;
            }
            if(productName.contains('Practical Guidance')){
                countOfLexisPracticalGuidance += quantity;
            }
            if(productName.contains('Practical Guidance -')){
                maxQuantityForStandalonePGList.add(quantity);
            }
            if(CoreCPQCalculationService.convertToBoolean(line,'Is_Quantity_Same_As_Attorney__c')){
                quantityOfFirmWideProduct += 1;
            }
            if((productCode == 'urn:product:1536918' || productCode == 'urn:product:1536917') && !excludedKey){
                countDiligenceGoldAndDiligencePlatinum += quantity;
            }
            if(CoreCPQCalculationService.convertToString(line,'SBQQ__ProductCode__c') == 'urn:product:1000050'){
                lexisPlatformCount += 1;
            }
            if(CoreCPQCalculationService.convertToString(line,'SBQQ__ProductCode__c') == 'urn:product:1531221'){
                lexisPlusPlatformCount += 1;
            }
            if(CoreCPQCalculationService.convertToString(line,'SBQQ__ProductCode__c') == 'urn:product:1554573'){
                lexisPlusAIPlatformCount += 1;
            }
            if(CoreCPQCalculationService.convertToString(line,'SBQQ__ProductName__c') == 'Sanction 1535862'){
                sanctionBundleCount += 1;
            }
            if(CoreCPQCalculationService.convertToString(line,'SBQQ__ProductName__c') == 'Continuing Legal Education (CLE) OnDemand General Catalog'){
                sanctionBundleCount += quantity;
            }
            if(CoreCPQCalculationService.convertToString(line,'SBQQ__ProductCode__c') == 'EC-1525173' || CoreCPQCalculationService.convertToString(line,'SBQQ__ProductCode__c') == 'urn:product:1525172' || CoreCPQCalculationService.convertToString(line,'SBQQ__ProductCode__c') == 'urn:product:1527138' || CoreCPQCalculationService.convertToString(line,'SBQQ__ProductCode__c') == 'urn:product:1525173'){
                countOfOnlyCourtlinkProd += 1;
            }
            System.debug('countOfOnlyCourtlinkProd'+countOfOnlyCourtlinkProd);
            //Check for Product Code urn:product:1548226 of Product Name Lexis+ AI™ Ask 1548226.
            if(productCode == 'urn:product:1548226'){
                countOfLexisPlusAIAsk += 1;
            }
            
        }
        if(!maxQuantityForStandalonePGList.isEmpty()){
            maxQuantityForStandalonePG = maxQuantityForStandalonePGList[0];
            
            For (integer i =0; i < maxQuantityForStandalonePGList.size(); i++){
                if( maxQuantityForStandalonePGList[i] > maxQuantityForStandalonePG){
                    maxQuantityForStandalonePG = maxQuantityForStandalonePGList[i];
                }            
            } 
        }   
        
        
        
        mapQuoteData.put('FirstSegment_Free_Product_List__c', sumOfFirstSegmentFreeProductList);
        
        System.debug('First Segment List Amount '+ sumOfFirstSegmentListAmount2);
        mapQuoteData.put('First_Segment_List_Amount2__c', sumOfFirstSegmentListAmount2);
        
        mapQuoteData.put('Secondary_Practical__c', sumOfNetMonthlyofSeondaryPracticalFeature);
        mapQuoteData.put('Secondary_Practical_Discount__c', sumOfNetMonthlyofSeondaryPracticalFeature > 0 ? 0.02 : 0);
        
        mapQuoteData.put('Primary_Law__c', sumOfNetMonthlyofCoreOfferingFeature);
        
        mapQuoteData.put('Lexis_Platform_count__c', countOfLexisPlatform);
        System.debug('countOfLexisPlatform ----'+countOfLexisPlatform);
        
        mapQuoteData.put('Law360_Platform_Plan_Count__c', law360PlatformPlanCount);
        
        mapQuoteData.put('Productivity__c', sumOfNetMonthlyofProductivityFeature);
        
        mapQuoteData.put('Analytics__c', sumOfNetMonthlyofAnalyticsFeature);
        
        mapQuoteData.put('LMO_Count__c', sumOfLMOProductCount);
        
        mapQuoteData.put('Automated_Forms_Count__c', sumOfAutomatedFormCount);
        
        mapQuoteData.put('News__c', sumOfNetMonthlyofNewFeature);
        mapQuoteData.put('News_Discount__c', sumOfNetMonthlyofNewFeature > 0 ? 0.02 : 0);
        
        mapQuoteData.put('Public_Records__c', sumOfNetMonthlyofPublicRecordsFeature);
        mapQuoteData.put('Public_Records_Discount__c', sumOfNetMonthlyofPublicRecordsFeature > 0 ? 0.02 : 0);
        
        mapQuoteData.put('Court_Materials__c', sumOfNetMonthlyofCourtMaterialsFeature);
        mapQuoteData.put('Court_Materials_Discount__c', sumOfNetMonthlyofCourtMaterialsFeature > 0 ? 0.02 : 0);
        
        mapQuoteData.put('CLE_on_demand_count__c', countOfCLEProduct);
        
        mapQuoteData.put('Litigation_Tools__c', sumOfNetMonthlyofLitigationToolsFeature);
        mapQuoteData.put('Litigation_Tools_Discount__c', sumOfNetMonthlyofLitigationToolsFeature > 0 ? 0.02 : 0);
        
        mapQuoteData.put('Core_Offering_State_Product_Mix_Discount__c', sumOfCoreOfferingProductMixDiscount);
        
        mapQuoteData.put('Lexis_Platform_ct__c', countOflexisPlatform);
        mapQuoteData.put('hasSimplifiedPackageSku__c', hasSimplifiedPackageSkuPresent);

        
        
        if (countOfPremierResearchSuite > 0) {
            mapQuoteData.put('Premier_Research_Suite_Discount__c', 10);
            mapQuoteData.put('Premier_Research_Suite_Count__c', countOfPremierResearchSuite);
        }
        if(countOfOnlineContentSmallLaw > 0){
            mapQuoteData.put('Product_Mix_Discount_Eligible__c', true);
        }
        mapQuoteData.put('First_Segment_Additional_Disc_Amt__c', sumOfNegotiatedDiscAmt);
        
        if(transactionalProductCount > 0){
            mapQuoteData.put('Transactional_Discount_Addendum__c', true);
        }
        if(countOfGotcBundleAdded > 0){
            mapQuoteData.put('GOTC_Bundle_Added__c', true);
        }
        if(countOfCCHProduct > 0){
            mapQuoteData.put('Has_CCH__c', true);
            mapQuoteData.put('YoY_Growth__c', 7);
        }
        if(countOfCaseMap > 0){
            mapQuoteData.put('Has_CaseMap__c', true);
        }
        if(countOfCourtlink > 0){
            mapQuoteData.put('Has_Courtlink__c', true);
        }
        System.debug('countOfLexisCreateforUSMarkets :::' +  countOfLexisCreateforUSMarkets);
        if(countOfLexisCreateforUSMarkets > 0 ||  isAdminAssemblyPresent){
            mapQuoteData.put('Has_Lexis_Create_for_US_Markets__c', true);
        }
        if(countOfSanction > 0){
            mapQuoteData.put('Has_CaseMapSanction__c', true);
        }
        if(countofProductPublicRecordMin > 0){
            mapQuoteData.put('Has_Product_Public_Record_Min__c', true);
        }
        mapQuoteData.put('Excluded_Quote_Lines__c', countOfExcludeQuoteLines);
        if(countOfContinuingLegalEducationOnDemand > 0){
            mapQuoteData.put('Has_CLE_OD__c', true);
        }
        if(countAutomatedFormsBundleQuantity >0){
            mapQuoteData.put('Has_Automated_Forms__c',true);
        }
        if(countOfLexisPracticalGuidance > 0){
            mapQuoteData.put('lncpq_Has_PG__c', true);
        }
        mapQuoteData.put('Max_Quantity_for_Standalone_PG__c ', maxQuantityForStandalonePG);
        
        if(quantityOfFirmWideProduct > 0){
            mapQuoteData.put('Is_Quantity_Same_As_Attorney_False__c', true);
        }
        mapQuoteData.put('Negotiated_TD_Price__c', transactionalDiscountPrice);
        
        if(countDiligenceGoldAndDiligencePlatinum > 0 ){
            mapQuoteData.put('Has_Diligence__c', true);
        }
        
        if(lexisPlatformCount >= 1){
            mapQuoteData.put('Platform__c', 'Lexis');
        }
        if(lexisPlusPlatformCount > 0){
            mapQuoteData.put('Platform__c', 'Lexis+');
        }
        if(lexisPlusAIPlatformCount >= 1){
            mapQuoteData.put('Platform__c', 'Lexis+ AI');
        }
        //Lexis+ AI™ Ask 1548226 Product contains set to True.
        if(countOfLexisPlusAIAsk >= 1){
            mapQuoteData.put('Has_LexisPlusAIASK', true);
        }
        
        if(countOfOnlyCourtlinkProd == quoteLinedata.size()){
            mapQuoteData.put('hasOnlyCourtlinkProduct__c',true);
        }
        
        //debug logs
        System.debug('hasOnlyCourtlinkProduct - '+mapQuoteData.get('hasOnlyCourtlinkProduct'));
        
        
    }
    
    /**
* - This method calculates the SBQQ__SubscriptionTerm__c on the Quote as we are giving Term of Year only.  
* - It determines the subscription term based on the Quote type, Term_of_Years__c,Bridge_Period_Months__c.  
* - For non-Amendment and non-Replacement quotes, it sets the term as (Term_of_Years__c * 12) + Bridge_Period_Months__c.  
* - For Replacement quotes, it calculates the term based on WestBridge_Bridge_End_Date__c and SBQQ__EndDate__c.  
* - If WestBridge_Bridge_End_Date__c is null, it uses SBQQ__StartDate__c and SBQQ__EndDate__c for calculation.
* - If westBridgeEndDate is not null, it calculates the Subscription term based on the difference between the End Date and West Bridge Date.
*/
    public static void calculateSubscriptionTerm(Map<String, Object> mapQuoteData) { 
        
        Date westBridgeEndDate = CoreCPQCalculationService.convertToDate(mapQuoteData,'WestBridge_Bridge_End_Date__c');
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData, 'SBQQ__Type__c');
        Integer bridgePeriodMonth = CoreCPQCalculationService.convertToInteger(mapQuoteData, 'Bridge_Period_Months__c');
        System.debug('bridgePeriodMonth'+bridgePeriodMonth);
        Integer termOfYear = CoreCPQCalculationService.convertToInteger(mapQuoteData, 'Term_of_Years__c');
        Date endDate = CoreCPQCalculationService.convertToDate(mapQuoteData,'SBQQ__EndDate__c');
        Date startDate = CoreCPQCalculationService.convertToDate(mapQuoteData, 'SBQQ__StartDate__c');
        Integer yearDiff = endDate.year() - startDate.year();
        Integer monthDiff = endDate.month() - startDate.month();
        Integer endDay = endDate.day();
        Integer startDay = startDate.day();
        Integer bridgeMonths = bridgePeriodMonth != null ? bridgePeriodMonth : 0;
        
        if (quoteType != 'Amendment' && termOfYear != null && termOfYear != 0) {   
           Integer totalMonths = yearDiff * 12 + monthDiff + (endDay >= startDay ? 1 : 0);
            mapQuoteData.put('SBQQ__SubscriptionTerm__c',  Double.valueOf(totalMonths));
            
        }
        //debug logs
        system.debug('subTerm- ' + mapQuoteData.get('SBQQ__SubscriptionTerm__c') + ' bridgePeriodMonth- '+ bridgePeriodMonth + ' termOfYear- ' + termOfYear + ' quoteType- ' + quoteType + ' westBridgeEndDate- ' + westBridgeEndDate);
    }
    
    /**
* This method calculates the of_Attorneys__c on the Quote.  
* It Calculates the total number of attorneys by adding the values of  
* Number_of_Attorneys_Excluding_of_Counse__c and Number_of_Of_Counsel__c
**/
    public static void calculateOfAttorneysOnQuote(Map<String, Object> mapQuoteData){
        Integer numberOfAttorneysExludingCounse = CoreCPQCalculationService.convertToInteger(mapQuoteData,'Number_of_Attorneys_Excluding_of_Counse__c');
        Integer numberOfCounsel = CoreCPQCalculationService.convertToInteger(mapQuoteData,'Number_of_Of_Counsel__c');
        Integer attorneysOnQuote = numberOfAttorneysExludingCounse + numberOfCounsel;
        mapQuoteData.put('of_Attorneys__c', attorneysOnQuote);
        
        //debug logs
        system.debug('numberOfAttorneysExludingCounse- ' + numberOfAttorneysExludingCounse + ' numberOfCounsel- ' + numberOfCounsel + ' attorneysOnQuote- ' + attorneysOnQuote + '  of_Attorneys__c- '+ mapQuoteData.get('of_Attorneys__c'));
        
    }
    
    
    /**
* - This method updates Line Level Qty based on Quote Header Level Qty.
* - For New Business Quotes ,Quantity should be from headers and User can update it on Line Level.
* - If User change the Qty on Header level, then chnage should reflect on Lines making sure overridden lines are not effected.
* - For New Retentions Quotes, at the time of adding products, Quantity should be from headers and User can update it on Line Level.
* - If User change the Qty on Header level, then chnage should reflect on all Lines.
**/
    public static void calculateQuantityOnQuoteline(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData, 'SBQQ__Type__c');
        Integer offAttorneys = CoreCPQCalculationService.convertToInteger(mapQuoteData, 'of_Attorneys__c');
        Double priorQuantityOfQuote = CoreCPQCalculationService.convertToDouble(mapQuoteData, 'Prior_Quantity__c');
        
        
        for(Map<String, Object> lineRec: quoteLinedata){
            String lncrRenewedSub = CoreCPQCalculationService.convertToString(lineRec, 'LNCR__RenewedSubscription__c');
            String renewedSub = CoreCPQCalculationService.convertToString(lineRec, 'SBQQ__RenewedSubscription__c');
            Double quantity = CoreCPQCalculationService.convertToDouble(lineRec, 'SBQQ__Quantity__c');
            String lineId = CoreCPQCalculationService.convertToString(lineRec, 'qliId');
            Boolean isTransProduct = CoreCPQCalculationService.convertToBoolean(lineRec, 'Is_Transactional_Prod__c');
            
            if(quoteType == 'Quote'){
                if(lineId == null || priorQuantityOfQuote == quantity){
                    if(isTransProduct){
                        lineRec.put('SBQQ__Quantity__c', quantity);
                    }else{
                        lineRec.put('SBQQ__Quantity__c',offAttorneys);
                    }
                }else{
                    lineRec.put('SBQQ__Quantity__c', quantity);
                }
            }else{
                system.debug('quoteType--->'+quoteType);
                if(isTransProduct){
                    lineRec.put('SBQQ__Quantity__c', quantity);
                }
                else if((priorQuantityOfQuote == offAttorneys && lineId != null) ||
                        ((quoteType == 'Renewal' || quoteType == 'Replacement') && 
                         lineId == null && (lncrRenewedSub != null || renewedSub != null))){
                             lineRec.put('SBQQ__Quantity__c', quantity);
                         }
                else if((quoteType == 'Renewal' || quoteType == 'Replacement') && lineId != null && 
                        priorQuantityOfQuote != quantity){
                            lineRec.put('SBQQ__Quantity__c', quantity);
                        }
                else if(quoteType != CPQConstants.QUOTE_TYPE_AMENDMENT){
                    lineRec.put('SBQQ__Quantity__c', offAttorneys);
                }
            }
        }
    }
    
    
    /**
*   This method applies program discounts on the Quote based on promo name and bridge program details.  
* - If a Promo_Name__c exists, it retrieves the related program and updates Programs_and_Promos1__c.  
* - If the Bridge_ProgramF__c is different from the previous bridge program.
**/
    public static void applyProgramDiscountsBasedonProgramSelected(Map<String, Object> mapQuoteData) {
        String promoName = CoreCPQCalculationService.convertToString(mapQuoteData, 'Promo_Name__c');
        String bridgeProgram = CoreCPQCalculationService.convertToString(mapQuoteData, 'Bridge_ProgramF__c');
        String prevBridgeProgram = CoreCPQCalculationService.convertToString(mapQuoteData, 'Prev_Bridge_Program__c');
        
        if (promoName != null) {
            List<Programs_and_Promos__c> promoList = [
                SELECT Id 
                FROM Programs_and_Promos__c 
                WHERE Name =: promoName 
            ];
            
            if (!promoList.isEmpty()) {
                mapQuoteData.put('Programs_and_Promos1__c', promoList[0].Id);
            }
        }
        system.debug('Program Discount - '+CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Program_Discount__c'));
        if (bridgeProgram != null && bridgeProgram != prevBridgeProgram) {
            List<Programs_and_Promos__c> programList = [
                SELECT Id, Program_Discount__c 
                FROM Programs_and_Promos__c 
                WHERE Name =: bridgeProgram 
            ];
            system.debug('programList -'+programList);
            if (!programList.isEmpty()) {
                mapQuoteData.put('Programs_and_Promos__c', programList[0].Id);
                mapQuoteData.put('Program_Discount__c', programList[0].Program_Discount__c);
                mapQuoteData.put('Max_Program_Discount_Allowed__c', programList[0].Program_Discount__c);
                mapQuoteData.put('Prev_Bridge_Program__c', bridgeProgram);
            }
        }
        //debug logs
        System.debug('promoName- ' + promoName + ' bridgeProgram- ' + bridgeProgram + ' prevBridgeProgram- ' + prevBridgeProgram + 'Program_Discount__c- ' + mapQuoteData.get('Program_Discount__c'));
    }
    
    
    
    /**
*   This method applies the program discount to Quote Line Items calculated from applyProgramDiscountsOnQuote Method.  
* - It retrieves the Program_Discount__c and FirstSegmentTermEndDate__c from the Quote.
* - It applies the discount only to the first segment (SBQQ__SegmentIndex__c = 1).
* - For all other segments, the discount remains 0.  
**/    
    public static void calulcateDiscountFromProgramDiscountOnQuoteline(Map<String, Object> mapQuoteData, List<Map<String,Object>> quoteLineData){
        Decimal programDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Program_Discount__c');
        Date firstSegmentEndDate = CoreCPQCalculationService.convertToDate(mapQuoteData, 'SBQQ__FirstSegmentTermEndDate__c');
        for(Map<String,Object> lineRecord : quoteLineData){
            lineRecord.put('SBQQ__Discount__c', 0);
            if(programDiscount != null && programDiscount != 0 && firstSegmentEndDate != null){
                Double segmentIndex = CoreCPQCalculationService.convertToDouble(lineRecord , 'SBQQ__SegmentIndex__c');
                if(segmentIndex == 1){
                    system.debug('programDiscount-' + programDiscount);
                    lineRecord.put('SBQQ__Discount__c', programDiscount);
                }
            }
        }
        //debug logs
        System.debug('programDiscount- ' + programDiscount + ' firstSegmentEndDate- ' + firstSegmentEndDate);
    }
    
    /**
* This method calculates and applies the depth discount on a Quote based on various criteria.  
* - The method calculates the per-attorney monthly price.  
* - It retrieves relevant depth discount records from the Depth_Discount__c object.
* - The discount is capped at a maximum of 37%.  
**/
    public static void calculateDepthDiscountOnQuote(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData,'SBQQ__Type__c');
        Boolean bundleCCHPresent = false;
        Double ofAttorneys = CoreCPQCalculationService.convertToDouble(mapQuoteData, 'of_Attorneys__c');
        Decimal monthlyPricePerAtt = 0;
        Decimal firstSegmentListAmount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'First_Segment_List_Amount2__c');
        Decimal firstSegmentProductList = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'FirstSegment_Free_Product_List__c');
        Integer termOfYears = CoreCPQCalculationService.convertToInteger(mapQuoteData, 'Term_of_Years__c');
        Integer depthDiscountStateTier = CoreCPQCalculationService.convertToInteger(mapQuoteData, 'Depth_Discount_State_Tier__c');
        
        for(Map<String, Object> lineRecord : quoteLinedata) {
            //Check if CCH Bundle added - not to apply depth discount
            if(CoreCPQCalculationService.convertToString(lineRecord, 'SBQQ__ProductCode__c') == 'LNLPCCH'){
                bundleCCHPresent = true;
            }
        }
        if (bundleCCHPresent == false) {
            Decimal calDepthDis = 0;
            if(ofAttorneys > 0){
                monthlyPricePerAtt = (firstSegmentListAmount - (firstSegmentProductList)) / ofAttorneys;
            }
            mapQuoteData.put('Depth_Discount__c', 0);
            if ((quoteType == 'Quote' && monthlyPricePerAtt != null) ||
                ((quoteType == 'Renewal' || quoteType == 'Replacement') && monthlyPricePerAtt != null)) {
                    List<Depth_Discount__c> depthDiscountList = [Select Id,Marginal_Discount__c,Per_Attorney_List_Price_High__c,Per_Attorney_List_Price_Low__c,Depth_Discount_Percent__c,State_Tier__c From Depth_Discount__c];
                    if(!depthDiscountList.isEmpty()){
                        for(Depth_Discount__c depthDisRec : depthDiscountList){
                            if (depthDisRec.State_Tier__c == depthDiscountStateTier &&
                                depthDisRec.Per_Attorney_List_Price_High__c >= monthlyPricePerAtt &&
                                depthDisRec.Per_Attorney_List_Price_Low__c <= monthlyPricePerAtt) {
                                    mapQuoteData.put('Depth_Discount_Lookup__c', depthDisRec.Id);
                                    if(monthlyPricePerAtt > 0){
                                        System.debug('monthlyPricePerAtt---'+monthlyPricePerAtt);
                                        calDepthDis = ((depthDisRec.Per_Attorney_List_Price_Low__c * depthDisRec.Depth_Discount_Percent__c) + ((monthlyPricePerAtt - depthDisRec.Per_Attorney_List_Price_Low__c) * depthDisRec.Marginal_Discount__c)) / monthlyPricePerAtt;
                                    }
                                    if (calDepthDis > 37) {
                                        mapQuoteData.put('Depth_Discount__c', 37);
                                    } else if (calDepthDis > 0 && calDepthDis < 37) {
                                        mapQuoteData.put('Depth_Discount__c', calDepthDis);
                                    } else {
                                        mapQuoteData.put('Depth_Discount__c', 0);
                                    }
                                }
                        }
                    }
                } 
        } 
        
    }
    
    
    /**
* This method calculates the discretionary discount on a Quote.    
* - If a target customer amount is specified, it calculates the discretionary discount using the formula:  
*   - (List Amount - Free Product List - Target Amount) / (List Amount - Free Product List)  
* - Then adjusts the discount by subtracting the Sum of product mix and depth discount. 
*/
    public static void calculateDiscretionaryDiscountOnQuote(Map<String, Object> mapQuoteData){    
        Decimal firstSegmentListAmount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'First_Segment_List_Amount2__c');
        Decimal fistSegmentFreeProductList = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'FirstSegment_Free_Product_List__c');
        Decimal targetCustomerAmount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Negotiated_Price_Target__c');
        String cpqComposite = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');

        

        System.debug('targetCustomerAmount'+targetCustomerAmount);
        Decimal productMixDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Product_Mix_Discount__c');
        Decimal depthDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Depth_Discount__c');
        Decimal multiYearTermDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Multi_Year_Term_Discount__c');
        Decimal termOrProductMixDiscount  = cpqComposite ==  CPQConstants.CPQ_COMPOSITE_SMALL_LAW ? multiYearTermDiscount : productMixDiscount;
        
        if(targetCustomerAmount > 0){
            Decimal numerator = firstSegmentListAmount - fistSegmentFreeProductList - targetCustomerAmount;
            Decimal denominator = firstSegmentListAmount - fistSegmentFreeProductList;
            Decimal discount = (termOrProductMixDiscount + depthDiscount) / 100;
            if(denominator != 0){
                Decimal result = (numerator / denominator) - discount;
                mapQuoteData.put('Discretionary_Discount__c',  result*100);
            }
            
            
        }
    }
    
    /**
* This method calculates the Product Mix Discount on a Quote.  
* - Product Mix Discount is calculated as the sum of the discounts on Court Materials, News, 
*   Litigation Tools, Public Records, Secondary Practical, Premier Research Suite and Core offering state product mix discount.  
* - If the sum of the discounts exceeds 10%, the Product Mix Discount is capped at 10%. 
**/
    public static void calculateProductMixDiscountOnQuote(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata) {
        Boolean productMixDiscountEligible = CoreCPQCalculationService.convertToBoolean(mapQuoteData, 'Product_Mix_Discount_Eligible__c');
        Decimal courtMaterialsDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Court_Materials_Discount__c');
        Decimal newsDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'News_Discount__c');
        Decimal litigationToolsDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Litigation_Tools_Discount__c');
        Decimal publicRecordsDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Public_Records_Discount__c');
        Decimal secondaryPracticalDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Secondary_Practical_Discount__c');
        Decimal premierResearchSuiteDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Premier_Research_Suite_Discount__c');
        Decimal sumOfStateProductMixDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Core_Offering_State_Product_Mix_Discount__c');

        if (productMixDiscountEligible) {
            Decimal discountSumUp = (courtMaterialsDiscount + newsDiscount + litigationToolsDiscount + publicRecordsDiscount + secondaryPracticalDiscount + premierResearchSuiteDiscount + sumOfStateProductMixDiscount) * 100;
            system.debug('discountSumUp--' + discountSumUp);    
            if(discountSumUp > 10) {
                mapQuoteData.put('Product_Mix_Discount__c', 10);
            } else {
                mapQuoteData.put('Product_Mix_Discount__c', discountSumUp);
            }
        } else {
            mapQuoteData.put('Product_Mix_Discount__c', 0);
        }
        for(Map<String, Object> line : quoteLinedata) {
            if ((mapQuoteData.get('Product_Mix_Discount__c') != null) 
                && CoreCPQCalculationService.convertToString(line, 'RequiredByProductName') != 'CCH' && CoreCPQCalculationService.convertToString(line, 'SBQQ__ProductName__c') != 'CCH'){
                    line.put('Product_Mix_Discount__c', mapQuoteData.get('Product_Mix_Discount__c'));
                }
        }
    }
    
    
    /**
* This method calculates the partner discount on a Quote.
* - If the Quote is not a trial and was not generated from 'AAR' or 'Fixed Term Extension',  
* - it sums up the discretionary, product mix, and depth discounts to determine the partner discount.
*/
    public static void calculatePartnerDiscountOnQuote(Map<String, Object> mapQuoteData){
        Boolean trialFlag = CoreCPQCalculationService.convertToBoolean(mapQuoteData,'Trial_Flag__c');
        String generatedFrom = CoreCPQCalculationService.convertToString(mapQuoteData,'Generated_From__c');
        String cpqComposite = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');
        Decimal discretionaryDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'Discretionary_Discount__c');
        Decimal multiYearTermDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Multi_Year_Term_Discount__c');
        Decimal productMixDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'Product_Mix_Discount__c');
        Decimal depthDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'Depth_Discount__c');
        
        Decimal termOrProductMixDiscount  = cpqComposite == CPQConstants.CPQ_COMPOSITE_SMALL_LAW ? multiYearTermDiscount : productMixDiscount;
        if(trialFlag == false && generatedFrom != 'AAR' &&  generatedFrom != 'Fixed Term Extension'){
            Decimal partnerDiscount = discretionaryDiscount + termOrProductMixDiscount + depthDiscount;
            mapQuoteData.put('SBQQ__PartnerDiscount__c',partnerDiscount);
        }
        //debug logs
        System.debug('trialFlag- ' + trialFlag + ' generatedFrom- ' + generatedFrom + ' discretionaryDiscount- ' + discretionaryDiscount + ' productMixDiscount- ' + productMixDiscount + ' depthDiscount- ' + depthDiscount + 'PartnerDiscount- ' + mapQuoteData.get('SBQQ__PartnerDiscount__c'));
    }
    
    
    
    /**
* - This method determines the minimum term eligibility for a quote.  
* - It evaluates whether the 'Term_of_Years__c' field meets the minimum required term for the given Bridge Program and Promo Name.
* - Checks if the term of years meets the eligibility requirements for specific Bridge Programs and Promo Names.
**/
    public static void minOfYearsEligibility(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        Integer term = CoreCPQCalculationService.convertToInteger(mapQuoteData, 'Term_of_Years__c');
        String  bridgeProgram =CoreCPQCalculationService.convertToString(mapQuoteData, 'Bridge_Program__c');
        String promoName = CoreCPQCalculationService.convertToString(mapQuoteData, 'Promo_Name__c');
        
        Boolean result = true;
        switch on bridgeProgram {
            when 'WestBridge', 'WestBridge_PLUS', 'LLP', 'Switch 2022'{
                result = (term >= 2);
                System.debug('bridgeProgram--'+bridgeProgram);
                System.debug('result -----'+result);
            }
            when 'Lexis Select-SL', '--None--', 'Lexis Intro', 'Lexis Intro Plus'{
                result = (term >= 1);
            }
            when 'Lexis Select 21+'{
                result = (term >= 3);
            }
        }
        if(result){
            switch on promoName {
                when 'SL-3 Year Deal'{
                    result = ( term >= 3);
                }
                when else {
                    result = true;
                }
            }
        }
        System.debug('Min_of_Years_Eligibility__c'+result);
        mapQuoteData.put('Min_of_Years_Eligibility__c' ,result);
    }
    
    
    /**
* This method checks whether the selected Promo Name and Bridge Program are compatible.
* - If both Promo Name and Bridge Program are provided, it queries the  
*   Compatible_Program_Promotions__c object to find a matching record where
* - If a matching record exists, it sets 'Program_Promo_Is_Compatible__c' to true.  
*/
    public static void checkProgramAndPromoCompatibility(Map<String, Object> mapQuoteData) {
        String promoName = CoreCPQCalculationService.convertToString(mapQuoteData, 'Promo_Name__c');
        String bridgeProgram = CoreCPQCalculationService.convertToString(mapQuoteData, 'Bridge_Program__c');
        String bridgeProgramF = CoreCPQCalculationService.convertToString(mapQuoteData, 'Bridge_ProgramF__c');
        
        if (promoName != '' && bridgeProgram != '') {
            List<Compatible_Program_Promotions__c> listOfAssignments = [
                SELECT Promotions_Name__c, Programe_Name__c 
                FROM Compatible_Program_Promotions__c 
                WHERE 
                Promotions_Name__c =: promoName AND Programe_Name__c =: bridgeProgramF
            ];
            
            if(!listOfAssignments.isEmpty()) {
                mapQuoteData.put('Program_Promo_Is_Compatible__c', true);
            }
            
        }
    }
    
    
    /**
* This method populates the generic product price on Quote Lines.
* - Queries the PricebookEntry object to retrieve the unit price for the product code Matching Generic Product Code and Jurisdiction.
* - The retrieved price entries are stored in a map with a key format of 'ProductCode-Jurisdiction'.
* - It iterates through the quote lines and updates the 'SBQQ__ListPrice__c' field.
**/
    public static void populateGenericProductPriceOnQLs(Map<String, Object> mapQuoteData, List<Map<String,Object>> quoteLineData) {
        String cpqComposite = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');
        List<String> lstOfProductCodes = new List<String>();
        List<String> lstOfJurisdiction = new List<String>();
        Map<String, PricebookEntry> mapOfPriceBookEntries = new Map<String, PricebookEntry>();
        for(Map<String,Object> quoteLine: quoteLineData){
            
            String productCode = CoreCPQCalculationService.convertToString(quoteLine, 'SBQQ__ProductCode__c');
            lstOfProductCodes.add(productCode);
            String jurisdiction = CoreCPQCalculationService.convertToString(quoteLine, 'Jurisdiction__c');
            lstOfJurisdiction.add(jurisdiction);
        }
        List<PricebookEntry> priceBookEntry = [
            SELECT UnitPrice , Generic_State_Product_Code__c, Jurisdiction__c
            FROM PricebookEntry 
            WHERE 
            Generic_State_Product_Code__c IN : lstOfProductCodes AND Jurisdiction__c IN: lstOfJurisdiction
        ];
        for(PricebookEntry pbe: priceBookEntry){
            String key = pbe.Generic_State_Product_Code__c + '-' + pbe.Jurisdiction__c;
            mapOfPriceBookEntries.put(key,pbe);
        }
        
        for(Map<String,Object> quoteLine: quoteLineData){
            String productCode = CoreCPQCalculationService.convertToString(quoteLine, 'SBQQ__ProductCode__c');
            String jurisdiction = CoreCPQCalculationService.convertToString(quoteLine, 'Jurisdiction__c');
            String key = productCode + '-' + jurisdiction;
            if(mapOfPriceBookEntries.containsKey(key)){
                quoteLine.put('SBQQ__ListPrice__c',mapOfPriceBookEntries.get(key).UnitPrice);
            }
        }    
    }
    
    
    
    /**
* This method determines the eligibility of a negotiated price per attorney for a quote.
* - Based on the platform type selected, it queries the 'Target_CPA_Range__c' object to check if 
*   the given negotiated price per attorney falls within the allowed range for the specified 
*   number of attorneys.
* - The logic is applied separately for 'Lexis', 'Lexis+', and 'Lexis+ AI' platforms.
**/
    public static void calculateNegotiatedPriceEligibilityOnQuote(Map<String, Object> mapQuoteData) {
        String platform = CoreCPQCalculationService.convertToString(mapQuoteData, 'Platform__c');
        String promoName = CoreCPQCalculationService.convertToString(mapQuoteData, 'Promo_Name__c');
        Decimal ofAttorneys = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'of_Attorneys__c');
        Decimal negotiatedPricePerAttorney = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Negotiated_price_per_attorney__c');
        
        //Lexis Platform
        if(promoName != null && platform != null && promoName.equals('SL - Target CPA') && platform.equals('Lexis')) {
            List<Target_CPA_Range__c> targetCpaRange = [
                SELECT Id, Lexis_Plus_Target_CPA__c 
                FROM Target_CPA_Range__c 
                WHERE 
                Lexis_Plus_Target_CPA__c != 0 AND Lexis_Target_CPA__c != 0 AND of_Attorneys_high__c >: ofAttorneys AND Lexis_Target_CPA__c >: negotiatedPricePerAttorney AND of_Attorneys_low__c <=: ofAttorneys
            ];
            System.debug('targetCpaRange present in Lexis' + targetCpaRange.isEmpty());
            if (!targetCpaRange.isEmpty()) {
                mapQuoteData.put('Negotiated_Price_Eligibility__c', false);
            }
        }
        
        //Lexis Plus
        if(promoName != null && platform != null && promoName.equals('SL - Target CPA') && platform.equals('Lexis+')) {
            List<Target_CPA_Range__c> targetCpaRange = [
                SELECT Id, Lexis_Plus_Target_CPA__c 
                FROM Target_CPA_Range__c 
                WHERE 
                Lexis_Plus_Target_CPA__c != 0 AND Lexis_Target_CPA__c != 0 AND of_Attorneys_high__c >: ofAttorneys AND Lexis_Plus_Target_CPA__c >: negotiatedPricePerAttorney AND of_Attorneys_low__c <=: ofAttorneys
            ];
            System.debug('targetCpaRange present Plus' + targetCpaRange.isEmpty());
            if (!targetCpaRange.isEmpty()) {
                mapQuoteData.put('Negotiated_Price_Eligibility__c', false);
            }
        }
        //Lexis Plus AI
        if(promoName != null && platform != null && promoName.equals('SL - Target CPA') && platform.equals('Lexis+ AI')) {
            List<Target_CPA_Range__c> targetCpaRange = [
                SELECT Id, Lexis_Plus_Target_CPA__c 
                FROM Target_CPA_Range__c 
                WHERE 
                Lexis_Plus_Target_CPA__c != 0 AND Lexis_Target_CPA__c != 0 AND of_Attorneys_high__c >: ofAttorneys AND Lexis_Plus_AI_Target_CPA__c >: negotiatedPricePerAttorney AND of_Attorneys_low__c <=: ofAttorneys
            ];
            System.debug('targetCpaRange present in Lexis' + targetCpaRange.isEmpty());
            if (!targetCpaRange.isEmpty()) {
                mapQuoteData.put('Negotiated_Price_Eligibility__c', false);
            }
        }
    }
    
    
    /**
* This method calculates the term of years.
*
* - Computes the remaining term by subtracting the bridge period from the subscription term.
* - If the quote type (SBQQ__Type__c) is 'Replacement' as In New Business we manually select the Term of Year
*   - If the remaining term is 60 months or more, the term is set to 5 years.
*   - Otherwise, the term is determined by dividing the remaining months by 12
**/
    public static void calculateTermOfYear(Map<String, Object> mapQuoteData){
        Double subscriptionTerm = CoreCPQCalculationService.convertToDouble(mapQuoteData, 'SBQQ__SubscriptionTerm__c');
        Integer bridgePeriodMonth = CoreCPQCalculationService.convertToInteger(mapQuoteData, 'Bridge_Period_Months__c');    
        Integer remainingTerm = Math.round(subscriptionTerm - bridgePeriodMonth);
        if(CoreCPQCalculationService.convertToString(mapQuoteData, 'SBQQ__Type__c') == 'Replacement'){
            if(remainingTerm >= 60){
                mapQuoteData.put('Term_of_Years__c','5');
            }else{
                if(remainingTerm / 12 == 0){
                    mapQuoteData.put('Term_of_Years__c','1');
                }else{
                    mapQuoteData.put('Term_of_Years__c', String.valueOf(remainingTerm / 12));
                }
            }
        }
        //debug logs
        System.debug('subscriptionTerm- ' + subscriptionTerm + ' bridgePeriodMonth- ' + bridgePeriodMonth + ' remainingTerm- ' + remainingTerm + ' Term_of_Years__c- ' + mapQuoteData.get('Term_of_Years__c'));
    }
    
    
    /**
* Calculates the bridge period in months for a quote.
*
* - Calculates the total months by determining the difference in years 
*   and months between the start date and the first segment term end date.
* - Adjusts the total months based on the day of the month to ensure proper rounding.
**/
    public static void calculateBridgePeriodOfMonthsOnQuote(Map<String, Object> mapQuoteData) {
        Date westBridgeEndDate = CoreCPQCalculationService.convertToDate(mapQuoteData,'WestBridge_Bridge_End_Date__c');
        Date firstSegTermEndDate = CoreCPQCalculationService.convertToDate(mapQuoteData,'SBQQ__FirstSegmentTermEndDate__c');
        Date start = CoreCPQCalculationService.convertToDate(mapQuoteData, 'SBQQ__StartDate__c');
        if (firstSegTermEndDate == null && westBridgeEndDate == null) {
            mapQuoteData.put('Bridge_Period_Months__c', 0);
        }else{
            Integer yearDiff = Integer.valueOf(firstSegTermEndDate.year() - start.year());
            Integer monthDiff = Integer.valueOf(firstSegTermEndDate.month() - start.month());
            Integer totalMonths = yearDiff * 12 + monthDiff;
            
            if (start.day() > 1 && firstSegTermEndDate.day() < start.day()) {
                totalMonths += 0;
            } else {
                totalMonths += 1;
            }
            mapQuoteData.put('Bridge_Period_Months__c', totalMonths);
        }
        
    }
    
    
    /** 
* - This method used to calculate the SBQQ__FirstSegmentTermEndDate__c on the Quote.
* - It checks the conditions based on the quote type, bridge program, and other parameters to determine the First Segment End Date.
* - It is OOTB Functionality to calculate the First Segment End Date. But in case of Bridge Program we Explicit Update the First Segment Term End Date Field.  
**/    
    public static void calculateFirstSegmentTermEndDateOnQuote(Map<String, Object> mapQuoteData){
        Date firstSegmentTermEndDateModifier = CoreCPQCalculationService.convertToDate(mapQuoteData, 'First_Segment_Term_End_Date_Modifier__c');
        Date westBridgeBridgeEndDate = CoreCPQCalculationService.convertToDate(mapQuoteData,'WestBridge_Bridge_End_Date__c');
        String bridgeProgram =  CoreCPQCalculationService.convertToString(mapQuoteData, 'Bridge_Program__c');
        String type = CoreCPQCalculationService.convertToString(mapQuoteData,'SBQQ__Type__c');
        String westBridgeProgramFromPreviousQuote = CoreCPQCalculationService.convertToString(mapQuoteData, 'WestBridge_Program_from_Previous_Quote__c'); 
        Date priorSegmentEndDate = CoreCPQCalculationService.convertToDate(mapQuoteData, 'PriorSegmentEndDate__c');
        Date startDate = CoreCPQCalculationService.convertToDate(mapQuoteData, 'SBQQ__StartDate__c');
        Date endDateFromPreviousQuote = CoreCPQCalculationService.convertToDate(mapQuoteData, 'End_Date_from_Previous_Quote__c');
        Boolean resegmentLogicFlag = CoreCPQCalculationService.convertToBoolean(mapQuoteData, 'Resegment_Legacy_Line_Flag__c');
        Boolean backdatingOrderAllowed = CoreCPQCalculationService.convertToBoolean(mapQuoteData, 'Backdating_Order_Allowed__c');
        Date resegmentLineLogic = CoreCPQCalculationService.convertToDate(mapQuoteData, 'Resegment_Lines_Logic__c');
        Date endDateFromPreviousQte = CoreCPQCalculationService.convertToDate(mapQuoteData, 'End_Date_from_Previous_Quote__c');
        
        if(type != 'Amendment'){
            if (firstSegmentTermEndDateModifier != null && westBridgeBridgeEndDate == null) {
                mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c',firstSegmentTermEndDateModifier);
            }
            else if (westBridgeBridgeEndDate != null && bridgeProgram != null && bridgeProgram != '' ) {
                if (type !=null && bridgeProgram.equals('WestBridge_PLUS') && type.equals('Replacement') &&
                    (westBridgeProgramFromPreviousQuote  != null && westBridgeProgramFromPreviousQuote.equals('WestBridge_PLUS'))) {
                        mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c',priorSegmentEndDate);
                } 
                else {
                    System.debug('Enter in the block');
                    mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c',westBridgeBridgeEndDate);
                    System.debug('SBQQ__FirstSegmentTermEndDate__c'+ mapQuoteData.get('SBQQ__FirstSegmentTermEndDate__c'));
                }
            } else if (type.equals('Replacement') && westBridgeBridgeEndDate == null && backdatingOrderAllowed != true) {
                if (resegmentLogicFlag) {
                    mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c',resegmentLineLogic);
                } else if (priorSegmentEndDate != null && priorSegmentEndDate >= startDate) {
                    mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c',priorSegmentEndDate);
                } else if (priorSegmentEndDate != null && priorSegmentEndDate < startDate && startDate < endDateFromPreviousQuote) {
                    mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c',calculateFirstSegmentEndDate(priorSegmentEndDate,startDate));
                }
            }
            else {
                mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c',null);      
            }
        } 
        //Amendment case 
        else if(westBridgeBridgeEndDate == null){
            if (resegmentLogicFlag) {
                mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c',resegmentLineLogic);
            } else if (priorSegmentEndDate != null && priorSegmentEndDate >= startDate) {
                mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c',priorSegmentEndDate);
            } else if (priorSegmentEndDate != null && priorSegmentEndDate < startDate && startDate < endDateFromPreviousQuote) {
                mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c',calculateFirstSegmentEndDate(priorSegmentEndDate,startDate));
            }
            
        }
        //debug logs
        System.debug('firstSegmentTermEndDateModifier- ' + firstSegmentTermEndDateModifier + ' westBridgeBridgeEndDate- ' + westBridgeBridgeEndDate + ' bridgeProgram- ' + bridgeProgram + ' type- ' + type + ' westBridgeProgramFromPreviousQuote- ' + westBridgeProgramFromPreviousQuote + ' priorSegmentEndDate- ' + priorSegmentEndDate + ' startDate- ' + startDate + ' resegmentLogicFlag- ' + resegmentLogicFlag + ' SBQQ__FirstSegmentTermEndDate__c- '+ mapQuoteData.get('SBQQ__FirstSegmentTermEndDate__c'));
    }
    
    /**
* Calculates the end date for a quote.
* - It checks various conditions based on the quote type, bridge program, and other parameters to determine the quote end date.
* - The method handles special cases for leap years and specific date conditions.
*/
    public static Date calculateEndDateOnQuote(Map<String, Object> mapQuoteData){
        // Extracting fields from the quote record
        
        Date endDateModifier = CoreCPQCalculationService.convertToDate(mapQuoteData, 'End_Date_Modifier__c');
        String bridgeProgram = CoreCPQCalculationService.convertToString(mapQuoteData, 'Bridge_ProgramF__c');
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData, 'SBQQ__Type__c');
        Date raceEnhancedEndDate = CoreCPQCalculationService.convertToDate(mapQuoteData, 'Race_Enhanced_End_Date__c');
        Integer extendedTermOfYears = CoreCPQCalculationService.convertToString(mapQuoteData, 'Extended_Term_of_Years__c') == null ? 0 : CoreCPQCalculationService.convertToInteger(mapQuoteData, 'Extended_Term_of_Years__c');
        Date originalQuoteEndDate = CoreCPQCalculationService.convertToDate(mapQuoteData, 'Original_Quote_End_Date__c');
        Integer termOfYears = CoreCPQCalculationService.convertToInteger(mapQuoteData, 'Term_of_Years__c');
        Date firstSegmentTermEndDate = CoreCPQCalculationService.convertToDate(mapQuoteData, 'SBQQ__FirstSegmentTermEndDate__c');
        Date startDate = CoreCPQCalculationService.convertToDate(mapQuoteData, 'SBQQ__StartDate__c');
        Date customStartDate = CoreCPQCalculationService.convertToDate(mapQuoteData, 'Start_Date__c');
        Date endDate = CoreCPQCalculationService.convertToDate(mapQuoteData, 'SBQQ__EndDate__c');
        
        if (endDateModifier == null) {
            if (bridgeProgram == 'RACE Enhanced' && quoteType == 'Replacement' && raceEnhancedEndDate != null) {
                mapQuoteData.put('SBQQ__EndDate__c', raceEnhancedEndDate);
                return raceEnhancedEndDate;
            }
            
            if (extendedTermOfYears != null && originalQuoteEndDate != null && quoteType == 'Replacement') {
                Date originalDate = originalQuoteEndDate;
                Integer originalYear = originalDate.year() + extendedTermOfYears;
                Integer originalMonth = originalDate.month();
                Integer originalDay = originalDate.day();
                
                if (originalDay == 29 && originalMonth == 2 && extendedTermOfYears != 4) {
                    mapQuoteData.put('SBQQ__EndDate__c',Date.newInstance(originalYear, 2, 28));
                    return Date.newInstance(originalYear, 2, 28);
                }
                if (originalDay == 28 && originalMonth == 2 && Date.isLeapYear(originalYear)) {
                    mapQuoteData.put('SBQQ__EndDate__c', Date.newInstance(originalYear, 2, 29));
                    return Date.newInstance(originalYear, 2, 29);
                }
                if (originalDay == 29 && originalMonth == 2 && extendedTermOfYears == 4) {
                    mapQuoteData.put('SBQQ__EndDate__c', Date.newInstance(originalYear, 2, 29));
                    return Date.newInstance(originalYear, 2, 29);
                }
                
                mapQuoteData.put('SBQQ__EndDate__c', Date.newInstance(originalYear, originalMonth, originalDay));
                return Date.newInstance(originalYear, originalMonth, originalDay);
            }
            
            if (termOfYears != 0 && quoteType != 'Replacement') {
                if (firstSegmentTermEndDate != null) {
                    System.debug('firstSegmentTermEndDate'+firstSegmentTermEndDate);
                    Date firstSegmentDate = firstSegmentTermEndDate;
                    Integer firstSegmentYear = firstSegmentDate.year() + termOfYears;
                    Integer firstSegmentMonth = firstSegmentDate.month();
                    Integer firstSegmentDay = firstSegmentDate.day();
                    if(termOfYears != 0.5){
                        
                        if (firstSegmentDay == 29 && firstSegmentMonth == 2 && !Date.isLeapYear(firstSegmentYear)) {
                            mapQuoteData.put('SBQQ__EndDate__c', Date.newInstance(firstSegmentYear, 2, 28));
                            return Date.newInstance(firstSegmentYear, 2, 28);
                        }
                        if (firstSegmentDay == 28 && firstSegmentMonth == 2 && Date.isLeapYear(firstSegmentYear)) {
                            mapQuoteData.put('SBQQ__EndDate__c', Date.newInstance(firstSegmentYear, 2, 29));
                            return Date.newInstance(firstSegmentYear, 2, 29);
                        }
                        if (firstSegmentDay == 29 && firstSegmentMonth == 2 && termOfYears == 4) {
                            mapQuoteData.put('SBQQ__EndDate__c', Date.newInstance(firstSegmentYear, 2, 29));
                            return Date.newInstance(firstSegmentYear, 2, 29);
                        }
                        mapQuoteData.put('SBQQ__EndDate__c', Date.newInstance(firstSegmentYear, firstSegmentMonth, firstSegmentDay));
                        system.debug('End date 552 '+Date.newInstance(firstSegmentYear, firstSegmentMonth, firstSegmentDay));
                        return Date.newInstance(firstSegmentYear, firstSegmentMonth, firstSegmentDay);
                        
                    }
                    else{
                        Integer newMonth = Math.MOD((firstSegmentMonth + 6 - 1), 12) + 1;
                        Integer newYear = firstSegmentYear + Math.floor((firstSegmentMonth + 6 - 1) / 12).intValue();
                        if ((firstSegmentDay == 30 && firstSegmentMonth == 8) || 
                            (firstSegmentDay == 31 && (firstSegmentMonth == 1 || firstSegmentMonth == 3 || firstSegmentMonth == 5 || firstSegmentMonth == 8 || firstSegmentMonth == 10 || firstSegmentMonth == 12))) 
                        {
                            mapQuoteData.put('SBQQ__EndDate__c', Date.newInstance(newYear, newMonth, firstSegmentDay - 1));
                            return Date.newInstance(newYear, newMonth, firstSegmentDay - 1);
                        }
                        mapQuoteData.put('SBQQ__EndDate__c', Date.newInstance(newYear, newMonth, firstSegmentDay));
                        return Date.newInstance(newYear, newMonth, firstSegmentDay);
                    }
                }
                if (termOfYears != 0.5) {
                    System.debug('termOfY'+termOfYears);
                    if (startDate != null) {
                        System.debug('startDate'+startDate);
                        Date start = startDate;
                        Integer startYear = start.year() + termOfYears;
                        Integer startMonth = start.month();
                        Integer startDay = start.day();
                        
                        if (startDay == 29 && startMonth == 2) {
                            mapQuoteData.put('SBQQ__EndDate__c', Date.newInstance(startYear, startMonth, 28));							                         
                            return Date.newInstance(startYear, startMonth, 28);
                        }else{
                            mapQuoteData.put('SBQQ__EndDate__c', Date.newInstance(startYear, startMonth, startDay - 1));
                            return Date.newInstance(startYear, startMonth, startDay - 1);
                        }
                        
                        
                    }
                }
            }
            
            if (termOfYears == 0.5) {
                System.debug('termOfY'+termOfYears);
                
                if (customStartDate <> null) {
                    System.debug('startDate'+startDate);
                    Date start = customStartDate;
                    Integer month = start.month() + 6 - 1;
                    Integer modOfMonth = Math.MOD(month, 12) + 1;
                    Integer modOfMonthMinusOne = Math.MOD((month - 1), 12) + 1; 
                    Integer year = start.year() + Math.floor(month / 12).intValue();
                    Integer day = start.day();
                    
                    if (day > Date.daysInMonth(year, modOfMonth)) {
                        month = month + 1;
                    }
                    
                    Integer finalMonth = Math.MOD(month, 12) + 1;
                    if (day > Date.daysInMonth(year, modOfMonthMinusOne)) {
                        day = Date.daysInMonth(year, modOfMonthMinusOne) + 1;
                    }
                    
                    mapQuoteData.put('SBQQ__EndDate__c', Date.newInstance(year, month, day - 1));
                    return Date.newInstance(year, month, day - 1);
                }
            }
        }
        
        return endDate;
    }
    
    
    /**
* Calculates the WestBridge Bridge End Date for a quote 
* - Applies specific rules for different bridge programs such as RACE, Customer Appreciation, 
*   Lexis Select, WestBridge, LLP, and Switch 2022.
* - Adjusts the WestBridge end date based on attorney count, term duration, and eligibility for free time.
* - Uses predefined durations (1 years , 2 years , 3 years) for different bridge programs.
**/
    public static void calculateWestBridgeEndDateOnQuote(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        Date startDate = CoreCPQCalculationService.convertToDate(mapQuoteData,'SBQQ__StartDate__c');
        Date endDateFromPreviousContract = CoreCPQCalculationService.convertToDate(mapQuoteData, 'End_Date_from_Previous_Quote__c');
        String bridgeProgram = CoreCPQCalculationService.convertToString(mapQuoteData, 'Bridge_Program__c');
        System.debug('bridgeProgram'+bridgeProgram);
        Integer termOfYears = CoreCPQCalculationService.convertToInteger(mapQuoteData, 'Term_of_Years__c');
        Double numAttorneys = CoreCPQCalculationService.convertToDouble(mapQuoteData, 'of_Attorneys__c');
        String freeTime = CoreCPQCalculationService.convertToString(mapQuoteData, 'Free_Time__c');
        String prevBridgeProgram = CoreCPQCalculationService.convertToString(mapQuoteData, 'Prev_Bridge_Program__c');
        Date westBridgeEndDate = CoreCPQCalculationService.convertToDate(mapQuoteData,'WestBridge_Bridge_End_Date__c');
        String type = CoreCPQCalculationService.convertToString(mapQuoteData,'SBQQ__Type__c');
        Integer numberOfCounsel = CoreCPQCalculationService.convertToInteger(mapQuoteData,'Number_of_Of_Counsel__c');
        String defaultWestBridge = CoreCPQCalculationService.convertToString(mapQuoteData, 'PrevBridgeProgram__c');
        System.debug('defaultWestBridge'+defaultWestBridge);
        if(bridgeProgram <> null){
            System.debug('bridgeProgram'+bridgeProgram);
            if(bridgeProgram <> defaultWestBridge){
                System.debug('bridgeProgram one'+bridgeProgram);
                System.debug('defaultWestBridge one'+defaultWestBridge);
                defaultWestBridge = bridgeProgram;
                mapQuoteData.put('PrevBridgeProgram__c',defaultWestBridge);
                system.debug('defaultWestBridge one '+defaultWestBridge);
                if (CoreCPQCalculationService.convertToString(mapQuoteData,'WestBridge_Program_from_Previous_Quote__c') <> null && CoreCPQCalculationService.convertToString(mapQuoteData,'type') <> 'Renewal') {
                    if ((bridgeProgram.equals(CPQConstants.QUOTE_BRIDGE_PROGRAM_RACE) || bridgeProgram.equals(CPQConstants.QUOTE_BRIDGE_PROGRAM_CUSTOMER_APPRECIATION)) ) {
                        if ( numAttorneys <= 5  || bridgeProgram.equals(CPQConstants.QUOTE_BRIDGE_PROGRAM_CUSTOMER_APPRECIATION)) {
                            Date calculatedEndDate = calculateEndDateBasedOnStartDate(startDate);
                            Date result = CoreCPQCalculationService.getAfterDate(calculatedEndDate , endDateFromPreviousContract);
                            mapQuoteData.put('WestBridge_Bridge_End_Date__c',Date.newInstance(result.year(), result.month(), result.day()-1));
                        }
                        else{
                            mapQuoteData.put('WestBridge_Bridge_End_Date__c',calculateWestBridgeEndDate(startDate,12,0));
                        }
                    }
                    if (bridgeProgram.equals(CPQConstants.QUOTE_BRIDGE_PROGRAM_RACE_ENHANCED)) {
                        mapQuoteData.put('WestBridge_Bridge_End_Date__c',calculateWestBridgeEndDate(startDate, 9,0));
                    }
                   
                }
                if(bridgeProgram.equals('Lexis Select 21+') && termOfYears >= 3 && numAttorneys >= 21 && numAttorneys <= 99 && freeTime == 'Yes' || 
                   bridgeProgram.equals('WestBridge') && termOfYears >= 3 && numAttorneys >= 1 && numAttorneys <= 99 && freeTime == 'Yes'){
                       mapQuoteData.put('WestBridge_Bridge_End_Date__c',startDate.addYears(2).addDays(-1));
                       
                   }
                else if((bridgeProgram.equals('Lexis Select-SL') && termOfYears == 1 && numAttorneys >= 1 && numAttorneys <= 20 && freeTime == 'No') ||
                        (bridgeProgram.equals('Lexis Select-SL') && termOfYears >= 2 && numAttorneys >= 1 && numAttorneys <= 20 && freeTime == 'Yes')){
                            mapQuoteData.put('WestBridge_Bridge_End_Date__c',calculateWestBridgeEndDate(startDate,6,0));
                            
                        }
                else if(bridgeProgram.equals('Lexis Select-SL') && termOfYears == 1 && numAttorneys >= 1 && numAttorneys <= 20 && freeTime == 'Yes'){
                    mapQuoteData.put('WestBridge_Bridge_End_Date__c',calculateWestBridgeEndDate(startDate,3,0));
                    
                }
                else if((bridgeProgram.equals('LLP') && termOfYears >= 2 && numAttorneys >= 1 && numAttorneys <= 10 && freeTime == 'Yes') ||
                        (bridgeProgram.equals('WestBridge') && termOfYears == 2 && numAttorneys >= 1 && numAttorneys <= 10 && freeTime == 'Yes') ||
                        (bridgeProgram.equals('Switch 2022') && termOfYears >= 2 && numAttorneys >= 1 && numAttorneys <= 50)){
                            mapQuoteData.put('WestBridge_Bridge_End_Date__c',startDate.addYears(1).addDays(-1));
                        }
                else if(bridgeProgram.equals('WestBridge_PLUS') && termOfYears >= 3 && numAttorneys >= 1 && numAttorneys <= 99 && freeTime == 'No'){
                    mapQuoteData.put('WestBridge_Bridge_End_Date__c',calculateWestBridgeEndDate(startDate,10,1));
                }
                else if(bridgeProgram.equals('WestBridge_PLUS') && termOfYears == 2 && numAttorneys >= 1 && numAttorneys <= 10 && freeTime == 'No'){
                    mapQuoteData.put('WestBridge_Bridge_End_Date__c',calculateWestBridgeEndDate(startDate,10,0));
                }
                else if(bridgeProgram.equals('WestBridge_PLUS') && type == 'Replacement'){
                    mapQuoteData.put('WestBridge_Bridge_End_Date__c',westBridgeEndDate);
                }
                 else if(westBridgeEndDate <> null){
                    mapQuoteData.put('WestBridge_Bridge_End_Date__c',null);
                } 
            }else{
                system.debug('mapQuoteData west bridge one');
                mapQuoteData.put('WestBridge_Bridge_End_Date__c',westBridgeEndDate);
                system.debug('mapQuoteData west bridge--' + mapQuoteData.get('WestBridge_Bridge_End_Date__c'));
            }
        }else{
             system.debug('mapQuoteData west bridge one two');
            mapQuoteData.put('WestBridge_Bridge_End_Date__c',null);
        }
        system.debug('mapQuoteData west bridge--' + mapQuoteData.get('WestBridge_Bridge_End_Date__c'));
    }  
    
    
    /* Method for Dates Calculation utilized in calculateFirstSegmentTermEndDateOnQuote function */
    public Static Date calculateFirstSegmentEndDate(Date priorEndDate, Date startDate){
        Integer monthDifference = startDate.month() - priorEndDate.month();
        Integer yearDifference = startDate.year() - priorEndDate.year();
        Integer numsToAdd = ( startDate.day() > priorEndDate.day() && startDate.month() == priorEndDate.month() ? 1 : 0);
        Decimal result = numsToAdd/12.0;
        //Decimal vavar=  0.03.round(System.RoundingMode.CEILING);
        
        Decimal adjustedYear = ((monthDifference + numsToAdd)  / 12.0 + yearDifference);
        adjustedYear = adjustedYear.round(System.RoundingMode.CEILING);
        Integer targetYear = priorEndDate.Year() + (Integer)adjustedYear;
        
        Integer adjustedDay = priorEndDate.day();
        if(Math.mod(priorEndDate.Year(), 400) == 0 || (Math.mod(priorEndDate.Year(), 4) == 0) && Math.mod(priorEndDate.Year(), 100) != 0){
            if(priorEndDate.month() == 2 && priorEndDate.day() == 29){
                adjustedDay = priorEndDate.day() -1;
            }
        }
        return Date.newInstance(targetYear , priorEndDate.month(),adjustedDay);
    }
    
    
    /* Method for Dates Calculation utilized in calculateFirstSegmentTermEndDateOnQuote function */
    Public Static Date calculateFirstSegmentEndDateWestBridgeEndDate (Date westBridgeBridgeEndDate,Integer monthsToAdd,Integer YearToAdd){
        Integer year = westBridgeBridgeEndDate.year();
        Integer month = westBridgeBridgeEndDate.month();
        Integer day = westBridgeBridgeEndDate.day();
        
        Integer adjustedMonth =  Math.mod((month + monthsToAdd-1),12)+1;
        Integer additionalYears = Integer.valueOf(math.Floor((month + monthsToAdd-1) / 12)+YearToAdd);
        
        // Calculate target year
        Integer targetYear = year + additionalYears;
        Integer lastDayOfMonth = 0;
        
        lastDayOfMonth =  CoreCPQCalculationService.getDaysInMonth(year, adjustedMonth);
        
        if(day == CoreCPQCalculationService.getDaysInMonth(targetYear,month)){
            day =  CoreCPQCalculationService.getDaysInMonth(targetYear,adjustedMonth);
        }
        
        return Date.newInstance(targetYear, adjustedMonth, day);
        
        
    }
    
    /**
* Calculates additional discounts for a quote.
*
* - This method calcualtes the Additional Discounts And Missing Penny on the Quote line.
*/
    public static void calculateAdditionalDiscountsAndMissingPenny(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        String generatedFromQuote = CoreCPQCalculationService.convertToString(mapQuoteData, 'Generated_From__c');
        CoreCPQCalculationService.calculateNegotiatedPriceFromPrevQuote(mapQuoteData);
        CoreCPQCalculationService.calculateUpliftPrevQuoteNegotiatedPrice(mapQuoteData);
        mapQuoteData.put('minimum50Applied', false);
        Boolean remove50DollarValidation = true;
        String compositeKey = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');
        Map<String, Object> segmentIndexMap = new Map<String, Object>();
        for(Map<String, Object> lineRecord : quoteLinedata) {
            Boolean isBundleLine = CoreCPQCalculationService.convertToBoolean(lineRecord, 'SBQQ__Bundle__c');
            if((CoreCPQCalculationService.convertToString(lineRecord, 'SBQQ__ProductCode__c')!=null) && CoreCPQCalculationService.convertToString(lineRecord, 'SBQQ__ProductCode__c').equals('LNSL')){
                remove50DollarValidation = false;
            }
            if(isBundleLine == false){
                system.debug('lineRecord--' + lineRecord);
                lineRecord.put('Extended_Net_Monthly__c', 0);
                CoreCPQCalculationService.fillAndReturnSegmentMap(mapQuoteData, lineRecord, segmentIndexMap);
                CoreCPQCalculationService.calculateSuggestedRetailPriceMonthly(mapQuoteData, lineRecord);
                CoreCPQCalculationService.calculateNegotiatedPriceMonth(mapQuoteData, lineRecord);
                CoreCPQCalculationService.calculateSumOfAdditionalDiscounts(mapQuoteData, lineRecord);
                if(CoreCPQCalculationService.convertToDouble(lineRecord, 'SBQQ__SegmentIndex__c') == 1){
                    CoreCPQCalculationService.calculateTotalListOnQuote(mapQuoteData, lineRecord);
                }
            }
        }
        mapQuoteData.put('Remove_50_Dollar_Validation__c',remove50DollarValidation);
        system.debug('netMonthlyFirstSegment1--' + mapQuoteData.get('netMonthlyFirstSegment'));
        //Created Second Loop as we are filling totalList in calculateTotalListOnQuote
        mapQuoteData.put('negoDiscAmtQuote', 0);
        mapQuoteData.put('netMonthlyFirstSegment', 0);
        mapQuoteData.put('negotiatedDiscAmountSecondSegment', 0);
        
        system.debug('netMonthlyFirstSegment2--' + mapQuoteData.get('netMonthlyFirstSegment'));
        for(Map<String, Object> lineRecord : quoteLinedata){
            Boolean isBundleLine = CoreCPQCalculationService.convertToBoolean(lineRecord, 'SBQQ__Bundle__c');
            if(isBundleLine == false){
                CoreCPQCalculationService.calculateFieldsOnSegmentLines(mapQuoteData, lineRecord,segmentIndexMap);
                if(CoreCPQCalculationService.convertToDouble(lineRecord, 'SBQQ__SegmentIndex__c') == 1 && CoreCPQCalculationService.convertToDecimal(lineRecord, 'SBQQ__NetPrice__c') != 0 
                   && generatedFromQuote != 'AAR' && generatedFromQuote != 'Fixed Term Extension'){
                       CoreCPQCalculationService.calculateDiscountOnFirstSegmentLine(mapQuoteData, lineRecord);
                   }
                CoreCPQCalculationService.calculateSumOfAdditionalDiscounts(mapQuoteData, lineRecord);
            }
        }
        system.debug('netMonthlyFirstSegment3--' + mapQuoteData.get('netMonthlyFirstSegment'));
        calculateNegoPriceOnQuote(mapQuoteData);
        if(compositeKey == 'Small Law' || compositeKey == 'USA-LAW360'){
            calculateMissingPenny(mapQuoteData, quoteLinedata);
            calculateMissingPennyForOutYear(mapQuoteData, quoteLinedata);
        }
    }
    
    /** 
* - This method calculates the Missing Penny for the Out year according to the YoY_Growth__c
**/
    public static void calculateMissingPennyForOutYear(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        Integer termY;
        Decimal firstSegmentListAmount2 = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'First_Segment_List_Amount2__c');
        Decimal firstSegmentFreeProductList = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'FirstSegment_Free_Product_List__c');
        Decimal segmentCount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'SBQQ__SubscriptionTerm__c') / 12;
        segmentCount = segmentCount.round(System.RoundingMode.CEILING);
        Decimal partnerDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'SBQQ__PartnerDiscount__c');
        
        Decimal negotiatedDiscAmount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'negotiatedDiscAmount');
        Decimal yoyGrowth = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'YoY_Growth__c');
        String bridgeProgram = CoreCPQCalculationService.convertToString(mapQuoteData, 'Bridge_Program__c');
        
        system.debug('bridgeProgram--' + bridgeProgram);
        system.debug('subTemr11--' + CoreCPQCalculationService.convertToDouble(mapQuoteData, 'SBQQ__SubscriptionTerm__c'));
        
        if (bridgeProgram != null && bridgeProgram != '--None--') {
            termY = 2;
            segmentCount = segmentCount + 1;
        } else {
            termY = 1;
        }
        Decimal totalDisc = ((firstSegmentListAmount2 - firstSegmentFreeProductList) * partnerDiscount) / 100;
        Decimal np = ((firstSegmentListAmount2 - totalDisc) - firstSegmentFreeProductList);
        np = np.setScale(2,RoundingMode.HALF_UP);
        system.debug('np$$$' + np);
        //Out year Started
        system.debug('segmentCount--' + segmentCount);
        for (Integer i = 1; i <= segmentCount; i++) {
            if (i > termY) {
                Decimal calNp = 0;
                for(Map<String, Object> lineRecord : quoteLinedata){
                    Decimal negoPriceMonth = CoreCPQCalculationService.convertToDecimal(lineRecord, 'negoPriceMonth');
                    Double segmentIndex = CoreCPQCalculationService.convertToDouble(lineRecord, 'SBQQ__SegmentIndex__c');
                    system.debug('segmentIndex$$' + segmentIndex);
                    system.debug('negoPriceMonth$$' + negoPriceMonth);
                    if (segmentIndex == i && negoPriceMonth != 0) {
                        CoreCPQCalculationService.calculateSumOfAdditionalDiscounts(mapQuoteData, lineRecord);
                        Decimal computedVal = negoPriceMonth - negotiatedDiscAmount;
                        Decimal rounded  = computedVal.setScale(2,RoundingMode.HALF_UP);
                        system.debug('computedVal$$' + computedVal);
                        system.debug('rounded$$' + rounded);
                        calnp =  calnp + rounded;
                        system.debug('calnp$$' + calnp);
                    }
                }
                system.debug('calnp$$$' + calnp);
                system.debug('np111' + np);
                system.debug('yoyGrowth11---' + yoyGrowth);
                Decimal divededYearGrowth = yoyGrowth / 100;
                system.debug('divededYearGrowth--' + divededYearGrowth);
                Decimal multipliedNpWithYOY =  divededYearGrowth * np;
                multipliedNpWithYOY = multipliedNpWithYOY.setScale(2,RoundingMode.HALF_UP);
                system.debug('multipliedNpWithYOY--' + multipliedNpWithYOY);
                system.debug('multipliedNpWithYOY++' + multipliedNpWithYOY + np);
                Decimal missingPennyScaledValue = (multipliedNpWithYOY + np).setScale(2,RoundingMode.HALF_UP);
                system.debug('missingPennyScaledValue--' + missingPennyScaledValue);
                Decimal missingPenny = missingPennyScaledValue - calnp;
                missingPenny = missingPenny.setScale(2,RoundingMode.HALF_UP);
                system.debug('missingPenny$$' + missingPenny);
                
                applyExtendedOnQuote(i, mapQuoteData, quoteLinedata, missingPenny);
                system.debug('np333' + np);
                np = (np + (np * (yoyGrowth / 100)));
                system.debug('np222' + np);
                np = np.setScale(2,RoundingMode.HALF_UP);
                system.debug('np444' + np);
            }
        }
    }
    
    
    /** 
* - This method calculates the Missing penny on the Quote line and adjusts into the Extended Net Monthly.
**/
    public static void calculateMissingPenny(Map<String, Object> mapQuoteData,List<Map<String, Object>> quoteLinedata){
        Decimal negotiatedPriceQuote = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'negotiatedPriceQuote');
        system.debug('negotiatedPriceQuote--' + negotiatedPriceQuote);
        Decimal netMonthlyFirstSegment =  CoreCPQCalculationService.convertToDecimal(mapQuoteData,'netMonthlyFirstSegment');
        Decimal missingPenny = 0;
        Decimal roundedNegotaitedPriceFromPreviousQuote  = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'Negotiated_Price_from_Previous_Quote__c');
        Boolean minimum50Applied = CoreCPQCalculationService.convertToBoolean(mapQuoteData,'minimum50Applied');
        system.debug('minimum50Applied--' + minimum50Applied);
        String bridgeProgram = CoreCPQCalculationService.convertToString(mapQuoteData,'Bridge_Program__c');
        Decimal pricePrevQuote90 = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'pricePrevQuote90');
        Decimal programDiscountPercent = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'Program_Discount_percent__c');
        Decimal negoDiscAmtQuote = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'negoDiscAmtQuote');
        Decimal netMonthlySecondSegment = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'negotiatedDiscAmountSecondSegment');
        String generatedFrom = CoreCPQCalculationService.convertToString(mapQuoteData, 'Generated_From__c');
        Decimal upliftPrevQuoteNegotiatedPrice = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'upliftPrevQuoteNegotiatedPrice');
        system.debug('roundedNegotiatedDiscAmountFirstSegment-' + netMonthlyFirstSegment);
        system.debug('negotiatedPriceQuote## ' + negotiatedPriceQuote);
        if(minimum50Applied && netMonthlyFirstSegment != 50){
            missingPenny = 50 - netMonthlyFirstSegment;   
        }
        else if (bridgeProgram == 'RACE' || bridgeProgram == 'RACE Enhanced') {
            missingPenny = roundedNegotaitedPriceFromPreviousQuote - netMonthlyFirstSegment;
        }
        else if(bridgeProgram == 'Customer Appreciation') {
            missingPenny = pricePrevQuote90 - netMonthlyFirstSegment;
        }   
        else if (generatedFrom == 'AAR') {
            missingPenny = upliftPrevQuoteNegotiatedPrice - netMonthlyFirstSegment;
        }
        else if (generatedFrom  == 'Fixed Term Extension') {
            missingPenny = roundedNegotaitedPriceFromPreviousQuote - netMonthlyFirstSegment;
        }
        else if(!minimum50Applied && programDiscountPercent > 0){
            system.debug('negotiatedPriceQuote before program discount - '+negotiatedPriceQuote);
            system.debug('netMonthlyFirstSegment before program discount - '+netMonthlyFirstSegment);
            Decimal quoteNegoSubscriptionPrice = (negotiatedPriceQuote - (negotiatedPriceQuote * (programDiscountPercent / 100))).setScale(2,RoundingMode.HALF_UP);
            system.debug('negotiatedPriceQuote before program discount - '+quoteNegoSubscriptionPrice);
            missingPenny = quoteNegoSubscriptionPrice - netMonthlyFirstSegment;
            system.debug('missingPenny362 - '+missingPenny); 
        }
        else if(!minimum50Applied){
            system.debug('negotiatedPriceQuote# ' + negotiatedPriceQuote);
            system.debug('negoDiscAmtQuote# ' + negoDiscAmtQuote);
            system.debug('netMonthlyFirstSegment# ' + netMonthlyFirstSegment);
            missingPenny = (negotiatedPriceQuote - negoDiscAmtQuote);
            missingPenny = missingPenny - netMonthlyFirstSegment;
        }
        system.debug('missingPenny- ' + missingPenny);
        mapQuoteData.put('missingPenny', missingPenny);
        applyExtendedOnQuote(1, mapQuoteData, quoteLinedata, missingPenny);
        if (bridgeProgram != null && bridgeProgram != '--None--' && netMonthlySecondSegment != negotiatedPriceQuote) {
            System.debug('negotiatedPriceQuote---'+negotiatedPriceQuote);
            System.debug('netMonthlySecondSegment'+netMonthlySecondSegment);
            missingPenny = (negotiatedPriceQuote - netMonthlySecondSegment);
            missingPenny = missingPenny.setScale(2,RoundingMode.HALF_UP);
            applyExtendedOnQuote(2, mapQuoteData, quoteLinedata, missingPenny);
        }
    }
    
    /** 
* - This method calculates the Missing penny on the Quote 
* - This method is being called from calculateMissingPenny method
* - applyExtendedOnQuote method is being called to adjust the penny in highest amount and settling the missing Penny Amount in Extended Net Monthly.
**/
    public static void applyExtendedOnQuote(Integer segment, Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata , Decimal missingPenny){
        System.debug('missingP in ApplyExtended'+missingPenny);
        System.debug('segment In'+ segment);
        if (missingPenny != null) {
            Boolean added = false;
            Decimal highestAmount = 0;   
            Decimal regularAmount = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'SBQQ__RegularAmount__c');
            Decimal partnerDisc = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'SBQQ__PartnerDiscount__c');
            String generatedFrom = CoreCPQCalculationService.convertToString(mapQuoteData ,'Generated_From__c');
            for (Map<String, Object> lineRec : quoteLinedata) {
                Decimal suggestedPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRec ,'Suggested_Retail_Price_Monthly__c');
                Decimal negotiatedPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRec ,'negoPriceMonth');
                Double segmentIndex = CoreCPQCalculationService.convertToInteger(lineRec, 'SBQQ__SegmentIndex__c');
                if(segmentIndex == segment){
                    system.debug('segmentIndex--' + segmentIndex);
                    Decimal negoPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRec, 'negoPriceMonth');
                    lineRec.put('negoPriceMonth', negoPriceMonthly);
                    system.debug('negoPriceMoth421 -- ' + negoPriceMonthly);
                    if(highestAmount < negoPriceMonthly){
                        highestAmount = negoPriceMonthly;
                        System.debug('highestAmount----'+ highestAmount);
                    }
                }
            }
            for (Map<String, Object> lineRec : quoteLinedata) {
                Decimal negotiatedDiscAmount;
                Decimal negotiatedDiscAmtQLs;
                Decimal negoPriceMonth = CoreCPQCalculationService.convertToDecimal(lineRec, 'negoPriceMonth');
                Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRec ,'SBQQ__NonDiscountable__c');
                Double  segmentIndex = CoreCPQCalculationService.convertToDouble(lineRec, 'SBQQ__SegmentIndex__c');
                Decimal additionalDiscAmount = CoreCPQCalculationService.convertToDecimal(lineRec ,'SBQQ__AdditionalDiscountAmount__c');
                Double effectiveQuantity = CoreCPQCalculationService.convertToDouble(lineRec ,'SBQQ__EffectiveQuantity__c');
                Double prorateMultiplier = CoreCPQCalculationService.convertToDouble(lineRec ,'SBQQ__ProrateMultiplier__c');
                Decimal negoPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRec ,'negoPriceMonth');
                Decimal discount = CoreCPQCalculationService.convertToDecimal(lineRec ,'SBQQ__Discount__c');
                Decimal netMonthly = CoreCPQCalculationService.convertToDecimal(lineRec ,'Net_Monthly__c');
                system.debug('discount--' + discount);
                if(segmentIndex == segment && negoPriceMonth != 0 && negoPriceMonth > 0 && missingPenny != 0){
                    if (!nonDiscountable && (generatedFrom == 'AAR' || generatedFrom == 'Fixed Term Extension') && prorateMultiplier > 0){
                        negotiatedDiscAmount = (additionalDiscAmount * effectiveQuantity) / prorateMultiplier;
                        negotiatedDiscAmount = negotiatedDiscAmount.setScale(2,RoundingMode.HALF_UP);
                    }else if(!nonDiscountable){
                        negotiatedDiscAmount = (negoPriceMonthly * discount) / 100;
                        negotiatedDiscAmount = negotiatedDiscAmount.setScale(2,RoundingMode.HALF_UP);
                    }else{
                        negotiatedDiscAmount = 0; 
                    }
                    system.debug('negotiatedDiscAmount--' + negotiatedDiscAmount);
                    Decimal computedVal = negoPriceMonth - negotiatedDiscAmount;
                    Decimal rounded  = computedVal.setScale(2,RoundingMode.HALF_UP);
                    system.debug('Testrounded123-- ' + rounded);
                    system.debug('highestAmount$$' + highestAmount);
                    
                    if(netMonthly != 0 && !added && highestAmount == negoPriceMonth){
                        lineRec.put('Extended_Net_Monthly__c', rounded + missingPenny);
                        system.debug('Extended Net Monthly 704 --- '+rounded + missingPenny);
                        added = true;
                    }else if(netMonthly != 0){
                        lineRec.put('Extended_Net_Monthly__c' , rounded);
                    }else{
                        lineRec.put('Extended_Net_Monthly__c', 0);
                    }
                }
                else if(segmentIndex == segment &&  missingPenny == 0){
                    lineRec.put('Extended_Net_Monthly__c', 0);
                }
            }
        }
    } 
    
    /** 
* - This method calculates the NegotiatedPrice On Quote  used in calculateAdditionalDiscountsAndMissingPenny
* - It is calculating the negotiated price based on the first segment list amount, free product list, and partner discount.
**/
    public static void calculateNegoPriceOnQuote(Map<String, Object> mapQuoteData){
        Decimal firstSegmentListAmount = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'First_Segment_List_Amount2__c');
        Decimal firstSegmentFreeProductList = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'FirstSegment_Free_Product_List__c');
        Decimal partnerDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'SBQQ__PartnerDiscount__c'); 
        system.debug('firstSegmentListAmount one--' + firstSegmentFreeProductList + ' partnerDiscount-- '+partnerDiscount+' firstSegmentListAmount--'+firstSegmentListAmount);
        Decimal negotiatedPriceQuote = (firstSegmentListAmount - ((firstSegmentListAmount - firstSegmentFreeProductList) * partnerDiscount / 100) - firstSegmentFreeProductList);
        System.debug('negotiatedPriceQuote Before Rounding '+negotiatedPriceQuote);
        Decimal roundedNegopriceQuote = negotiatedPriceQuote.setScale(2,RoundingMode.HALF_UP);
        System.debug('roundedNegopriceQuote'+roundedNegopriceQuote);
        mapQuoteData.put('negotiatedPriceQuote', roundedNegopriceQuote);
    }
    
    /*
* - Method to calculate the WestBridge End Date based on the start date and months to add, Called from calculateWestBridgeEndDateOnQuote Method
*/
    public static Date calculateWestBridgeEndDate(Date startDate,Integer monthsToAdd,Integer YearToAdd){
        Integer year = startDate.year();
        Integer month = startDate.month();
        Integer day = startDate.day();
        
        Integer adjustedMonth =  Math.mod((month + monthsToAdd-1),12)+1;
        Integer additionalYears = Integer.valueOf(math.Floor((month + monthsToAdd-1) / 12)+YearToAdd);
        
        // Calculate target year
        Integer targetYear = year + additionalYears;
        Integer lastDayOfMonth = 0;
        
        lastDayOfMonth =  CoreCPQCalculationService.getDaysInMonth(year, adjustedMonth);
        
        if(day > lastDayOfMonth){
            adjustedMonth+=1;
        }
        return Date.newInstance(targetYear, adjustedMonth, day-1);
    }
    
    
    private static Date calculateEndDateBasedOnStartDate(Date startDate) {
        return calculateEndDateBasedOnStartDate(startDate, 6);
    }  
    
    public static Date calculateEndDateBasedOnStartDate(Date startDate, Integer monthsToAdd) {
        Date myDate = Date.valueOf(startDate);  
        Integer year = myDate.year();
        Integer month = myDate.month() + monthsToAdd - 1;
        
        // Handle month overflow
        year += Integer.valueOf(math.Floor(month / 12));
        month = math.mod(month, 12) + 1;
        
        // Handle leap year for February
        Integer day = myDate.day();
        if (month == 2 && day == 29 && !Date.isLeapYear(year)) {
            day = 28;
        } else {
            day = Math.min(day, getDaysInMonth(year, month));
        }
        
        return date.newinstance(year, month, day);
    }
    
    private static Date getAfterDate(Date calculatedEndDate , Date endDateFromPreviousContract){
        if(calculatedEndDate > endDateFromPreviousContract){
            return endDateFromPreviousContract;
        }else{
            return calculatedEndDate;
        }
    }
    
    private static Integer getDaysInMonth(Integer year, Integer month) {
        switch on month {
            When 4  , 6 , 9 , 11 {
                return 30;
            }
            When 2  {
                return Date.isLeapYear(year) ? 29 : 28;
            }
            When else {
                return 31;
            }
        }
    }
    
    
    
    
}