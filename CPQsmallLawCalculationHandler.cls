public class CPQSmallLawCalculationHandler implements ICustomScript{

    public static void callCalculations(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        
        //Populates Product Related Fields on the Quote line
        CoreCPQCalculationHelper.assignProductDetailsToQuoteLines(mapQuoteData, quoteLineData); 
        
         
        //Populate the Custom List__c on the Quote line
        CoreCPQCalculationHelper.calculateCustomListPrice(quoteLineData); 
        
        
        //Summary Variables Price Rules
        CPQSmallLawCalculationHelper.calculateRollupFieldsOnQuote(mapQuoteData, quoteLineData);
        
        //Update Start Date For Non - Segment Products on Quote Line From Quote
        CoreCPQCalculationHelper.setStartDateForRenewalNonSegmentedLines(mapQuoteData, quoteLineData);
        
        //Calculates West Bridge End date on the Quote
        CPQSmallLawCalculationHelper.calculateWestBridgeEndDateOnQuote(mapQuoteData, quoteLineData);
        
        //Calculates First Segment End date on the Quote
        CPQSmallLawCalculationHelper.calculateFirstSegmentTermEndDateOnQuote(mapQuoteData);
        
        //Calculates End Date on the Quote
        CPQSmallLawCalculationHelper.calculateEndDateOnQuote(mapQuoteData);
        
        //Calculates Bridge Period of Months on the Quote
        CPQSmallLawCalculationHelper.calculateBridgePeriodOfMonthsOnQuote(mapQuoteData);
        
        //Calculates Subscription Term on the Quote
        CPQSmallLawCalculationHelper.calculateSubscriptionTerm(mapQuoteData);
        
        //Calculates Term Of Year on the Quote
        CPQSmallLawCalculationHelper.calculateTermOfYear(mapQuoteData);
        
        //Calculates Of Attorneys on the Quote
        CPQSmallLawCalculationHelper.calculateOfAttorneysOnQuote(mapQuoteData);
        
        //Calculates Quantity on the Quote line
        CPQSmallLawCalculationHelper.calculateQuantityOnQuoteline(mapQuoteData, quoteLineData);
        
        //Calculates the Program Discount on the Quote  
        CPQSmallLawCalculationHelper.applyProgramDiscountsBasedonProgramSelected(mapQuoteData);
        
        //Calculates the Program Discount on the Quote
        CPQSmallLawCalculationHelper.calulcateDiscountFromProgramDiscountOnQuoteline(mapQuoteData, quoteLineData);
        
        //Calculates Product Mix Discount on the Quote
        //CPQSmallLawCalculationHelper.calculateProductMixDiscountOnQuote(mapQuoteData, quoteLineData);
        
        
        //Calculates multi Year Term Discount on the Quote
        CPQBISCalculationHelper.multiYearTermDiscount(mapQuoteData);
        
        //Calculates Depth Discount on the Quote
        CPQSmallLawCalculationHelper.calculateDepthDiscountOnQuote(mapQuoteData, quoteLineData);
        
        //Calculates Discretionary Discount on the Quote
        CPQSmallLawCalculationHelper.calculateDiscretionaryDiscountOnQuote(mapQuoteData);
        
        //Calculates Partner Discount on the Quote
        CPQSmallLawCalculationHelper.calculatePartnerDiscountOnQuote(mapQuoteData);
        
        //Calculates Additional Discount And Missing Penny on the Quote
        CPQSmallLawCalculationHelper.calculateAdditionalDiscountsAndMissingPenny(mapQuoteData, quoteLineData);
        
        //Calculates Uplift on the Quote line
        CoreCPQCalculationHelper.applyYOYGrowth(mapQuoteData, quoteLineData);
        
        //Calculates Minimum Years of Eligibility on the Quote
        CPQSmallLawCalculationHelper.minOfYearsEligibility(mapQuoteData, quoteLineData);
        
        //Conversion of Lookup Queries Price Rules
        CoreCPQCalculationHelper.assignPricingAnalystAndConsultant(mapQuoteData);
        CPQSmallLawCalculationHelper.checkProgramAndPromoCompatibility(mapQuoteData);
        CPQSmallLawCalculationHelper.populateGenericProductPriceOnQLs(mapQuoteData, quoteLineData);
        
        CPQSmallLawCalculationHelper.calculateNegotiatedPriceEligibilityOnQuote(mapQuoteData);
        CoreCPQCalculationHelper.updateQLIFieldsFromPriceBookEntry(mapQuoteData, quoteLineData);
        
        
        //Update Status on the Quote
        CoreCPQCalculationHelper.updateQuoteStatusForRetentionQuotes(mapQuoteData, quoteLineData);
    }
}