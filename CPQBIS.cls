/*******************************************************************************************
* @Name         CPQBISCalculationHelper 
* @Author       Naval Sharma
* @Description  This is Helper class used for Calculation of gNS Quotes.
********************************************************************************************/
public class CPQBISCalculationHelper {
    
    /**
* Retrieves subscription records for a given contract and maps them by ProductId-ContractId.
* This method is used to avoid querying the SBQQ__Subscription__c object multiple times 
**/
    public static Map<String, Object> getSubscriptionMapByProductId(Map<String, Object> mapQuoteData,List<Map<String, Object>> quoteLineData,List<Contract> contractRecord) {
        String contractId = CoreCPQCalculationService.convertToString(mapQuoteData, 'Contract__c');
        Map<String, SBQQ__Subscription__c> allSegmentsMap = new Map<String, SBQQ__Subscription__c>();
        Map<String, SBQQ__Subscription__c> lastSegmentMap = new Map<String, SBQQ__Subscription__c>();
        List<Contract> contractRecords = new List<Contract>();
        if (String.isNotBlank(contractId)) {
            contractRecords = [ SELECT StartDate,EndDate,First_Segment_End_Date__c,First_Segment_Start_Date__c,Second_Segment_Start_Date__c,Second_Segment_End_Date__c,Third_Segment_Start_Date__c,Third_Segment_End_Date__c
                               ,Fourth_Segment_Start_Date__c,Fourth_Segment_End_Date__c,Fifth_Segment_Start_Date__c,Fifth_Segment_End_Date__c,Sixth_Segment_Start_Date__c,Sixth_Segment_End_Date__c FROM Contract WHERE Id = :contractId LIMIT 1];
            contractRecord.addAll(contractRecords);   
        }
        if (String.isNotBlank(contractId)) {
            List<SBQQ__Subscription__c> subList = [
                SELECT Id, SBQQ__Contract__r.Primary_Jurisdiction2__c, SBQQ__RenewalPrice__c, SBQQ__SpecialPrice__c,
                SBQQ__Product__c, SBQQ__ProductName__c, Product_Id__c, SBQQ__EndDate__c,SBQQ__Product__r.ProductCode,
                Asset_Installed_Date__c, Extended_Net_Price__c, Net_Unit_Price__c, SBQQ__SegmentIndex__c,SBQQ__Quantity__c,
                SBQQ__SegmentQuantity__c, SBQQ__OriginalQuoteLine__r.SBQQ__Quantity__c,SBQQ__StartDate__c,
                SBQQ__OriginalQuoteLine__r.SBQQ__EffectiveQuantity__c, CPQ_Composite__c
                FROM SBQQ__Subscription__c
                WHERE SBQQ__Contract__c = :contractId
                ORDER BY SBQQ__SegmentIndex__c ASC
            ];
            
            for (SBQQ__Subscription__c sub : subList) {
                String key = sub.Product_Id__c + '-' + sub.SBQQ__Contract__c;
                // Composite key with SegmentIndex for all segments map to differentiate multiple segments
                allSegmentsMap.put(key + '-' + sub.SBQQ__SegmentIndex__c, sub);
                
                // Keep only the last segment per product key based on highest SegmentIndex
                if (!lastSegmentMap.containsKey(key) || sub.SBQQ__SegmentIndex__c > lastSegmentMap.get(key).SBQQ__SegmentIndex__c) {
                    lastSegmentMap.put(key, sub);
                }
            }
        }
        
        Map<String, Object> result = new Map<String, Object>();
        result.put('allSegments', allSegmentsMap);
        result.put('lastSegments', lastSegmentMap);
        
        return result;
    }
  

    
    /**
* Compares the Suggested Retail price (SRP) with the uplifted renewal price,
* and sets the lower of the two as the current pricing.
* calcualte Additional discount 
*/
    public static void calculateRTKPricinglogic(Map < String, Object > mapQuoteData, List < Map < String, Object >> quoteLinedata) {
        
        Map < String, Decimal > segmentKeyToRTKDiscount = new Map < String, Decimal > ();
        String generatedFrom = CoreCPQCalculationService.convertToString(mapQuoteData, 'Generated_From__c');
        Decimal Negotiated_Price_Target = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Negotiated_Price_Target__c');
        Decimal Discretionary_Discount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Discretionary_Discount__c');
        Decimal RenewalrtkUplift = CoreCPQCalculationService.convertToDouble(mapQuoteData, 'RTK_Uplift__c');
        Decimal RenewalUplift = CoreCPQCalculationService.convertToDouble(mapQuoteData, 'SBQQ__RenewalUpliftRate__c');
        String compositeKey = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');
        
        if (RenewalrtkUplift == null || RenewalrtkUplift == 0) {
            RenewalrtkUplift = RenewalUplift;
            mapQuoteData.put('RTK_Uplift__c', RenewalUplift);
        }
        
        // Only run RTK price adjustments for BIS/RTIS Renewal quotes. 
        Boolean doRtk = ((compositeKey == 'BIS' || compositeKey == 'RTIS' || compositeKey == 'Corp Legal') && generatedFrom == 'Renewal');
        if (!doRtk) {
            return;
        }
        
        for (Map < String, Object > lineRec: quoteLinedata) {
            Decimal rtkAdditionalDiscAmount = CoreCPQCalculationService.convertToDecimal(lineRec, 'RTK_Additional_Discount_Amt__c');
            Decimal AdditionalDiscAmount = CoreCPQCalculationService.convertToDecimal(lineRec, 'SBQQ__AdditionalDiscountAmount__c');
            Double effectiveQuantity = CoreCPQCalculationService.convertToDouble(lineRec, 'SBQQ__EffectiveQuantity__c');
            Double quantity = CoreCPQCalculationService.convertToDouble(lineRec, 'SBQQ__Quantity__c');
            Decimal segmentIndex = CoreCPQCalculationService.convertToDouble(lineRec, 'SBQQ__SegmentIndex__c');
            String segmentKey = CoreCPQCalculationService.convertToString(lineRec, 'SBQQ__SegmentKey__c');
            Decimal regularPrice = CoreCPQCalculationService.convertToDouble(lineRec, 'SBQQ__RegularPrice__c');
            Decimal PartnerDiscount = CoreCPQCalculationService.convertToDouble(lineRec, 'SBQQ__PartnerDiscount__c');
            Decimal upliftedRenewalPrice = CoreCPQCalculationService.convertToDouble(lineRec, 'RTK_Uplifted_Renewal_Price__c');
            Decimal upliftPercent = CoreCPQCalculationService.convertToDouble(lineRec, 'SBQQ__Uplift__c');
            Decimal Target_Price_Override = CoreCPQCalculationService.convertToDecimal(lineRec, 'Target_Price_Override__c');
            Decimal prorateMultiplier = CoreCPQCalculationService.convertToDecimal(lineRec, 'SBQQ__ProrateMultiplier__c');
            Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRec, 'SBQQ__NonDiscountable__c');
            
           
            Decimal adjRegularPrice = 0;
            rtkAdditionalDiscAmount = 0;
            
            if (RenewalrtkUplift > 0 && segmentIndex != null && segmentIndex == 1) {
                System.debug('Énter into the block');
                lineRec.put('SBQQ__Uplift__c', RenewalrtkUplift);
            }
            if (segmentIndex == null || quantity == null || effectiveQuantity == null || effectiveQuantity == 0) {
                continue;
            }
            
            Decimal quantityRatio = (quantity / effectiveQuantity);
            
            if (upliftedRenewalPrice != null && upliftedRenewalPrice > 0) {
                if (prorateMultiplier != 0 && quantityRatio != 0) {
                    adjRegularPrice = (regularPrice / prorateMultiplier) / quantityRatio;
                }
                  System.debug('adjRegularPrice1:::' + adjRegularPrice);
                
                if (adjRegularPrice > upliftedRenewalPrice || compositeKey == 'RTIS' || compositeKey == 'Corp Legal') {
                    String currentKey = segmentKey + '-' + segmentIndex.intValue();
                    
                    if (segmentIndex == 1) {
                        adjRegularPrice = regularPrice -(regularPrice* (PartnerDiscount/100));
                        if(quantityRatio ==1){
                           adjRegularPrice = adjRegularPrice*quantity; 
                        }
                        System.debug('adjRegularPrice2:::' + adjRegularPrice);
                        rtkAdditionalDiscAmount = ((adjRegularPrice - (upliftedRenewalPrice * quantity * prorateMultiplier))/effectiveQuantity).setScale(2, RoundingMode.HALF_UP);
                        upliftedRenewalPrice = (upliftedRenewalPrice * quantity).setScale(2, RoundingMode.HALF_UP);
                        
                        
                        lineRec.put('RTK_Additional_Discount_Amt__c', rtkAdditionalDiscAmount);
                        lineRec.put('RTK_Uplifted_Renewal_Price__c', upliftedRenewalPrice);

                       System.debug('rtkAdditionalDiscAmount:::' + rtkAdditionalDiscAmount);
                       System.debug('upliftedRenewalPrice:::' + upliftedRenewalPrice);
                        
                        segmentKeyToRTKDiscount.put(currentKey, rtkAdditionalDiscAmount);
                    } else if (segmentIndex > 1) {
                        
                        adjRegularPrice = regularPrice -(regularPrice* (PartnerDiscount/100));
                        if(quantityRatio ==1){
                           adjRegularPrice = adjRegularPrice*quantity; 
                        }
                        String prevKey = segmentKey + '-' + (segmentIndex.intValue() - 1);
                        Decimal prevRTK = segmentKeyToRTKDiscount.get(prevKey);
                        
                        if (prevRTK != null && upliftPercent != null) {
                            Decimal upliftFactor = 1 + (upliftPercent / 100);
                            Decimal newRTK = prevRTK * upliftFactor;
                            
                          
                            upliftedRenewalPrice = (upliftedRenewalPrice * quantity).setScale(2, RoundingMode.HALF_UP);
                        rtkAdditionalDiscAmount = ((adjRegularPrice - (upliftedRenewalPrice  * prorateMultiplier))/effectiveQuantity).setScale(2, RoundingMode.HALF_UP);

                            lineRec.put('RTK_Additional_Discount_Amt__c', newRTK);
                            lineRec.put('RTK_Uplifted_Renewal_Price__c', upliftedRenewalPrice);
                            segmentKeyToRTKDiscount.put(currentKey, newRTK);
                        }
                    }
                    
                    lineRec.put('SBQQ__AdditionalDiscountAmount__c', rtkAdditionalDiscAmount);
                    
                    if ((compositeKey == 'BIS' || compositeKey == 'RTIS' || compositeKey == 'Corp Legal') &&
                        Target_Price_Override == 0 &&
                        (Discretionary_Discount == null || Discretionary_Discount == 0.0) &&
                        (Negotiated_Price_Target == null || Negotiated_Price_Target == 0)) {
                            lineRec.put('Extended_Net_Monthly__c', 0);
                        }
                } else {
                    upliftedRenewalPrice = (upliftedRenewalPrice * quantityRatio).setScale(2, RoundingMode.HALF_UP);
                    lineRec.put('SBQQ__AdditionalDiscountAmount__c', 0);
                    lineRec.put('RTK_Additional_Discount_Amt__c', 0);
                    lineRec.put('RTK_Uplifted_Renewal_Price__c', upliftedRenewalPrice);
                }
            } else {
                upliftedRenewalPrice = (upliftedRenewalPrice * quantityRatio).setScale(2, RoundingMode.HALF_UP);
                lineRec.put('SBQQ__AdditionalDiscountAmount__c', 0);
                lineRec.put('RTK_Additional_Discount_Amt__c', 0);
                lineRec.put('RTK_Uplifted_Renewal_Price__c', upliftedRenewalPrice);
            }
            
            if (segmentIndex >= 1 && !nonDiscountable && (compositeKey == 'BIS' || compositeKey == 'RTIS' || compositeKey == 'Corp Legal') && rtkAdditionalDiscAmount > 0 && AdditionalDiscAmount > 0) {
                lineRec.put('SBQQ__DistributorDiscount__c', 0);
                lineRec.put('Extended_Net_Monthly__c', 0);
            }
            if ((compositeKey == 'RTIS' || compositeKey == 'Corp Legal') && upliftedRenewalPrice > 0) {
                
                lineRec.put('Extended_Net_Monthly__c', upliftedRenewalPrice);
            }
        }
        calculateIsTargetPriceOverridden(mapQuoteData, quoteLineData);
        clearAdditionalDiscountAmount(mapQuoteData, quoteLineData);
        calculateFirstSegmentNetPrice(mapQuoteData, quoteLinedata);
        calculateBundleAmount(mapQuoteData, quoteLineData);
        
    }
    
    /**
* Calculates the RTK percentage change for RTK Manual Renewals.
*  Retrieves subscription details from the associated contract.
*  Ensures the current monthly price is not lower than the contracted price.
**/
    public static void calculateRtkPercentageChange(Map < String, Object > mapQuoteData,List < Map < String, Object >> quoteLineData,Map < String, SBQQ__Subscription__c > productBySubMap){
        String generatedFrom = CoreCPQCalculationService.convertToString(mapQuoteData, 'Generated_From__c');
        String contractId = CoreCPQCalculationService.convertToString(mapQuoteData, 'Contract__c');
        Decimal RenewalUplift = CoreCPQCalculationService.convertToDouble(mapQuoteData, 'SBQQ__RenewalUpliftRate__c');
        Decimal RenewalrtkUplift = CoreCPQCalculationService.convertToDouble(mapQuoteData, 'RTK_Uplift__c');
        Decimal Negotiated_Price_Target = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Negotiated_Price_Target__c');
        Decimal Discretionary_Discount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Discretionary_Discount__c');
        String compositeKey = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');
        
        Decimal lastSegmentCommitment = 0;
        Map < String, Decimal > segmentToExtendedNetMap = new Map < String, Decimal > ();
        
        if ((compositeKey == 'BIS') && generatedFrom == 'Renewal') {
            for (Map < String, Object > lineRec: quoteLineData) {
                String productId = CoreCPQCalculationService.convertToString(lineRec, 'Product_Id__c');
                Boolean isBundle = CoreCPQCalculationService.convertToBoolean(lineRec, 'SBQQ__Bundle__c');
                Decimal listPrice = CoreCPQCalculationService.convertToDecimal(lineRec, 'SBQQ__ListPrice__c');
                Decimal bundleAmount = CoreCPQCalculationService.convertToDecimal(lineRec, 'Bundle_Amount__c');
                Double quantity = CoreCPQCalculationService.convertToDouble(lineRec, 'SBQQ__Quantity__c');
                Boolean excluded = CoreCPQCalculationService.convertToBoolean(lineRec, 'Excluded__c');
                Boolean isFree = CoreCPQCalculationService.convertToBoolean(lineRec, 'Free_Product__c');
                Decimal extendedNetMonthly = CoreCPQCalculationService.convertToDecimal(lineRec, 'Extended_Net_Monthly__c');
                Decimal targetPriceOverride = CoreCPQCalculationService.convertToDecimal(lineRec, 'Target_Price_Override__c');
                Decimal targetPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRec, 'Target_Price_Monthly__c');
                Decimal negotiatedDiscAmt = CoreCPQCalculationService.convertToDecimal(lineRec, 'Negotiated_Disc_Amt__c');
                
                Decimal upliftedRenewalPrice = CoreCPQCalculationService.convertToDouble(lineRec, 'RTK_Uplifted_Renewal_Price__c');
                Decimal segmentIndex = CoreCPQCalculationService.convertToDouble(lineRec, 'SBQQ__SegmentIndex__c');
                Decimal uplift = CoreCPQCalculationService.convertToDouble(lineRec, 'SBQQ__Uplift__c');
                Decimal rtkAdditionalDiscAmount = CoreCPQCalculationService.convertToDecimal(lineRec, 'RTK_Additional_Discount_Amt__c');
                Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRec, 'SBQQ__NonDiscountable__c');
                String segmentKey = CoreCPQCalculationService.convertToString(lineRec, 'SBQQ__SegmentKey__c');
                
                String key = productId + '-' + contractId;
                
                // Calculate netMonthly using provided logic
                Decimal netMonthly = 0;
                if (isBundle && listPrice != 0) {
                    netMonthly = bundleAmount;
                } else {
                    if (excluded || isFree) {
                        netMonthly = 0;
                    } else if (extendedNetMonthly != null && extendedNetMonthly != 0) {
                        netMonthly = extendedNetMonthly;
                    } else if (targetPriceOverride != null && targetPriceOverride != 0) {
                        netMonthly = targetPriceOverride;
                    } else {
                        netMonthly = (targetPriceMonthly - negotiatedDiscAmt).setScale(2);
                    }
                }
                
                if (segmentIndex >= 1 && !nonDiscountable && generatedFrom == 'RTK' && rtkAdditionalDiscAmount > 0) {
                    lineRec.put('SBQQ__DistributorDiscount__c', 0);
                }
                
                if (generatedFrom == CPQConstants.QUOTE_TYPE_RENEWAL &&
                    segmentIndex != null &&
                    productBySubMap.containsKey(key)) {
                        
                        SBQQ__Subscription__c sub = productBySubMap.get(key);
                        Decimal renewalPrice = sub.Extended_Net_Price__c;
                        Decimal SegmentQuantity = sub.SBQQ__SegmentQuantity__c;
                        
                        if (segmentIndex == 1) {
                            lastSegmentCommitment += renewalPrice;
                            
                            if (rtkAdditionalDiscAmount > 0 && RenewalrtkUplift > 0) {
                                Decimal rtkChange = RenewalrtkUplift - RenewalUplift;
                                lineRec.put('RTK_Change__c', rtkChange);
                            } else if (rtkAdditionalDiscAmount == null || rtkAdditionalDiscAmount == 0) {
                                lineRec.put('RTK_Change__c', 0);
                            }
                            if (compositeKey == 'BIS' && rtkAdditionalDiscAmount > 0 &&
                                targetPriceOverride == 0 &&
                                (Discretionary_Discount == null || Discretionary_Discount == 0.0) &&
                                (Negotiated_Price_Target == null || Negotiated_Price_Target == 0)) {
                                    lineRec.put('Extended_Net_Monthly__c', 0);
                                }
                            
                            if (compositeKey == 'BIS' && rtkAdditionalDiscAmount == 0 &&
                                (targetPriceOverride == 0 && Discretionary_Discount == 0.0 && Negotiated_Price_Target == 0)) {
                                    
                                    if (netMonthly != null && renewalPrice != null && netMonthly <= renewalPrice && SegmentQuantity == quantity) {
                                        lineRec.put('Extended_Net_Monthly__c', renewalPrice);
                                        String segKey = segmentKey + '-1';
                                        segmentToExtendedNetMap.put(segKey, renewalPrice);
                                    }
                                } else if (compositeKey == 'BIS' && rtkAdditionalDiscAmount >= 0 &&
                                           (targetPriceOverride == 0 && Discretionary_Discount == 0.0 && Negotiated_Price_Target == 0 && SegmentQuantity == quantity)) {
                                               lineRec.put('Extended_Net_Monthly__c', upliftedRenewalPrice);
                                               String segKey = segmentKey + '-1';
                                               segmentToExtendedNetMap.put(segKey, upliftedRenewalPrice);
                                           }
                            
                        } else if (segmentIndex > 1) {
                            String prevKey = segmentKey + '-' + (segmentIndex.intValue() - 1);
                            if (segmentToExtendedNetMap.containsKey(prevKey) && uplift != null) {
                                Decimal prevVal = segmentToExtendedNetMap.get(prevKey);
                                Decimal upliftFactor = 1 + (uplift / 100);
                                Decimal newVal = (prevVal * upliftFactor).setScale(2, RoundingMode.HALF_UP);
                                lineRec.put('Extended_Net_Monthly__c', newVal);
                                
                                segmentToExtendedNetMap.put(segmentKey + '-' + segmentIndex.intValue(), newVal);
                            }
                        }
                    }
            }
            calculateFirstSegmentNetPrice(mapQuoteData, quoteLinedata);
            Decimal firstSegmentNetPrice = CoreCPQCalculationService.convertToDouble(mapQuoteData, 'FirstSegment_Net_Price__c');
            // Final RTK uplift % change
            Decimal rtkUpliftChange = 0;
            if (lastSegmentCommitment != 0) {
                rtkUpliftChange = (((firstSegmentNetPrice - lastSegmentCommitment) / lastSegmentCommitment) * 100).setScale(2, RoundingMode.HALF_UP);
                mapQuoteData.put('RTK_Uplift_Change__c', rtkUpliftChange);
            }
            calculateIsTargetPriceOverridden(mapQuoteData, quoteLineData);
            clearAdditionalDiscountAmount(mapQuoteData, quoteLineData);
            calculateFirstSegmentNetPrice(mapQuoteData, quoteLinedata);
            calculateBundleAmount(mapQuoteData, quoteLineData);
            
        }
    }
    
    /*
*  Extended price subscription is fetched from the subscription object.
*  Calculate Intial RTK Uplift Prices
*/
    
    public static void calculateInitialRTKRenewalUpliftPrices(Map < String, Object > mapQuoteData,List < Map < String, Object >> quoteLinedata,Map < String, SBQQ__Subscription__c > productBySubMap){
        String contractId = CoreCPQCalculationService.convertToString(mapQuoteData, 'Contract__c');
        String generatedFrom = CoreCPQCalculationService.convertToString(mapQuoteData, 'Generated_From__c');
        String compositeKey = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');
        calculateIsTargetPriceOverridden(mapQuoteData, quoteLineData);
        clearAdditionalDiscountAmount(mapQuoteData, quoteLineData);
      

        if ((compositeKey == 'BIS' || compositeKey == 'RTIS' || compositeKey == 'Corp Legal') && generatedFrom == 'Renewal') {
            
            Map < String, Decimal > segmentKeyToRenewalPrice = new Map < String, Decimal > ();
            
            for (Map < String, Object > lineRec: quoteLinedata) {
                String productId = CoreCPQCalculationService.convertToString(lineRec, 'Product_Id__c');
                Decimal uplift = CoreCPQCalculationService.convertToDouble(lineRec, 'SBQQ__Uplift__c');
                Decimal segmentIndex = CoreCPQCalculationService.convertToDouble(lineRec, 'SBQQ__SegmentIndex__c');
                String segmentKey = CoreCPQCalculationService.convertToString(lineRec, 'SBQQ__SegmentKey__c');
                String DiscountScheduleType = CoreCPQCalculationService.convertToString(lineRec, 'SBQQ__DiscountScheduleType__c');
                
                Decimal listPrice = CoreCPQCalculationService.convertToDecimal(lineRec, 'SBQQ__ListPrice__c');
                
                String key = productId + '-' + contractId;
                if (compositeKey == 'BIS' || compositeKey == 'RTIS' || compositeKey == 'Corp Legal') {
                    lineRec.put('Extended_Net_Monthly__c', 0);
                }
                
                if (generatedFrom == CPQConstants.QUOTE_TYPE_RENEWAL && segmentIndex != null && productBySubMap.containsKey(key)) {
                    SBQQ__Subscription__c sub = productBySubMap.get(key);
                    Decimal renewalPrice = sub.Extended_Net_Price__c;
                    Decimal OriginalListPrice = sub.SBQQ__SpecialPrice__c;
                    
                    if (OriginalListPrice != listPrice && (compositeKey == 'RTIS' || compositeKey == 'Corp Legal')) {
                        lineRec.put('RTK_Uplifted_Renewal_Price__c', 0);
                        continue;
                    }
                    
                    String currentKey = segmentKey + '-' + segmentIndex.intValue();
                    
                    if (uplift != 0) {
                        uplift = uplift / 100;
                    }
                    
                    if (segmentIndex == 1 && renewalPrice != null) {
                        Decimal uplifted = renewalPrice * (1 + uplift);
                        
                        if (sub.SBQQ__OriginalQuoteLine__c != null &&
                            sub.SBQQ__OriginalQuoteLine__r.SBQQ__Quantity__c > 0 &&
                            sub.SBQQ__OriginalQuoteLine__r.SBQQ__EffectiveQuantity__c > 0) {
                                
                                Decimal origQty = sub.SBQQ__OriginalQuoteLine__r.SBQQ__Quantity__c;
                                Decimal origEffQty = sub.SBQQ__OriginalQuoteLine__r.SBQQ__EffectiveQuantity__c;
                                uplifted = (renewalPrice * (1 + uplift)) / (origQty);
                                
                            } else {
                                Decimal origQty = sub.SBQQ__Quantity__c;
                                uplifted = (renewalPrice * (1 + uplift)) / origQty;
                            }
                        
                        lineRec.put('RTK_Uplifted_Renewal_Price__c', uplifted);
                        segmentKeyToRenewalPrice.put(currentKey, uplifted);
                       
                       
                        
                    } else if (segmentIndex > 1) {
                        String prevKey = segmentKey + '-' + (segmentIndex.intValue() - 1);
                        Decimal prevRenewal = segmentKeyToRenewalPrice.get(prevKey);
                        
                        if (prevRenewal != null) {
                            Decimal uplifted = prevRenewal * (1 + uplift);
                            lineRec.put('RTK_Uplifted_Renewal_Price__c', uplifted);
                            segmentKeyToRenewalPrice.put(currentKey, uplifted);
                        }
                    }
                }
            }
        }
        
    }
    
    /*
* - This method is used to calculate the EndDate from the subscription term of Quote in New Business & Renewal.
* - In Replacement Quote Extended Term is used to calculate the End Date.
* - If Extended Term is not provided then End Date is set to End Date from Previous Quote.
* - If Start Date is Leap Year then, End Date is set to 1 day prior after adding terms in Start Date.
*/
    public static void calculateEndDateForBIS(Map<String, Object> mapQuoteData){
        Date endDate = CoreCPQCalculationService.convertToDate(mapQuoteData, 'SBQQ__EndDate__c');
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData, 'SBQQ__Type__c');
        Date startDate = CoreCPQCalculationService.convertToDate(mapQuoteData, 'SBQQ__StartDate__c');
        Integer subscriptionTerm = CoreCPQCalculationService.convertToInteger(mapQuoteData,'SBQQ__SubscriptionTerm__c');
        Date endDateFromprevQuote = CoreCPQCalculationService.convertToDate(mapQuoteData, 'End_Date_from_Previous_Quote__c');
        Integer extendedTerm = CoreCPQCalculationService.convertToInteger(mapQuoteData,'Extended_Term__c');
        String generatedFrom = CoreCPQCalculationService.convertToString(mapQuoteData,'Generated_From__c');
        String qStatus = CoreCPQCalculationService.convertToString(mapQuoteData,'SBQQ__Status__c');
        // Calculating Partial Months 
        Integer partialMonths = Math.MOD(CoreCPQCalculationService.convertToInteger(mapQuoteData,'SBQQ__SubscriptionTerm__c'), 12);
        if(qStatus != 'Contracted'){
            if(subscriptionTerm != null && subscriptionTerm > 0 && generatedFrom != 'Trial'){
                if(quoteType == 'Quote' && startDate != null){
                    Integer startMonth = startDate.month();
                    Integer startDay = startDate.day();
                    
                    if (startDay == 29 && startMonth == 2) {
                        if(partialMonths == 0){
                            mapQuoteData.put('SBQQ__EndDate__c', startDate.addMonths(subscriptionTerm));
                        }else{
                            mapQuoteData.put('SBQQ__EndDate__c', startDate.addMonths(subscriptionTerm).addDays(-1));
                        }
                        
                    }else{
                        mapQuoteData.put('SBQQ__EndDate__c', startDate.addMonths(subscriptionTerm).addDays(-1));
                    }
                }else if(quoteType == 'Renewal'){
                    mapQuoteData.put('SBQQ__EndDate__c', startDate.addMonths(subscriptionTerm).addDays(-1));
                }else if(quoteType == 'Replacement'){
                    if(extendedTerm != null && endDateFromprevQuote != null && extendedTerm > 0){
                        mapQuoteData.put('SBQQ__EndDate__c', endDateFromprevQuote.addMonths(extendedTerm));
                    }else if(extendedTerm == null || extendedTerm == 0){
                        mapQuoteData.put('SBQQ__EndDate__c',endDateFromprevQuote);
                    }
                }
            }else{
                mapQuoteData.put('SBQQ__EndDate__c',endDate);
            }
        }
        // Debugging Logs
        System.debug('End Date Calculated :: ' + CoreCPQCalculationService.convertToDate(mapQuoteData, 'SBQQ__EndDate__c'));
    }
    
    /*
* - This method calculates the length of First Segment.
* - Calculates the First Segment Term End date by calculating the partial months.
* - If the Start Date is Leap Year then, End Date is set to 1 day prior after adding terms in Start Date.
* - In Replacement Quote, it calculates the First Segment End Date by checking the number of days between Start Date and End Date.
*/
    public static void calculateFirstSegmentEndDateForBIS(Map<String, Object> mapQuoteData){
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData,'SBQQ__Type__c');
        Integer subscriptionTerm = CoreCPQCalculationService.convertToInteger(mapQuoteData,'SBQQ__SubscriptionTerm__c');
        Date startDate = CoreCPQCalculationService.convertToDate(mapQuoteData,'SBQQ__StartDate__c');
        Date endDate = CoreCPQCalculationService.convertToDate(mapQuoteData,'SBQQ__EndDate__c');
        Date resegmentLineLogic = CoreCPQCalculationService.convertToDate(mapQuoteData, 'Resegment_Lines_Logic__c');
        String qStatus = CoreCPQCalculationService.convertToString(mapQuoteData,'SBQQ__Status__c');
        
        if(qStatus != 'Contracted'){ 
            if(quoteType == 'Quote' || quoteType == 'Renewal'){
                if(subscriptionTerm >= 12){
                    Integer partialMonths = Math.MOD(CoreCPQCalculationService.convertToInteger(mapQuoteData,'SBQQ__SubscriptionTerm__c'), 12);
                    
                    if (startDate != null) {
                        Integer startMonth = startDate.month();
                        Integer startDay = startDate.day();
                        
                        if (startDay == 29 && startMonth == 2) {
                            if(partialMonths == 0){
                                mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c', startDate.addMonths(12));
                               System.debug('SBQQ__FirstSegmentTermEndDate__c'+mapQuoteData.get('SBQQ__FirstSegmentTermEndDate__c'));
                                
                            }else{
                                mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c', startDate.addMonths(partialMonths).addDays(-1));
                                System.debug('SBQQ__FirstSegmentTermEndDate__c'+mapQuoteData.get('SBQQ__FirstSegmentTermEndDate__c'));
                            }
                        }else{
                            if(partialMonths == 0){
                                mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c',startDate.addMonths(12).addDays(-1));
                               System.debug('SBQQ__FirstSegmentTermEndDate__c'+mapQuoteData.get('SBQQ__FirstSegmentTermEndDate__c'));

                            }else{
                                Date firstSegmentEndDate = startDate.addMonths(partialMonths);
                                mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c',firstSegmentEndDate.addDays(-1));
                                System.debug('SBQQ__FirstSegmentTermEndDate__c'+mapQuoteData.get('SBQQ__FirstSegmentTermEndDate__c'));
                            }
                        }
                    }
                } else if(endDate != null && subscriptionTerm == 0){
                    mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c',resegmentLineLogic);
                }
                else{
                    mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c',null);
                }
            }
            
            // Calculating FirstSegmentTermEndDate for Replacement Quotes        
            if(quoteType == 'Replacement'){
                Integer startDateYear = startDate.year();
                Integer endDateYear = endDate.year();
                Integer countOfLeapYearDays = 0;
                Integer partialDays = startDate.daysBetween(endDate);
                system.debug('partialDays -- '+ partialDays);
                for(Integer i = startDateYear; i<= endDateYear; i++){
                    if(Math.Mod(i,4) == 0){
                        if(startDateYear == i){
                            if(startDate.Month() < 2 || (startDate.Month() == 2 && startDate.Day() <= 29)){
                                countOfLeapYearDays++;
                            }
                        }
                        else if(endDateYear == i){
                            if(endDate.Month() > 2 || (endDate.Month() == 2 && endDate.Day() == 29)){
                                countOfLeapYearDays++;
                            }
                        }
                        else if(startDateYear != i && endDateYear != i){
                            countOfLeapYearDays++;
                        }
                    }
                }
                System.debug('countOfLeapYearDays'+countOfLeapYearDays);
                if(partialDays < 365){
                    mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c', null);
                }else{
                    Integer remainingDays = Math.Mod(partialDays,365);
                    if(countOfLeapYearDays == 0 && remainingDays > 0){
                        mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c',startDate.addDays(remainingDays));
                    }else if(partialDays >= 365 && remainingDays == 0){
                        mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c',null);
                    }else if(partialDays > 365 && remainingDays > 0){
                        
                        Boolean hasLeapYearFebruary = false;
                        
                        Integer startYear = startDate.year();
                        Integer endYear = startDate.addDays(remainingDays).year();
                        
                        for (Integer year = startYear; year <= endYear; year++) {
                            // Check if it's a leap year
                            Boolean isLeapYear = (Math.Mod(year,4) == 0  && Math.Mod(year,100) != 0) || (Math.Mod(year,400) == 0);
                            
                            if (isLeapYear) {
                                Date febStart = Date.newInstance(year, 2, 1);
                                Date febEnd = Date.newInstance(year, 2, 29);
                                
                                // Check if any part of February in leap year is within 365 days from startDate
                                if ((febStart >= startDate && febStart <= startDate.addDays(remainingDays)) ||
                                    (febEnd >= startDate && febEnd <= startDate.addDays(remainingDays)) ||
                                    (startDate <= febStart && startDate.addDays(remainingDays) >= febEnd)) {
                                        hasLeapYearFebruary = true;
                                        break;
                                    }
                            }
                        }
                        if(hasLeapYearFebruary == true){
                            mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c',StartDate.addDays(remainingDays - countOfLeapYearDays+1));
                        }else{
                            mapQuoteData.put('SBQQ__FirstSegmentTermEndDate__c',StartDate.addDays(remainingDays - countOfLeapYearDays));
                        }
                        
                        System.debug('StartDate'+startDate.format());
                        System.debug('SBQQ__FirstSegmentTermEndDate__c'+ (remainingDays - countOfLeapYearDays));
                        System.debug('SBQQ__FirstSegmentTermEndDate__c------'+StartDate.addDays(349));
                    }
                }
            }
        }
        // Debugging Logs
        System.debug('First Segment End Date Calculated :: ' + CoreCPQCalculationService.convertToDate(mapQuoteData, 'SBQQ__FirstSegmentTermEndDate__c'));
    }
    
    /*
* - This method Calculates subscription term for Replacement
* - For Replacement, Start Date and End Date are calculated OOTB, so need to calculate term month as well.
* - It calculates months between start date and end date.
* - If the months are 0 then it checks for days remaining and if days remaining is greater than 0 then it sets subscription term to 1.
*/ 
    public static void calculateSubscriptionTermForReplacement(Map<String, Object> mapQuoteData){
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData, 'SBQQ__Type__c');
        Date startDate = CoreCPQCalculationService.convertToDate(mapQuoteData,'SBQQ__StartDate__c');
        Date endDate = CoreCPQCalculationService.convertToDate(mapQuoteData,'SBQQ__EndDate__c');
        Integer subscriptionTermQuote = CoreCPQCalculationService.convertToInteger(mapQuoteData,'SBQQ__SubscriptionTerm__c');
        
        if(quoteType == 'Replacement' || subscriptionTermQuote == 0){
            Integer subscriptionTerm = startDate.monthsBetween(endDate);
            if(subscriptionTerm == 0){
                Integer daysRemaining = startDate.daysBetween(endDate);
                if(daysRemaining > 0){
                    mapQuoteData.put('SBQQ__SubscriptionTerm__c',1);
                }
            }else{
                Integer daysRemaining = startDate.addMonths(subscriptionTerm).daysBetween(endDate);
                if(daysRemaining > 0){
                    subscriptionTerm +=1;   
                }
                mapQuoteData.put('SBQQ__SubscriptionTerm__c',subscriptionTerm);
            }
        }
        // Debugging Logs
        System.debug('Subscription Term Calculated :: ' + CoreCPQCalculationService.convertToInteger(mapQuoteData, 'SBQQ__SubscriptionTerm__c'));
    }
    
    /*
* - This method is used to calculate the YOY for Out Years.
* - It checks for the maximum number of segments and if the segment index is greater than the maximum number of segments then it sets the uplift to 0.
* - It also checks for the prior uplift and if it is null or 0 then it sets the uplift to the quote YOY growth.
* - It also checks for the prior YOY growth and if it is not equal to the quote YOY growth then it sets the uplift to the quote YOY growth.
* - It also checks for the segment index and if it is greater than 1 then it sets the uplift from quote YOY growth.
* - It also checks for the quote line number and if it is 1 then it sets the uplift to the quote YOY growth.
*/
    
    public static void calculateSegmentedUplifts(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        Map<Integer, Decimal> mapOfSegmentedUplift = new Map<Integer, Decimal>();
        Decimal priorYOYGrowth = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Prior_yoy_growth__c');
        Decimal quoteYOYGrowth = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'YoY_Growth__c');
        String generatedFrom = CoreCPQCalculationService.convertToString(mapQuoteData,'Generated_From__c');
        quoteYOYGrowth = quoteYOYGrowth.setScale(2, RoundingMode.HALF_UP);
        Integer maxNumberOfSegment = CoreCPQCalculationService.convertToInteger(mapQuoteData, 'Maximum_Number_Of_Segments__c');
        String compositeKey = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');
        
        for(Map<String, Object> lineRec: quoteLinedata){
            Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRec, 'SBQQ__SegmentIndex__c');
            Integer upliftQL = CoreCPQCalculationService.convertToInteger(lineRec, 'SBQQ__Uplift__c');
            Integer qoutelineNumber = CoreCPQCalculationService.convertToInteger(lineRec, 'SBQQ__Number__c');
            String requiredBy = CoreCPQCalculationService.convertToString(lineRec, 'SBQQ__RequiredBy__c');
            System.debug('requiredBy'+requiredBy);
            system.debug(' prior uplift -- '+ CoreCPQCalculationService.convertToIntegerReturnNull(lineRec, 'Prior_Uplift__c') + ' :: Uplift :: '+upliftQL + ' :: maxNumberOfSegment :: ' +maxNumberOfSegment  );
            if((maxNumberOfSegment < segmentIndex && maxNumberOfSegment != 0)
               ||((CoreCPQCalculationService.convertToIntegerReturnNull(lineRec, 'Prior_Uplift__c') == 0 || CoreCPQCalculationService.convertToIntegerReturnNull(lineRec, 'Prior_Uplift__c') == null) && upliftQL == 0 && segmentIndex > 1)){
                   lineRec.put('SBQQ__Uplift__c',quoteYOYGrowth);
               }
            if((priorYOYGrowth != quoteYOYGrowth && segmentIndex > 1)){
                lineRec.put('SBQQ__Uplift__c',quoteYOYGrowth);
            }
            else if(segmentIndex > 1 && qoutelineNumber == 1 ){
                mapOfSegmentedUplift.put(segmentIndex, CoreCPQCalculationService.convertToDecimal(lineRec, 'SBQQ__Uplift__c'));
            }
        }
        for(Map<String, Object> lineRec: quoteLinedata){
            Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRec, 'SBQQ__SegmentIndex__c');
            
            if(mapOfSegmentedUplift.containskey(segmentIndex) && segmentIndex > 1){
                lineRec.put('SBQQ__Uplift__c', mapOfSegmentedUplift.get(segmentIndex));
            }
            Double uplift = CoreCPQCalculationService.convertToDouble(lineRec, 'SBQQ__Uplift__c');
            lineRec.put('Prior_Uplift__c', uplift);
            system.debug('Prior_Uplift__c---');
        }
        
        mapQuoteData.put('Prior_yoy_growth__c',quoteYOYGrowth);
        mapQuoteData.put('YoY_Growth__c',quoteYOYGrowth);
        
    }
    
    /*
* - This method calculates the last segment number on quote.
*/
    public static void calculateMaximumSegmentIndexOnQuote(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        Integer maxSegment = 0;
        for(Map<String, Object> lineRec: quoteLinedata){
            Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRec, 'SBQQ__SegmentIndex__c');
            if(segmentIndex > maxSegment){
                maxSegment = segmentIndex;
            }
            system.debug('maximum number of segment -'+ maxSegment);
        }
        mapQuoteData.put('Maximum_Number_Of_Segments__c', maxSegment);
    }
    
    
    /*
* - This method calculates calculateAnnualAmount for gns
* - Annual Amount is sum of Customer Total of 1st segment
*/ 
    public static void calculateAnnualAmount(Map<String, Object> mapQuoteData,List<Map<String, Object>> quoteLinedata){
        Decimal sumOfCustomerTotal = 0;  
        for(Map<String, Object> lineRec: quoteLinedata){
            Double segmentIndex = CoreCPQCalculationService.convertToDouble(lineRec, 'SBQQ__SegmentIndex__c');
            Decimal netCustomerTotal = CoreCPQCalculationService.convertToDecimal(lineRec, 'SBQQ__CustomerTotal__c');
            if(segmentIndex <= 1 || segmentIndex == null ){ 
                sumOfCustomerTotal += netCustomerTotal;
            }
        }
        mapQuoteData.put('Annual_Amount__c',sumOfCustomerTotal);
    }
    
    /*
* - If Target is applied on bundle or Discretionary discount is applied on bundle or line level then we need to handle the penny issue according to bundle level.
* - If the Target Price Override is greater than 0 then it sets the isTargetPriceOverridden to true.
* - If the quote line discretionary is greater than 0 then it sets the isTargetPriceOrDDApplied to true.
* - isTargetPriceOrDDApplied is used to handle penny issues
*/    
    public static void calculateIsTargetPriceOverridden(Map<String, Object> mapQuoteData,List<Map<String, Object>> quoteLinedata){
        Boolean isTargetPriceOverridden = false;
        Boolean isTargetPriceOrDDApplied = false;
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData, 'SBQQ__Type__c');
        Decimal quoteDiscretionary = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'Discretionary_Discount__c');
        String compositeKey = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');
        String generatedFrom = CoreCPQCalculationService.convertToString(mapQuoteData, 'Generated_From__c');
        
        for(Map<String, Object> lineRec: quoteLinedata){
            Decimal TargetPriceOverride = CoreCPQCalculationService.convertToDecimal(lineRec, 'Target_Price_Override__c');
            Decimal quoteLineDiscretionary = CoreCPQCalculationService.convertToDecimal(lineRec,'SBQQ__DistributorDiscount__c');
            String requiredByProductCode = CoreCPQCalculationService.convertToString(lineRec,'bundleCode');
            String productName = CoreCPQCalculationService.convertToString(lineRec, 'SBQQ__ProductName__c');
            String bundleName = CoreCPQCalculationService.convertToString(lineRec, 'SBQQ__ProductName__c');
            Decimal priorDistributorDiscount = CoreCPQCalculationService.convertToDecimal(lineRec, 'priorDistributorDiscount');
            System.debug('::priorDistributorDiscount--'+priorDistributorDiscount);
            
            
            // We need to check if target override is applied. we need to support 0 target as well
            if(lineRec.containsKey('Target_Price_Override__c') && lineRec.get('Target_Price_Override__c')!=null ){ 
                isTargetPriceOverridden = true;
                isTargetPriceOrDDApplied = true;
                mapQuoteData.put(productName,true);
            }
            else if(quoteLineDiscretionary != null && quoteLineDiscretionary != 0 && requiredByProductCode == null){
                isTargetPriceOrDDApplied = true;
                mapQuoteData.put(productName,true);
            }
            // It is used to handle the credits to be same as previous purchase.Defined in UK method. For UK, penny calculation is done at bundle level and multiple bundles can be added.
            /*else if(quoteType == CPQConstants.QUOTE_TYPE_AMENDMENT && quantity!=0){
                isTargetPriceOrDDApplied = true;
                mapQuoteData.put(bundleName,true);
            }*/
            else if((compositeKey == 'BIS' || compositeKey == 'RTIS'  || compositeKey == 'Corp Legal') && generatedFrom =='Renewal' && quoteDiscretionary != null && quoteDiscretionary != 0  && requiredByProductCode == null){
                isTargetPriceOrDDApplied = true;
                mapQuoteData.put(productName,true);
            }
        }
        // isTargetPriceOverridden will nullfy Target amount and DD on Quote
        mapQuoteData.put('Is_Target_Price_Overridden__c',isTargetPriceOverridden);
        mapQuoteData.put('isTargetPriceOrDDApplied',isTargetPriceOrDDApplied);
    }
    
    //Clear AdditionalDiscountAmount
    public static void clearAdditionalDiscountAmount(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData, 'SBQQ__Type__c');
        Boolean isTargetPriceOverriden = CoreCPQCalculationService.convertToBoolean(mapQuoteData,'Is_Target_Price_Overridden__c');
        Boolean isTargetPriceOrDDApplied = CoreCPQCalculationService.convertToBoolean(mapQuoteData,'isTargetPriceOrDDApplied');
        
        
        if(quoteType == 'Renewal' && (isTargetPriceOverriden || isTargetPriceOrDDApplied)){
            for(Map<String, Object> lineRec: quoteLinedata){
                Decimal segmentIndex = CoreCPQCalculationService.convertToDouble(lineRec, 'SBQQ__SegmentIndex__c');
                String bundleName = CoreCPQCalculationService.convertToString(lineRec,'Bundle_Name__c');
                String productName = CoreCPQCalculationService.convertToString(lineRec,'SBQQ__ProductName__c');
                String key = bundleName == null ? productName : bundleName;
                
                if((segmentIndex >= 1 || bundleName == null)  && mapQuoteData.get(key) == true){
                    lineRec.put('SBQQ__AdditionalDiscountAmount__c',0);                                                   
                    lineRec.put('Extended_Net_Monthly__c', 0);
                    lineRec.put('RTK_Additional_Discount_Amt__c',0); 
                }
            }
            System.debug('inside the clearAdditionalDiscountAmount');
        }
        
    }
    
    
    /* 
* - Changes on one segment needs to be reflect on outyears segment , so need to map values.
*/ 
    public static void calculateMapping(Map<String, Object> mapQuoteData,List<Map<String, Object>> quoteLinedata){
        Map<String, Object> segmentMap = new Map<String, Object>();
        String compositeKey = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');
        for(Map<String, Object> lineRecord : quoteLinedata) {
            Double segmentIndex = CoreCPQCalculationService.convertToDouble(lineRecord, 'SBQQ__SegmentIndex__c');
            String productName = CoreCPQCalculationService.convertToString(lineRecord, 'SBQQ__ProductName__c');
            Decimal discount = CoreCPQCalculationService.convertToDecimal(lineRecord,'Product_Mix_Discount__c');
            Decimal discretionaryDiscount = CoreCPQCalculationService.convertToDecimal(lineRecord,'SBQQ__DistributorDiscount__c');
            System.debug('discretionaryDiscount'+discretionaryDiscount);
            Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRecord ,'SBQQ__NonDiscountable__c');
            if(segmentIndex == 1 && !nonDiscountable){
                segmentMap.put(productName ,discount);
                segmentMap.put(productName +'Excluded__c',CoreCPQCalculationService.convertToBoolean(lineRecord, 'Excluded__c'));
                segmentMap.put(productName + 'Free_Product__c',CoreCPQCalculationService.convertToBoolean(lineRecord, 'Free_Product__c'));
                if(discretionaryDiscount > 0 && discretionaryDiscount !=null){
                    segmentMap.put(productName + 'discretionaryDiscount' , discretionaryDiscount);
                }
            }
        }
        system.debug('segment Map - '+segmentMap);
        for (Map<String, Object> lineRecord : quoteLinedata) {
            Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRecord ,'SBQQ__NonDiscountable__c');
            Double segmentIndex = CoreCPQCalculationService.convertToDouble(lineRecord, 'SBQQ__SegmentIndex__c');
            String productName = CoreCPQCalculationService.convertToString(lineRecord, 'SBQQ__ProductName__c');
            String ExcludedKey = CoreCPQCalculationService.convertToString(lineRecord,'SBQQ__ProductName__c')+'Excluded__c';
            String FreeProduct = CoreCPQCalculationService.convertToString(lineRecord,'SBQQ__ProductName__c') +'Free_Product__c' ;
            String discretionaryDiscountKey = CoreCPQCalculationService.convertToString(lineRecord,'SBQQ__ProductName__c') +'discretionaryDiscount' ;
            System.debug('discretionaryDiscountKey'+discretionaryDiscountKey);
            if(!nonDiscountable){
                if(segmentIndex != 1){
                    lineRecord.put('Product_Mix_Discount__c',segmentMap.get(productName));
                    if(!CPQConstants.CPQ_COMPOSITE_EXCLUDE_PRODUCT_MIX_DISCOUNT.contains(compositeKey)){
                        lineRecord.put('SBQQ__PartnerDiscount__c', segmentMap.get(productName));
                    }
                    if(segmentMap.containsKey(discretionaryDiscountKey)){
                        System.debug('enter in the block');
                        lineRecord.put('SBQQ__DistributorDiscount__c', segmentMap.get(discretionaryDiscountKey));
                        System.debug('Distributer Discount'+segmentMap.get(discretionaryDiscountKey));
                    }
                }
                system.debug('Segment Index - '+segmentIndex+ ' Distributor discount '+lineRecord.get('SBQQ__DistributorDiscount__c'));
                if (segmentMap.containsKey(ExcludedKey)) {
                    lineRecord.put('Excluded__c', Boolean.valueOf(segmentMap.get(ExcludedKey)));
                }
                if (segmentMap.containsKey(FreeProduct)) {
                    lineRecord.put('Free_Product__c',Boolean.valueOf(segmentMap.get(FreeProduct)));
                }
            }
        }
    }
    
    /*   
* - This method calculates bundle amount for each bundle in Quotes
* - Bundle Amount is sum of Net Monthly of all the first segment lines or non segment lines in the bundle.
*/
    public static void calculateBundleAmount(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        Map<String, Decimal> quoteLineNetMonthlyData = new Map<String, Decimal>();
        String compositeKey = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');
        for(Map<String, Object> lineRec: quoteLinedata){
            Decimal extendedNetMontly = CoreCPQCalculationService.convertToDecimal(lineRec,'Extended_Net_Monthly__c');
            Decimal NetMonthly = CoreCPQCalculationService.convertToDecimal(lineRec, 'Net_Monthly__c');
            String requiredByProductCode = CoreCPQCalculationService.convertToString(lineRec,'bundleCode');
            String productCode = CoreCPQCalculationService.convertToString(lineRec,'SBQQ__ProductCode__c');
            String ProductSubscriptionType = CoreCPQCalculationService.convertToString(lineRec,'SBQQ__ProductSubscriptionType__c');
            Boolean isBundleProduct = CoreCPQCalculationService.convertToBoolean(lineRec,'SBQQ__Bundle__c');
            System.debug('test--00001-1-10-1' +  CoreCPQCalculationService.convertToBoolean(lineRec,'Excluded__c'));
            if(!isBundleProduct){
                if( CoreCPQCalculationService.convertToBoolean(lineRec,'Excluded__c')  || CoreCPQCalculationService.convertToBoolean(lineRec,'Free_Product__c') ){
                    netMonthly =0;
                }else if(extendedNetMontly != null && extendedNetMontly != 0){
                    netMonthly = extendedNetMontly;
                }else{
                    netMonthly = CoreCPQCalculationService.convertToDecimal(lineRec,'Target_Price_Monthly__c') - CoreCPQCalculationService.convertToDecimal(lineRec,'Negotiated_Disc_Amt__c');
                }
                
                Decimal roundednetMonthly = netMonthly;
                if(compositeKey != 'United Kingdom'){
                    roundednetMonthly = netMonthly.setScale(2, RoundingMode.HALF_UP);
                }
                
                Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRec,'SBQQ__SegmentIndex__c');
                
                if(segmentIndex <= 1 && ProductSubscriptionType != 'One-time' && ProductSubscriptionType !=null){
                    if (requiredByProductCode != null) {
                        system.debug('productCode --'+productCode + 'roundednetMonthly--' + roundednetMonthly);
                        if (!quoteLineNetMonthlyData.containskey(requiredByProductCode)) {
                            quoteLineNetMonthlyData.put(requiredByProductCode, NetMonthly);
                        } else {
                            Decimal requiredBySum = quoteLineNetMonthlyData.get(requiredByProductCode) + roundednetMonthly;
                            system.debug('requiredBySum---'+requiredBySum);
                            quoteLineNetMonthlyData.put(requiredByProductCode, requiredBySum);
                        }
                    }
                    else if(!isBundleProduct){
                        if (!quoteLineNetMonthlyData.containskey(productCode)) {
                            quoteLineNetMonthlyData.put(productCode, NetMonthly);
                        } else {
                            Decimal requiredBySum = quoteLineNetMonthlyData.get(productCode) + roundednetMonthly;
                            system.debug('requiredBySum---'+requiredBySum);
                            quoteLineNetMonthlyData.put(productCode, requiredBySum);
                        }
                    }
                }
            }
        }
        system.debug('quoteLineNetMonthlyData--' + quoteLineNetMonthlyData);
        for(Map<String, Object> lineRec: quoteLinedata){
            String bundleName = CoreCPQCalculationService.convertToString(lineRec,'bundleName');
            if(bundleName == null){
                String BundleProductCode = CoreCPQCalculationService.convertToString(lineRec,'SBQQ__ProductCode__c');
                if (quoteLineNetMonthlyData.containskey(BundleProductCode)){
                    lineRec.put('Bundle_Amount__c',quoteLineNetMonthlyData.get(BundleProductCode));
                }
            }
        }
    }
    
    /*
* - This method calculates bundle Amount when we give Target Price Override 
* - This method calculates Distributor Discount on Quote Line Item and update Target price monthly
*/
    public static void calculateTargetBundleAmount(Map<String, Object> mapQuoteData,List<Map<String, Object>> quoteLinedata){
        Map<String, Decimal> negoPriceMonthlyMap = new Map<String, Decimal>();
        String compositeKey = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');
        String generatedFrom = CoreCPQCalculationService.convertToString(mapQuoteData, 'Generated_From__c');
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData, 'SBQQ__Type__c');
        
        Map<String, Decimal> targetPriceOverrideMap = new Map<String, Decimal>();
        Map<String, Decimal> mapOfNonDiscountableProductsByNetMonthly = new Map<String, Decimal>();
        for(Map<String, Object> lineRec: quoteLinedata){
            Decimal targetPriceOverride = CoreCPQCalculationService.convertToDecimal(lineRec,'Target_Price_Override__c');
            String bundleName = CoreCPQCalculationService.convertToString(lineRec,'bundleName');
            String BundleProductCode = CoreCPQCalculationService.convertToString(lineRec,'bundleCode');
            Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRec,'SBQQ__SegmentIndex__c');
            Decimal negoPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRec, 'Negotiated_Price_Monthly__c');
            String productCode = CoreCPQCalculationService.convertToString(lineRec,'SBQQ__ProductCode__c');
            String ProductSubscriptionType = CoreCPQCalculationService.convertToString(lineRec,'SBQQ__ProductSubscriptionType__c');
            Boolean isBundleProduct = CoreCPQCalculationService.convertToBoolean(lineRec,'SBQQ__Bundle__c');
            Boolean isNonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRec,'SBQQ__NonDiscountable__c');
            system.debug('Product code - '+productCode  + ' :: ProductSubscriptionType '+ProductSubscriptionType);
            system.debug('targetPriceOverride '+targetPriceOverride + ' - Bundle name -- '+bundleName);
            if(segmentIndex <= 1 && ProductSubscriptionType != 'One-time' && ProductSubscriptionType !=null){
                if(isNonDiscountable){
                    if(!mapOfNonDiscountableProductsByNetMonthly.containskey(BundleProductCode)){
                        mapOfNonDiscountableProductsByNetMonthly.put(BundleProductCode, negoPriceMonthly);
                    }else{
                        Decimal targetPrice = mapOfNonDiscountableProductsByNetMonthly.get(BundleProductCode) + negoPriceMonthly;
                        mapOfNonDiscountableProductsByNetMonthly.put(BundleProductCode, targetPrice);
                    }
                }
                if(bundleName != null && !isNonDiscountable){
                    
                    if(!negoPriceMonthlyMap.containskey(BundleProductCode)){
                        negoPriceMonthlyMap.put(BundleProductCode, negoPriceMonthly);
                    }else{
                        Decimal targetPrice = negoPriceMonthlyMap.get(BundleProductCode) + negoPriceMonthly;
                        negoPriceMonthlyMap.put(BundleProductCode, targetPrice);
                    }
                    
                }else if(!isBundleProduct && !isNonDiscountable){
                    if(!negoPriceMonthlyMap.containskey(productCode)){
                        negoPriceMonthlyMap.put(productCode, negoPriceMonthly);
                    }else{
                        Decimal targetPrice = negoPriceMonthlyMap.get(productCode) + negoPriceMonthly;
                        negoPriceMonthlyMap.put(productCode, targetPrice);
                    }
                }
            } else if(segmentIndex <= 1 && ProductSubscriptionType == 'One-time' && !isBundleProduct && bundleName == null){
                negoPriceMonthlyMap.put('OneTime ' + productCode, negoPriceMonthly);
            }
            if(bundleName == null){
                // We need to check if target override is applied. we need to support 0 target as well
                if(lineRec.get('Target_Price_Override__c') != null){
                    mapQuoteData.put('Negotiated_Price_Target__c', null);
                    targetPriceOverrideMap.put(productCode,targetPriceOverride);
                    
                }
            }
        }
        system.debug('negoPriceMonthlyMap - ' + negoPriceMonthlyMap);
        system.debug('targetPriceOverrideMap - ' + targetPriceOverrideMap);
        system.debug('mapOfNonDiscountableProductsByNetMonthly - ' + mapOfNonDiscountableProductsByNetMonthly);
        
        Map<String, Decimal> distributorDiscountMap = new Map<String, Decimal>();
        for(Map<String, Object> lineRec: quoteLinedata){
            String productCode = CoreCPQCalculationService.convertToString(lineRec,'SBQQ__ProductCode__c');
            String bundleName = CoreCPQCalculationService.convertToString(lineRec,'bundleName');
            Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRec ,'SBQQ__NonDiscountable__c');
            String ProductSubscriptionType = CoreCPQCalculationService.convertToString(lineRec,'SBQQ__ProductSubscriptionType__c');
            system.debug('Bundle Name'+bundleName);
            if(bundleName == null){
                if(!targetPriceOverrideMap.isEmpty() && !nonDiscountable && targetPriceOverrideMap.containsKey(productCode)){
                    Decimal nonDiscountProductsAmt = mapOfNonDiscountableProductsByNetMonthly.containsKey(productCode) ? mapOfNonDiscountableProductsByNetMonthly.get(productCode) : 0;
                    Decimal targetdPrice = targetPriceOverrideMap.containsKey(productCode) ? targetPriceOverrideMap.get(productCode) : 0;
                    Decimal bundleTarget = targetdPrice - nonDiscountProductsAmt;
                    system.debug('bundleTarget--' + bundleTarget);
                    Decimal bundleAmount = 0;
                    if(ProductSubscriptionType == 'One-time' && ProductSubscriptionType !=null && negoPriceMonthlyMap.containsKey('OneTime ' + productCode)){
                        bundleAmount = negoPriceMonthlyMap.get('OneTime ' + productCode);
                    } else if(negoPriceMonthlyMap.containsKey(productCode)){
                        bundleAmount = negoPriceMonthlyMap.get(productCode);
                    }
                    if(bundleAmount != 0){
                        Decimal numerator = bundleAmount - bundleTarget;
                        Decimal denominator = bundleAmount;
                        Decimal result = (numerator/denominator)*100;
                        distributorDiscountMap.put(productCode, result);
                    }
                }
            }
        }
        system.debug('distributorDiscountMap -- '+distributorDiscountMap);
        for(Map<String, Object> lineRec: quoteLinedata){
            String productCode = CoreCPQCalculationService.convertToString(lineRec,'SBQQ__ProductCode__c');
            Decimal negotiatedPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRec, 'Negotiated_Price_Monthly__c');
            Decimal distributorDiscountQL = CoreCPQCalculationService.convertToDecimal(lineRec, 'SBQQ__DistributorDiscount__c');
            String bundleCode = CoreCPQCalculationService.convertToString(lineRec,'bundleCode');
            Boolean isBundleProduct = CoreCPQCalculationService.convertToBoolean(lineRec,'SBQQ__Bundle__c');
            String ProductSubscriptionType = CoreCPQCalculationService.convertToString(lineRec,'SBQQ__ProductSubscriptionType__c');
            Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRec ,'SBQQ__NonDiscountable__c');
            Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRec,'SBQQ__SegmentIndex__c');
            Decimal multiYearTermDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Multi_Year_Term_Discount__c');
            if(!nonDiscountable && ProductSubscriptionType != 'One-time' && ProductSubscriptionType !=null ){
                system.debug('distributorDiscountMap '+distributorDiscountMap);
                
                if(!distributorDiscountMap.isEmpty()){
                    if(distributorDiscountMap.containskey(bundleCode)){
                        if ((compositeKey == 'BIS' ||compositeKey == 'RTIS' )&& generatedFrom == 'Renewal') {
                            lineRec.put('SBQQ__AdditionalDiscountAmount__c', 0);
                        }
                        if(segmentIndex == 1){
                            lineRec.put('SBQQ__DistributorDiscount__c', distributorDiscountMap.get(bundleCode)); 
                        }
                        Decimal discountValue = distributorDiscountMap.get(bundleCode);
                        // Subtract multiYearTermDiscount if segment > 1
                        if(segmentIndex > 1 && multiYearTermDiscount != null  && (quoteType != CPQConstants.QUOTE_TYPE_AMENDMENT || negotiatedPriceMonthly > 0)){
                            discountValue = discountValue - multiYearTermDiscount;
                            lineRec.put('SBQQ__DistributorDiscount__c',distributorDiscountMap.get(bundleCode));
                        }
                        Decimal updatedDistributorDiscount = CoreCPQCalculationService.convertToDecimal(lineRec, 'SBQQ__DistributorDiscount__c');
                        lineRec.put('Target_Price_Monthly__c', negotiatedPriceMonthly * (1 - (updatedDistributorDiscount / 100)));
                    }else if(distributorDiscountMap.containskey(productCode) && !isBundleProduct){
                        if(bundleCode == null && segmentIndex == 0){
                            lineRec.put('SBQQ__DistributorDiscount__c', distributorDiscountMap.get(productCode));
                        }
                        if(segmentIndex == 1){
                            lineRec.put('SBQQ__DistributorDiscount__c', distributorDiscountMap.get(productCode)); 
                        }
                        Decimal discountValue = distributorDiscountMap.get(productCode);
                        // Subtract multiYearTermDiscount if segment > 1
                        if(segmentIndex > 1 && multiYearTermDiscount != null){
                            discountValue = discountValue - multiYearTermDiscount;
                            lineRec.put('SBQQ__DistributorDiscount__c',distributorDiscountMap.get(productCode));
                            
                        }
                        Decimal updatedDistributorDiscount = CoreCPQCalculationService.convertToDecimal(lineRec, 'SBQQ__DistributorDiscount__c');
                        lineRec.put('Target_Price_Monthly__c', negotiatedPriceMonthly * (1 - (updatedDistributorDiscount / 100)));
                    }
                    
                    system.debug('bundle Name -'+bundleCode +'product Code -'+productCode+'discount -'+distributorDiscountMap.get(bundleCode));
                }else{
                    if(distributorDiscountQL != null){
                        lineRec.put('Target_Price_Monthly__c', negotiatedPriceMonthly * (1 - distributorDiscountQL/100));
                    }else{
                        Decimal distributorDiscQuote = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'SBQQ__DistributorDiscount__c');
                        lineRec.put('Target_Price_Monthly__c', negotiatedPriceMonthly * (1 - distributorDiscQuote/100));
                    }
                }
            } else if(ProductSubscriptionType == 'One-time' && ProductSubscriptionType !=null && lineRec.get('Target_Price_Override__c') != null && distributorDiscountMap.containskey(productCode)){
                lineRec.put('SBQQ__DistributorDiscount__c', distributorDiscountMap.get(productCode));
            }
             
            System.debug('segmentIndex -- :: '+segmentIndex+' :: productCode :: '+productCode+ ' :: Distributor Discount :: '+lineRec.get('SBQQ__DistributorDiscount__c'));
        }
    }
    /*
* - This method calculates product mix discount and partner discount for gns
* - It does not apply for AAR and Fixed Term Extension Quotes
* - It applies only for Research Bundle
*/
    public static void calculatePartnerDiscount(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        Integer countOfContentSetTier1 = 0;
        String generatedFrom = CoreCPQCalculationService.convertToString(mapQuoteData,'Generated_From__c');
        Boolean trialFlag = CoreCPQCalculationService.convertToBoolean(mapQuoteData,'Trial_Flag__c');
        
        if(trialFlag == false && generatedFrom != 'AAR' &&  generatedFrom != 'Fixed Term Extension'){
            for(Map<String, Object> lineRec: quoteLinedata){
                String bundleName = CoreCPQCalculationService.convertToString(lineRec,'bundleName');
                Double segmentIndex = CoreCPQCalculationService.convertToDouble(lineRec, 'SBQQ__SegmentIndex__c');
                if(CoreCPQCalculationService.convertToString(lineRec,'Content_Tier__c') == CPQConstants.CONTENT_SET_TIER_1 && bundleName == CPQConstants.BUNDLE_RESEARCH_BUNDLE && segmentIndex == 1 ){
                    countOfContentSetTier1 += 1;
                }
            }
            for(Map<String, Object> lineRec: quoteLinedata){
                String bundleName = CoreCPQCalculationService.convertToString(lineRec,'bundleName');
                Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRec ,'SBQQ__NonDiscountable__c');
                if(!nonDiscountable && CoreCPQCalculationService.convertToString(lineRec,'Content_Tier__c') == CPQConstants.CONTENT_SET_TIER_1 && bundleName == CPQConstants.BUNDLE_RESEARCH_BUNDLE){
                    if(countOfContentSetTier1 == 2){
                        lineRec.put('Product_Mix_Discount__c', 10);
                        lineRec.put('SBQQ__PartnerDiscount__c', 10);
                    }else if(countOfContentSetTier1 > 2){
                        lineRec.put('Product_Mix_Discount__c', 15);
                        lineRec.put('SBQQ__PartnerDiscount__c', 15);
                    }else{
                        lineRec.put('Product_Mix_Discount__c', 0);
                         lineRec.put('SBQQ__PartnerDiscount__c', 0);
                    }
                }
            }
        }
    }
    
    /*
* - This method calculates the MultiYear Term Discount On Quote For BIS
* - It checks the subscription term and if it is greater than 12 and less than or equal to 24 then it sets the Multi Year Term Discount to 5.
* - If it is greater than 24 and less than or equal to 36 then it sets the Multi Year Term Discount to 10.
* - Else it sets the Multi Year Term Discount to 0.
*/
    
    public static void multiYearTermDiscount(Map<String, Object> mapQuoteData){
        Integer subscriptionTerm = CoreCPQCalculationService.convertToInteger(mapQuoteData,'SBQQ__SubscriptionTerm__c');
        if(subscriptionTerm >= 24 && subscriptionTerm <= 35){
            mapQuoteData.put('Multi_Year_Term_Discount__c',5);
        }else if(subscriptionTerm >= 36){
            mapQuoteData.put('Multi_Year_Term_Discount__c',10);
        }else{
            mapQuoteData.put('Multi_Year_Term_Discount__c',0);
        }
    }
    
    /*
* - This method calculates Discretionary/Distributor Discount for gNS Quotes
* - It does not apply for AAR and Fixed Term Extension Quotes
* - It applies only for First Segment 
* - It Calculates Discretionary Discount on Quote and Distributor Discount on Quote Line Item for the Target Customer Amount
*/
    public static void calculateDiscretionaryDiscountOnQuoteForBIS(Map<String, Object> mapQuoteData,List<Map<String, Object>> quoteLinedata){
        Decimal firstSegmentListAmount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'First_Segment_List_Amount2__c');
        Decimal fistSegmentFreeProductList = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'FirstSegment_Free_Product_List__c');
        Decimal targetCustomerAmount = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'Negotiated_Price_Target__c');
        Decimal multiYearTermDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Multi_Year_Term_Discount__c');
        Boolean trialFlag = CoreCPQCalculationService.convertToBoolean(mapQuoteData,'Trial_Flag__c');
        String generatedFrom = CoreCPQCalculationService.convertToString(mapQuoteData,'Generated_From__c');
        String compositeKey = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData, 'SBQQ__Type__c');
        
        Decimal quoteDiscretionary = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'Discretionary_Discount__c');
        Decimal DiscountTotal = 0;
        Decimal DiscountTotalOne=0;
        Decimal nonDiscountableAmountQuote = 0;
        
        for(Map<String, Object> lineRecord : quoteLinedata){
            Decimal negotiatedPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRecord, 'Negotiated_Price_Monthly__c');
            Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRecord ,'SBQQ__NonDiscountable__c');  
            Double segmentIndex = CoreCPQCalculationService.convertToDouble(lineRecord, 'SBQQ__SegmentIndex__c');
            if(nonDiscountable && segmentIndex == 1){
                nonDiscountableAmountQuote += negotiatedPriceMonthly;
            }
        }
        System.debug('trialFlag  ::' +  trialFlag + ' generatedFrom : ' + generatedFrom);
        if(trialFlag == false && generatedFrom != 'AAR' &&  generatedFrom != 'Fixed Term Extension'){
            if(targetCustomerAmount > 0){
                targetCustomerAmount = targetCustomerAmount - nonDiscountableAmountQuote;
                Decimal numerator = firstSegmentListAmount - fistSegmentFreeProductList - targetCustomerAmount;
                Decimal denominator = firstSegmentListAmount - fistSegmentFreeProductList;
                if(denominator > 0){
                    Decimal distributorDiscount = (numerator / denominator) *100;
                    Decimal DiscretionaryDiscount = distributorDiscount - multiYearTermDiscount ;
                    Decimal distributorDiscountone = DiscretionaryDiscount + multiYearTermDiscount;
                    mapQuoteData.put('Discretionary_Discount__c',DiscretionaryDiscount);  
                    for(Map<String, Object> lineRecord : quoteLinedata) {
                        Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRecord, 'SBQQ__NonDiscountable__c');
                        Double segmentIndex = CoreCPQCalculationService.convertToDouble(lineRecord, 'SBQQ__SegmentIndex__c');
                        String ProductSubscriptionType = CoreCPQCalculationService.convertToString(lineRecord,'SBQQ__ProductSubscriptionType__c');
                        System.debug('ProductSubscriptionType'+ProductSubscriptionType);
                        if(segmentIndex == 1 && !nonDiscountable ){
                            DiscountTotal += distributorDiscountone;
                            lineRecord.put('SBQQ__DistributorDiscount__c', distributorDiscountone);
                        }
                        if(segmentIndex > 1 && !nonDiscountable  ){
                            lineRecord.put('SBQQ__DistributorDiscount__c', distributorDiscountone);
                        }
                        if(!nonDiscountable && ProductSubscriptionType != 'One-time' && segmentIndex != null){
                            System.debug('enter into the block');
                            if(segmentIndex == 1) lineRecord.put('SBQQ__DistributorDiscount__c', distributorDiscountone);
                            if(segmentIndex > 1) lineRecord.put('SBQQ__DistributorDiscount__c', distributorDiscountone);
                            System.debug('distributorDiscountone'+distributorDiscountone);
                        }
                    }
                }
            }else{
                for(Map<String, Object> lineRecord : quoteLinedata) {
                    Double segmentIndex = CoreCPQCalculationService.convertToDouble(lineRecord, 'SBQQ__SegmentIndex__c');
                    Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRecord, 'SBQQ__NonDiscountable__c');
                    Decimal AdditionalDiscAmount = CoreCPQCalculationService.convertToDecimal(lineRecord, 'SBQQ__AdditionalDiscountAmount__c');
                    Decimal RTKadditionalDiscAmount = CoreCPQCalculationService.convertToDecimal(lineRecord,'RTK_Additional_Discount_Amt__c');
                    
                    if(segmentIndex == 1 && !nonDiscountable){
                        // DiscountTotalOne += multiYearTermDiscount;
                        lineRecord.put('SBQQ__DistributorDiscount__c', multiYearTermDiscount);
                        
                    }
                    if(segmentIndex > 1 && !nonDiscountable  ){
                        lineRecord.put('SBQQ__DistributorDiscount__c', 0);
                    }
                    if(segmentIndex >= 1 && !nonDiscountable && (compositeKey == 'BIS' || compositeKey == 'RTIS' || compositeKey == 'Corp Legal')&& quoteType == 'Renewal' && RTKadditionalDiscAmount>0 && AdditionalDiscAmount >0 ){
                        lineRecord.put('SBQQ__DistributorDiscount__c', 0);
                        
                    }
                }
            }
            if(quoteDiscretionary != null && quoteDiscretionary > 0 && (targetCustomerAmount == null || targetCustomerAmount == 0)){
                for(Map<String, Object> lineRecord : quoteLinedata){
                    Double segmentIndex = CoreCPQCalculationService.convertToDouble(lineRecord, 'SBQQ__SegmentIndex__c');
                    Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRecord, 'SBQQ__NonDiscountable__c');
                    if(segmentIndex == 1 && !nonDiscountable){
                        
                        lineRecord.put('SBQQ__DistributorDiscount__c', (quoteDiscretionary + multiYearTermDiscount));
                        System.debug('SBQQ__DistributorDiscount__c one'+ (quoteDiscretionary + multiYearTermDiscount));
                    }
                    if(segmentIndex > 1 && !nonDiscountable){
                        
                        lineRecord.put('SBQQ__DistributorDiscount__c', quoteDiscretionary);
                        System.debug('SBQQ__DistributorDiscount__c one'+ (quoteDiscretionary + multiYearTermDiscount));
                    }
                    
                }
            }
        }
    }
    /*
* - This method calculates First Segment List Amount For Quote and Per Bundle
* - It calculates the sum of Negotiated Price Monthly for all the lines of 1st Segment in the first segment. 
*/
    public static void calculateFirstSegmentListAmount(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        Decimal firstSegmentListAmount = 0;
        for(Map<String, Object> lineRec: quoteLinedata){
            Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRec,'SBQQ__SegmentIndex__c');
            Boolean isBundleProduct = CoreCPQCalculationService.convertToBoolean(lineRec,'SBQQ__Bundle__c');
            Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRec ,'SBQQ__NonDiscountable__c');
            if(segmentIndex == 1 && !isBundleProduct && !nonDiscountable){
                Decimal negotiatedPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRec, 'Negotiated_Price_Monthly__c');
                firstSegmentListAmount += negotiatedPriceMonthly;
            }
        }
        mapQuoteData.put('First_Segment_List_Amount2__c',firstSegmentListAmount);
    }
    
    
    
    /** 
* - Extended Monthly To Zero for all child lines and standalone lines
**/  
    
    public static void calculateExtendedMonthlyToZero(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        Map<String, Decimal> mapOfBundle = new Map<String, Decimal>();
        for(Map<String, Object> lineRecord : quoteLinedata) {
            Decimal bundleAmount = CoreCPQCalculationService.convertToDecimal(lineRecord, 'Bundle_Amount__c');
            Decimal targetPriceOverride = CoreCPQCalculationService.convertToDecimal(lineRecord, 'Target_Price_Override__c');
            String requiredByProductCode = CoreCPQCalculationService.convertToString(lineRecord,'BundleCode');
            String productCode = CoreCPQCalculationService.convertToString(lineRecord,'SBQQ__ProductCode__c');
            System.debug('requiredByProductCode'+requiredByProductCode + ' :: productCode :: '+productCode + ' :: bundleAmount :: '+bundleAmount + ' :: targetPriceOverride :: '+targetPriceOverride);
            if(requiredByProductCode == null){ 
                if(!mapOfBundle.containskey(productCode)){
                    if (targetPriceOverride != bundleAmount) {
                        mapOfBundle.put(productCode, bundleAmount);
                    }
                }    
            }
        }
        for(Map<String, Object> lineRecord : quoteLinedata) {
            String requiredByProductCode = CoreCPQCalculationService.convertToString(lineRecord,'bundleCode');
            String productCode = CoreCPQCalculationService.convertToString(lineRecord,'SBQQ__ProductCode__c');
            Boolean isBundleLine = CoreCPQCalculationService.convertToBoolean(lineRecord, 'SBQQ__Bundle__c');
            System.debug('requiredByProductCode'+requiredByProductCode + ' :: productCode :: '+productCode + ' :: isBundleLine :: ');
            if(mapOfBundle.containskey(requiredByProductCode) || (!isBundleLine && mapOfBundle.containskey(productCode))){
                lineRecord.put('Extended_Net_Monthly__c',0);
            } 
        }
    }
    
    /**
* - Missing Penny on the Quote line.
* - if Target Price Override or Disc Discount on Bundle Level is applied then it calculates the missing penny on the bundle level.
* - if Target Price Override or Disc Discount on Bundle Level is not applied then it calculates the missing penny on the quote level.
* - Negotiated Price and Target Price  is compared and if they are not equal then it calculates the missing penny.
**/
    
    public static void calculateMissingPenny(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        Boolean TargetPriceOverride = CoreCPQCalculationService.convertToBoolean(mapQuoteData, 'isTargetPriceOrDDApplied');
        String compositeKey = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');
        System.debug('TargetPriceOverride'+TargetPriceOverride);
        if(TargetPriceOverride == true ||compositeKey == 'United Kingdom'){
            Map<String, Decimal> mapOfNegoPrices = new Map<String, Decimal>();
            Map<String, Decimal> mapOfTargetPrices = new Map<String, Decimal>();
            Map<String, Decimal> mapOfBundleByMissingPenny = new Map<String, Decimal>();
            calculateNegoPriceOnBundle(mapQuoteData, quoteLinedata, mapOfNegoPrices); 
            calculateTargetPriceOnBundle(mapQuoteData, quoteLinedata,mapOfTargetPrices); 
            System.debug('mapOfNegoPrices '+mapOfNegoPrices + ' :: mapOfTargetPrices :: '+mapOfTargetPrices);
            for (String bundleCode : mapOfNegoPrices.keySet()) {
                Decimal negoPrice = mapOfNegoPrices.get(bundleCode);
                Decimal targetPrice = mapOfTargetPrices.get(bundleCode);
                system.debug('negoPrice==' + negoPrice);
                system.debug('targetPrice==' + targetPrice);
                if(negoPrice != null && targetPrice != null && negoPrice != targetPrice){
                    Decimal missingPenny =negoPrice- targetPrice;
                    System.debug('missingPenny'+missingPenny);
                    mapOfBundleByMissingPenny.put(bundleCode,missingPenny);
                }
            }
            System.debug('mapOfBundleByMissingPenny1 '+mapOfBundleByMissingPenny);
            if(!mapOfBundleByMissingPenny.isEmpty()){
                calculateApplyExtendedForBundle(mapOfBundleByMissingPenny, quoteLinedata, mapQuoteData);
                System.debug('Bundle level MissingPenny');
            }
            //Missing penny for out year
            calculateMissingPennyForOutYearForBundle(mapQuoteData,quoteLinedata);
        }else{
            System.debug('Missing penny for Quote');
            calculateNegoPriceOnQuote(mapQuoteData);
            calculateSumOfTargetPriceMonthlyBIS(mapQuoteData,quoteLinedata);
            calculateMissingPennyOnQuote(mapQuoteData,quoteLinedata);
            calculateMissingPennyForOutYear(mapQuoteData,quoteLinedata); 
        }
    }
    
    /*
* - This method calculates Missing Penny for Out Years
* - YOY growth is applied on the first segment to calculate the expected values for next Out Years.
* - Expected Value is compared with the caluclated values of Out Year lines.
* - If they are not equal then it calculates the missing penny.
* - It applies the missing penny on the highest amount of the line.
*/
    public static void calculateMissingPennyForOutYearForBundle(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        String compositeKey = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');
        Decimal segmentCount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'SBQQ__SubscriptionTerm__c') / 12;
        segmentCount = compositeKey == 'United Kingdom' && mapQuoteData.get('Maximum_Number_Of_Segments__c') != null ? CoreCPQCalculationService.convertToDecimal(mapQuoteData,'Maximum_Number_Of_Segments__c') :segmentCount.round(System.RoundingMode.CEILING);
        Decimal yoyGrowth = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'YoY_Growth__c');
        Decimal firstSegTargetPriceMonthly = 0;
        Map<String ,Decimal>  mapOfSegmentWiseMissingPennyScaledValueForAmendments = new Map<String ,Decimal>();
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData, 'SBQQ__Type__c');
        String generatedFrom = CoreCPQCalculationService.convertToString(mapQuoteData, 'Generated_From__c');
        String pricingType = CoreCPQCalculationService.convertToString(mapQuoteData,'Price_Type__c');
        Boolean evaluateTargetFromPreviousPurchase = false;
        
        
        
        Map<Integer,Decimal> mapOfSegmentedUplift = new Map<Integer,Decimal>();
        Map<String,Decimal> mapOfSegmentedUpliftUK = new Map<String,Decimal>();
        Map<String, Decimal> mapOfFinalTargetPrice = new Map<String, Decimal>();
        Map<String, Decimal> mapOfTargetPriceByBundle = new Map<String, Decimal>();
        Map<String, Decimal> mapOfSegmentIndexAndProrateMultiplier = new Map<String, Decimal>();
        for(Map<String, Object> lineRecord : quoteLinedata){
            Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRecord, 'SBQQ__SegmentIndex__c');
            String bundleName = CoreCPQCalculationService.convertToString(lineRecord,'bundleName');
            String productName = CoreCPQCalculationService.convertToString(lineRecord,'SBQQ__ProductName__c');
            String key= bundleName != null ? bundleName+segmentIndex : productName+segmentIndex;
            Decimal prorateMultiplier = CoreCPQCalculationService.convertToDecimal(lineRecord, 'SBQQ__ProrateMultiplier__c');
            if(!mapOfSegmentIndexAndProrateMultiplier.containsKey(key)){
                mapOfSegmentIndexAndProrateMultiplier.put(key , prorateMultiplier);
            }
            
        }
        
        for(Map<String, Object> lineRecord : quoteLinedata){
            Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRecord, 'SBQQ__SegmentIndex__c');
            Decimal negotiatedPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRecord, 'Negotiated_Price_Monthly__c');
            Decimal distributorDiscount = CoreCPQCalculationService.convertToDecimal(lineRecord, 'SBQQ__DistributorDiscount__c');
            String bundleName = CoreCPQCalculationService.convertToString(lineRecord,'bundleName');
            String productName = CoreCPQCalculationService.convertToString(lineRecord,'SBQQ__ProductName__c');
            String key = bundleName != null ? bundleName : productName;
            Decimal suggestedRetailPrice = CoreCPQCalculationService.convertToDecimal(lineRecord, 'Suggested_Retail_Price_Monthly__c');
            Decimal prorateMultiplier = CoreCPQCalculationService.convertToDecimal(lineRecord, 'SBQQ__ProrateMultiplier__c');
            Decimal targetPriceMonthly = 0;
            Decimal targetPriceOverride = CoreCPQCalculationService.convertToDecimal(lineRecord, 'Target_Price_Override__c');
            System.debug('bundleNamee :: '+bundleName + ' :: segmentIndex :: '+segmentIndex + ' :: pricingType :: '+pricingType + ' :: prorateMultiplier :: '+prorateMultiplier + ' :: suggestedRetailPrice :: '+suggestedRetailPrice + ' :: targetPriceOverride :: '+targetPriceOverride);
            
            if(bundleName == null && segmentIndex <= 1 && pricingType == 'Annual' && prorateMultiplier != 0){
                targetPriceMonthly = suggestedRetailPrice != 0 ? suggestedRetailPrice / prorateMultiplier : 0;
                System.debug('@@@targetPriceMonthly '+targetPriceMonthly+' '+productName+' '+negotiatedPriceMonthly+' '+segmentIndex + ' :: suggestedRetailPrice :: '+suggestedRetailPrice + ' :: prorateMultiplier :: '+prorateMultiplier);
                if(targetPriceOverride != 0 || distributorDiscount != 0 ){
                    if(mapOfSegmentIndexAndProrateMultiplier.containsKey(key+1)){
                        Decimal firstSegmentProrate = mapOfSegmentIndexAndProrateMultiplier.get(key+1);
                        if(firstSegmentProrate != 0){
                            targetPriceOverride = targetPriceOverride / firstSegmentProrate;
                        }
                    }
                    negotiatedPriceMonthly = negotiatedPriceMonthly / prorateMultiplier; // to get annualized price
                    targetPriceMonthly = targetPriceOverride != 0 ? targetPriceOverride : negotiatedPriceMonthly - (negotiatedPriceMonthly * distributorDiscount / 100);
                }
                targetPriceMonthly = targetPriceMonthly.setScale(2, RoundingMode.HALF_UP);
                mapOfTargetPriceByBundle.put(key, targetPriceMonthly);
            }
            
        }
        System.debug('mapOfTargetPriceByBundle :: '+mapOfTargetPriceByBundle);
        for(Map<String, Object> lineRecord : quoteLinedata){
            Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRecord, 'SBQQ__SegmentIndex__c');
            Decimal negotiatedPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRecord, 'Negotiated_Price_Monthly__c');
            Decimal distributorDiscount = CoreCPQCalculationService.convertToDecimal(lineRecord, 'SBQQ__DistributorDiscount__c');
            Decimal uplift = CoreCPQCalculationService.convertToDecimal(lineRecord, 'SBQQ__Uplift__c');
            Decimal priorNetPrice = CoreCPQCalculationService.convertToDecimal(lineRecord, 'priorNetPrice');
            Decimal priorDistributorDiscount = CoreCPQCalculationService.convertToDecimal(lineRecord, 'priorDistributorDiscount');
            Double quantity = CoreCPQCalculationService.convertToDouble(lineRecord, 'SBQQ__Quantity__c');
            String bundleName = CoreCPQCalculationService.convertToString(lineRecord,'bundleName');
            String productName = CoreCPQCalculationService.convertToString(lineRecord,'SBQQ__ProductName__c');
            String key = bundleName != null ? bundleName : productName;
            String upliftKey=key+segmentIndex;
            Decimal bundleSRP = CoreCPQCalculationService.convertToDecimal(lineRecord, 'bundleSRP');
            Double bundleProrateMultiplier = CoreCPQCalculationService.convertToDouble(lineRecord ,'bundleProrateMultiplier');
            Decimal targetPriceMonthly = 0;
            Decimal targetPriceOverride = CoreCPQCalculationService.convertToDecimal(lineRecord, 'Target_Price_Override__c');
            
            Boolean isPriceFromBundleProduct = false;
            if(quoteType == CPQConstants.QUOTE_TYPE_AMENDMENT && negotiatedPriceMonthly < 0 && !mapQuoteData.containsKey(bundleName)){
                targetPriceMonthly = negotiatedPriceMonthly - (negotiatedPriceMonthly * priorDistributorDiscount/100);
            } else {
                targetPriceMonthly = negotiatedPriceMonthly - (negotiatedPriceMonthly * distributorDiscount/100);
            }
            System.debug('@@@TargetandNego'+' '+(negotiatedPriceMonthly - (negotiatedPriceMonthly * priorDistributorDiscount/100))+' '+(negotiatedPriceMonthly - (negotiatedPriceMonthly * distributorDiscount/100)) + ' '+productName);
            system.debug('bundleSRPPPP '+bundleSRP + 'productName '+productName + ' :: bundleName :: '+bundleName );
            mapOfSegmentedUplift.put(segmentIndex,uplift);
            mapOfSegmentedUpliftUK.put(upliftKey,uplift);
            if(segmentIndex == 1){
                if(mapOfTargetPriceByBundle.containsKey(key)){
                    targetPriceMonthly = mapOfTargetPriceByBundle.get(key);
                    isPriceFromBundleProduct = true;
                }
                firstSegTargetPriceMonthly += targetPriceMonthly;
                if(mapOfFinalTargetPrice.containsKey(key) && !isPriceFromBundleProduct){
                    mapOfFinalTargetPrice.put(key, mapOfFinalTargetPrice.get(key) + targetPriceMonthly);
                }else if(!mapOfFinalTargetPrice.containsKey(key)){
                    mapOfFinalTargetPrice.put(key, targetPriceMonthly);
                }
                System.debug('targetPriceMonthly '+targetPriceMonthly+' '+productName+' '+negotiatedPriceMonthly+' '+segmentIndex);
            }
            System.debug('mapOfFinalTargetPrice '+mapOfFinalTargetPrice);
            if(quoteType == CPQConstants.QUOTE_TYPE_AMENDMENT){
                key = key + segmentIndex;
                System.debug('mapQuoteData.containsKey(bundleName)'+mapQuoteData.get(bundleName)+' '+bundleName);
                Decimal computedVal = (quantity != 0)
                    ? targetPriceMonthly
                    : (quantity == 0)
                ? (-1 * priorNetPrice)
                    : targetPriceMonthly;
                
                System.debug('1234@@@ProductName'+targetPriceMonthly+' '+productName+' '+negotiatedPriceMonthly+' '+segmentIndex);
                evaluateTargetFromPreviousPurchase = true;
                if(!mapOfSegmentWiseMissingPennyScaledValueForAmendments.containsKey(key)){
                    mapOfSegmentWiseMissingPennyScaledValueForAmendments.put(key, computedVal);
                }else{
                    mapOfSegmentWiseMissingPennyScaledValueForAmendments.put(key, mapOfSegmentWiseMissingPennyScaledValueForAmendments.get(key) + computedVal);
                }
                if(mapOfFinalTargetPrice.containsKey(key)){
                    mapOfFinalTargetPrice.put(key, mapOfFinalTargetPrice.get(key) + computedVal);
                }else{
                    mapOfFinalTargetPrice.put(key, computedVal);
                }
            }
        }
        system.debug('firstSegTargetPriceMonthly :: '+firstSegTargetPriceMonthly + ' :: mapOfSegmentWiseMissingPennyScaledValueForAmendments :: ' + mapOfSegmentWiseMissingPennyScaledValueForAmendments + ' :: mapOfFinalTargetPrice :: ' + mapOfFinalTargetPrice);
        
        //Out year Started
        for (Integer i = 1; i <= segmentCount; i++) {
            if (i > 1) {
                Decimal finalTargetPrice = 0;
                Map<String, Decimal> mapOfFinalTargetPriceForSegment = new Map<String, Decimal>();
                Map<String, Decimal> mapOfMissingPennyByProducts = new Map<String, Decimal>();
                for(Map<String, Object> lineRecord : quoteLinedata){
                    String productName = CoreCPQCalculationService.convertToString(lineRecord, 'SBQQ__ProductName__c');
                    String bundleName = CoreCPQCalculationService.convertToString(lineRecord,'bundleName');
                    Decimal negotiatedPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRecord, 'Negotiated_Price_Monthly__c');
                    Decimal distributorDiscount = CoreCPQCalculationService.convertToDecimal(lineRecord, 'SBQQ__DistributorDiscount__c');
                    Decimal targetPriceMonthly = negotiatedPriceMonthly - (negotiatedPriceMonthly * distributorDiscount/100);  
                    Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRecord, 'SBQQ__SegmentIndex__c');
                    Double quantity = CoreCPQCalculationService.convertToDouble(lineRecord, 'SBQQ__Quantity__c');
                    Decimal prorateMultiplier = CoreCPQCalculationService.convertToDecimal(lineRecord, 'SBQQ__ProrateMultiplier__c');
                    String key = bundleName != null ? bundleName : productName;
                    
                    system.debug('segmentIndex$$' + segmentIndex + 'targetPriceMonthly$$' + targetPriceMonthly + 'ProductName$$' + productName);
                    if (segmentIndex == i && targetPriceMonthly != 0) {
                        CoreCPQCalculationService.calculateSumOfAdditionalDiscounts(mapQuoteData, lineRecord);
                        
                        Decimal negotiatedDiscAmount = CoreCPQCalculationService.convertToDecimal(lineRecord, 'negotiatedDiscAmount');
                        Decimal computedVal = targetPriceMonthly - negotiatedDiscAmount;
                        Decimal rounded  = computedVal.setScale(2,RoundingMode.HALF_UP);
                        if(compositeKey == 'United Kingdom')
                        {lineRecord.put('Extended_Net_Monthly__c', rounded);}
                        system.debug('segmentIndex$$' + segmentIndex + 'targetPriceMonthly$$' + targetPriceMonthly + 'ProductName$$' + productName + 'negotiated disc amt '+ negotiatedDiscAmount);
                        system.debug('computedVal$$' + computedVal);
                        system.debug('rounded$$ ' + rounded+' '+productName+' '+targetPriceMonthly);
                        finalTargetPrice =  finalTargetPrice + rounded;
                        system.debug('finalTargetPrice$$' + finalTargetPrice);
                        if(mapOfFinalTargetPriceForSegment.containsKey(key)){
                            mapOfFinalTargetPriceForSegment.put(key, mapOfFinalTargetPriceForSegment.get(key) + rounded);
                        } else {
                            mapOfFinalTargetPriceForSegment.put(key, rounded);
                        }
                    }
                    
                }
                
                system.debug('mapOfFinalTargetPriceForSegment:: ' + mapOfFinalTargetPriceForSegment + ' :: mapOfFinalTargetPrice :: ' + mapOfFinalTargetPrice);
                // Missing penny calculation for each bundle
                // Call extended quote method per bundle
                if(compositeKey == 'United Kingdom') {
                    for (String segmentKey : mapOfFinalTargetPriceForSegment.keySet()) {
                        Decimal bundleTarget = mapOfFinalTargetPriceForSegment.get(segmentKey);
                        String segmentKeyWithIndex = segmentKey + i;
                        System.debug('segmentKeyWithIndex'+ segmentKeyWithIndex+' '+mapOfSegmentIndexAndProrateMultiplier);
                        
                        // Missing penny calculation for this bundle
                        Decimal expectedBundleValue = 0;
                        Decimal bundleValue = 0;
                        if(mapOfFinalTargetPrice.containsKey(segmentKey)){
                            bundleValue = mapOfFinalTargetPrice.get(segmentKey);
                            System.debug('@@@bundleValue before prorate'+ bundleValue+' '+segmentKey+' '+segmentKey);
                            // Case of Leap year where second segment prorate multiplier is decimal instead of 1
                            if(mapOfSegmentIndexAndProrateMultiplier.containsKey(segmentKeyWithIndex)){
                                bundleValue = bundleValue * mapOfSegmentIndexAndProrateMultiplier.get(segmentKeyWithIndex);
                            }
                        }

                        System.debug('@@@bundleValue after'+bundleValue+' '+bundleTarget+' '+segmentKey);
                        System.debug(' mapOfSegmentedUplift'+ mapOfSegmentedUplift);
                        Decimal previousSegmentUplift1 = mapOfSegmentedUpliftUK.containsKey(segmentKeyWithIndex) ? mapOfSegmentedUpliftUK.get(segmentKeyWithIndex) : 0;
                        System.debug('previousSegmentUplift1'+previousSegmentUplift1);
                        Decimal upliftedTargetPrice1 =  bundleValue * previousSegmentUplift1 / 100;

                        System.debug('upliftedTargetPrice1 '+upliftedTargetPrice1);
                        
                        if (evaluateTargetFromPreviousPurchase && mapOfSegmentWiseMissingPennyScaledValueForAmendments.containsKey(segmentKeyWithIndex)) {
                            expectedBundleValue = mapOfSegmentWiseMissingPennyScaledValueForAmendments.get(segmentKeyWithIndex);
                        } else {
                            expectedBundleValue = (upliftedTargetPrice1 + bundleValue).setScale(2, RoundingMode.HALF_UP);
                        }
                        System.debug('expectedBundleValue'+expectedBundleValue+' '+bundleTarget+' '+bundleTarget);
                        Decimal missingPenny1 = expectedBundleValue - bundleTarget;
                        missingPenny1 = missingPenny1.setScale(2, RoundingMode.HALF_UP);
                        
                        if(missingPenny1 != 0){
                            mapOfMissingPennyByProducts.put(segmentKey, missingPenny1);
                        }
                        
                        system.debug('Missing Penny Bundle: ' + segmentKey + ' | bundleTarget: ' + bundleTarget + ' | expected: ' + expectedBundleValue + ' | missingPenny: ' + mapOfMissingPennyByProducts + '  mapOfFinalTargetPrice: ' + mapOfFinalTargetPrice);
                        
                        bundleValue = (bundleValue + (bundleValue * (previousSegmentUplift1 / 100)));
                        bundleValue = bundleValue.setScale(2,RoundingMode.HALF_UP);
                        if(mapOfFinalTargetPrice.containsKey(segmentKey) && quoteType != CPQConstants.QUOTE_TYPE_AMENDMENT){
                            if(mapOfSegmentIndexAndProrateMultiplier.containsKey(segmentKeyWithIndex)){
                                bundleValue = bundleValue / mapOfSegmentIndexAndProrateMultiplier.get(segmentKeyWithIndex);
                            }
                            mapOfFinalTargetPrice.put(segmentKey, bundleValue.setScale(2,RoundingMode.HALF_UP));
                        }
                    }
                    // This is for UK only to adjust the penny bundle wise. Other BU can utilize this logic if required.
                    CPQUKCalculationHelper.applyExtendedOnQuoteForBundle(i, mapQuoteData, quoteLinedata, mapOfMissingPennyByProducts,'CPQBISCalculationHelper');
                } else {
                    system.debug('finalTargetPrice$$$' + finalTargetPrice);
                    system.debug('yoyGrowth11---' + yoyGrowth);
                    system.debug('Segment Uplift --- '+mapOfSegmentedUplift.get(i));
                    Decimal previousSegmentUplift = mapOfSegmentedUplift.containsKey(i) ? mapOfSegmentedUplift.get(i) : 0;
                    System.debug('previousSegmentUplift'+previousSegmentUplift);
                    Decimal upliftedTargetPrice =  firstSegTargetPriceMonthly * previousSegmentUplift / 100;
                    
                    upliftedTargetPrice = upliftedTargetPrice.setScale(2,RoundingMode.HALF_UP);
                     System.debug('upliftedTargetPrice'+upliftedTargetPrice);
                    System.debug('firstSegTargetPriceMonthly'+firstSegTargetPriceMonthly);
                    Decimal missingPennyScaledValue = 0;
                    missingPennyScaledValue = (upliftedTargetPrice + firstSegTargetPriceMonthly).setScale(2,RoundingMode.HALF_UP);
                    system.debug('missingPennyScaledValue--' + missingPennyScaledValue);
                    Decimal missingPenny = missingPennyScaledValue - finalTargetPrice;
                    missingPenny = missingPenny.setScale(2,RoundingMode.HALF_UP);
                    system.debug('missingPenny$$' + missingPenny);
                    
                    //Calling applyExtended Method to adjust the penny in highest amount
                    applyExtendedOnQuote(i, mapQuoteData, quoteLinedata, missingPenny);
                    
                    system.debug('firstSegTargetPriceMonthly ' + firstSegTargetPriceMonthly);
                    firstSegTargetPriceMonthly = (firstSegTargetPriceMonthly + (firstSegTargetPriceMonthly * (previousSegmentUplift / 100)));
                    system.debug('Uplifted firstSegTargetPriceMonthly' + firstSegTargetPriceMonthly);
                    firstSegTargetPriceMonthly = firstSegTargetPriceMonthly.setScale(2,RoundingMode.HALF_UP);
                    system.debug('rounded firstSegTargetPriceMonthly' + firstSegTargetPriceMonthly);
                    
                } 
                
            }
        }
    }
    
    /*
* - This method calculates the NegotiatedPrice On Quote
* - This method is being called from Missing Penny is handled in case when target is not override on bundle
*/
    
    
    public static void calculateNegoPriceOnQuote(Map<String, Object> mapQuoteData){
        Decimal firstSegmentListAmount = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'First_Segment_List_Amount2__c');
        Decimal firstSegmentFreeProductList = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'FirstSegment_Free_Product_List__c');
        Decimal totalDiscountOnQuote = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'Discretionary_Discount__c') + CoreCPQCalculationService.convertToDecimal(mapQuoteData,'Multi_Year_Term_Discount__c');
        Decimal negotiatedPriceQuote =  (firstSegmentListAmount - ((firstSegmentListAmount - firstSegmentFreeProductList) * totalDiscountOnQuote / 100) - firstSegmentFreeProductList);
        Decimal roundedNegopriceQuote = negotiatedPriceQuote.setScale(2,RoundingMode.HALF_UP);
        mapQuoteData.put('negotiatedPriceQuote', roundedNegopriceQuote);
        
    }
    
    /*
* - This method calculates the sum of Net Monthly for missing penny
* - Net Monthly is calculated by subtracting the negotiated discount amount from the target price monthly
*/
    
    public static void calculateSumOfTargetPriceMonthlyBIS(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        Decimal sumOfNetMonthly=0;
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData,'SBQQ__Type__c');
        String compositeKey = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');
        for(Map<String, Object> lineRecord : quoteLinedata) {
            Decimal targetPrice = CoreCPQCalculationService.convertToDecimal(lineRecord,'Target_Price_Monthly__c');
            Decimal negoDiscAmount = CoreCPQCalculationService.convertToDecimal(lineRecord,'Negotiated_Disc_Amt__c');
            Decimal netMonthly = CoreCPQCalculationService.convertToDecimal(lineRecord,'Net_Monthly__c');
            Integer segment = CoreCPQCalculationService.convertToInteger(lineRecord, 'SBQQ__SegmentIndex__c');
            Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRecord ,'SBQQ__NonDiscountable__c');
            String generatedFrom = CoreCPQCalculationService.convertToString(mapQuoteData,'Generated_From__c');
            System.debug('generatedFrom'+generatedFrom);
            if((generatedFrom == 'AAR') || (segment == 1 && !nonDiscountable)){
                System.debug('Enter into this block');
                targetPrice = targetPrice - negoDiscAmount;
                targetPrice = targetPrice.setScale(2,RoundingMode.HALF_UP);
                sumOfNetMonthly += targetPrice;
            }
        }
        sumOfNetMonthly = sumOfNetMonthly.setScale(2,RoundingMode.HALF_UP);
        mapQuoteData.put('sumOfNetMonthly', sumOfNetMonthly);
    }
    
    /*
* - This method calculates the Missing penny on the Quote 
* - This method is being called from calculateMissingPenny method
* - applyExtendedOnQuote method is being called to adjust the penny in highest amount
* - It Calculate penny in case when Target Override or DD is not applied on bundle level.
*/
    
    public static void calculateMissingPennyOnQuote(Map<String, Object> mapQuoteData,List<Map<String, Object>> quoteLinedata){
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData,'SBQQ__Type__c');
        String generatedFrom = CoreCPQCalculationService.convertToString(mapQuoteData,'Generated_From__c');
        String compositeKey = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');
        Decimal negotiatedPriceQuote = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'negotiatedPriceQuote');
        Decimal Negotiated_Price_Target = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'Negotiated_Price_Target__c');
        Decimal Discretionary_Discount = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'Discretionary_Discount__c');
        Boolean isTargetPriceOverriden = CoreCPQCalculationService.convertToBoolean(mapQuoteData,'Is_Target_Price_Overridden__c');
        Boolean isTargetPriceOrDDApplied = CoreCPQCalculationService.convertToBoolean(mapQuoteData,'isTargetPriceOrDDApplied');
        String bridgeProgram = CoreCPQCalculationService.convertToString(mapQuoteData, 'Bridge_ProgramF__c');
        Date westBridgeEndDate = CoreCPQCalculationService.convertToDate(mapQuoteData,'WestBridge_Bridge_End_Date__c');
        Decimal missingPenny = 0;
        Decimal quoteFinalTargetPrice = 0;
        Decimal quoteFinalNetPrice = 0;
        Decimal distributerDiscountAmount = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'negoDiscAmtQuote');
        Decimal bridgeDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData ,'Program_Discount__c');
        System.debug('bridgeDiscount'+bridgeDiscount);
        system.debug('negotiatedPriceQuote## ' + negotiatedPriceQuote);
        Decimal sumOfNetMonthly = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'sumOfNetMonthly');
        system.debug('sumOfNetMonthly--' + sumOfNetMonthly);
        quoteFinalTargetPrice = (negotiatedPriceQuote - distributerDiscountAmount);
        System.debug('quoteFinalTargetPrice'+quoteFinalTargetPrice);
        // calculate the quoteFinalNetPrice in case of Bridge Discount for Corp Legal
         if(compositeKey == 'Corp Legal' && bridgeDiscount != 0 && westBridgeEndDate != null){
            quoteFinalNetPrice = (quoteFinalTargetPrice * bridgeDiscount) / 100;
            System.debug('quoteFinalNetPrice'+quoteFinalNetPrice);
            quoteFinalTargetPrice = quoteFinalTargetPrice - quoteFinalNetPrice;
            quoteFinalTargetPrice = quoteFinalTargetPrice.setScale(2,RoundingMode.HALF_UP);
            System.debug('quoteFinalTargetPrice----'+quoteFinalTargetPrice);
        } 
        System.debug('missingPenny'+missingPenny);
        missingPenny = quoteFinalTargetPrice - sumOfNetMonthly;
        System.debug('missingPenny'+missingPenny);
        
        if(quoteType == 'Renewal' && generatedFrom == 'Fixed Term Extension'){
            Decimal lastSegmentNegotiatedPrice = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'Negotiated_Price_from_Previous_Quote__c');
            system.debug('lastSegmentNegotiatedPrice '+lastSegmentNegotiatedPrice);
            system.debug('sumOfNetMonthly '+sumOfNetMonthly);
            missingPenny = lastSegmentNegotiatedPrice - sumOfNetMonthly;
        }else if(generatedFrom == 'AAR'){
            CoreCPQCalculationService.calculateUpliftPrevQuoteNegotiatedPrice(mapQuoteData);
            Decimal upliftPrevQuoteNegotiatedPrice = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'upliftPrevQuoteNegotiatedPrice');
            system.debug('upliftPrevQuoteNegotiatedPrice '+ upliftPrevQuoteNegotiatedPrice);
            system.debug('sumOfNetMonthly -'+sumOfNetMonthly);
            missingPenny = upliftPrevQuoteNegotiatedPrice - sumOfNetMonthly;
        }
        else if((compositeKey == 'BIS' || compositeKey == 'RTIS') && generatedFrom == 'Renewal'&& isTargetPriceOrDDApplied== false && isTargetPriceOverriden == false && (Discretionary_Discount == null || Discretionary_Discount ==0) && (Negotiated_Price_Target == null || Negotiated_Price_Target == 0) ){
            CoreCPQCalculationService.calculateUpliftPrevQuoteNegotiatedPrice(mapQuoteData);
            Decimal upliftPrevQuoteNegotiatedPrice = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'upliftPrevQuoteNegotiatedPrice');
            system.debug('upliftPrevQuoteNegotiatedPrice '+ upliftPrevQuoteNegotiatedPrice);
            system.debug('sumOfNetMonthly -'+sumOfNetMonthly);
            missingPenny =0;
        }
        system.debug('missingPenny- ' + missingPenny);
        mapQuoteData.put('missingPenny', missingPenny);
        applyExtendedOnQuote(1, mapQuoteData, quoteLinedata, missingPenny);
    }
    
    /*
* - This method calculates Missing Penny for Out Years
* - YOY growth is applied on the first segment to calculate the expected values for next Out Years.
* - Expected Value is compared with the caluclated values of Out Year lines.
* - If they are not equal then it calculates the missing penny.
* - It applies the missing penny on the highest amount of the line.
*/
    public static void calculateMissingPennyForOutYear(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        Integer termY;
        Decimal firstSegmentListAmount2 = 0;
        String pricingType = CoreCPQCalculationService.convertToString(mapQuoteData,'Price_Type__c');
        for(Map<String, Object> lineRec: quoteLinedata){
            Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRec,'SBQQ__SegmentIndex__c');
            Boolean isBundleProduct = CoreCPQCalculationService.convertToBoolean(lineRec,'SBQQ__Bundle__c');
            Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRec ,'SBQQ__NonDiscountable__c');
            if(segmentIndex == 1 && !isBundleProduct && !nonDiscountable){
                Decimal negotiatedPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRec, 'Negotiated_Price_Monthly__c');
                Decimal prorateMultiplier = CoreCPQCalculationService.convertToDecimal(lineRec, 'SBQQ__ProrateMultiplier__c');
                
                if(pricingType == 'Annual' && prorateMultiplier > 0){
                    negotiatedPriceMonthly = negotiatedPriceMonthly / prorateMultiplier;
                    System.debug('negotiatedPriceMonthly '+negotiatedPriceMonthly.setScale(2,RoundingMode.HALF_UP));
                }

                firstSegmentListAmount2 += negotiatedPriceMonthly.setScale(2,RoundingMode.HALF_UP);
            }
        }
        Decimal firstSegmentFreeProductList = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'FirstSegment_Free_Product_List__c');
        Decimal segmentCount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'SBQQ__SubscriptionTerm__c') / 12;
        segmentCount = segmentCount.round(System.RoundingMode.CEILING);
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
        Decimal  dis  = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'Discretionary_Discount__c') + CoreCPQCalculationService.convertToDecimal(mapQuoteData,'Multi_Year_Term_Discount__c');
        Decimal totalDisc = ((firstSegmentListAmount2 - firstSegmentFreeProductList) * dis) / 100;
        system.debug('totalDisc'+totalDisc);
        Decimal np = ((firstSegmentListAmount2 - totalDisc) - firstSegmentFreeProductList);
        np = np.setScale(2,RoundingMode.HALF_UP);
        system.debug('np$$$' + np);
        system.debug('segmentCount--' + segmentCount);
        Map<Integer, Decimal> mapOfUpliftBySegmentIndex = new Map<Integer, Decimal>();
        for (Integer i = 1; i <= segmentCount; i++) {
            if (i > termY) {
                Decimal calNp = 0;
                for(Map<String, Object> lineRecord : quoteLinedata){
                    Decimal negoPriceMonth = CoreCPQCalculationService.convertToDecimal(lineRecord, 'negoPriceMonth');
                    Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRecord, 'SBQQ__SegmentIndex__c');
                    Decimal uplift = CoreCPQCalculationService.convertToDecimal(lineRecord, 'SBQQ__Uplift__c');
                    mapOfUpliftBySegmentIndex.put(segmentIndex, uplift);
                    System.debug('segmentIndex'+segmentIndex);
                    Decimal targetPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRecord,'Target_Price_Monthly__c');
                    Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRecord ,'SBQQ__NonDiscountable__c');
                    system.debug('segmentIndex$$' + segmentIndex);
                    system.debug('targetPriceMonthly$$' + targetPriceMonthly);
                    system.debug('calnpUp$$' + calnp + ' ' + CoreCPQCalculationService.convertToString(lineRecord,'SBQQ__ProductName__c')+ ' ' + segmentIndex + ' ' + targetPriceMonthly);

                    if (segmentIndex == i && targetPriceMonthly != 0) {
                        system.debug('targetPriceMonthly$$--' + targetPriceMonthly);
                        system.debug('negotiatedDiscAmount$$' + negotiatedDiscAmount);
                        Decimal computedVal = targetPriceMonthly - negotiatedDiscAmount;
                        Decimal rounded  = computedVal.setScale(2,RoundingMode.HALF_UP);
                        system.debug('computedVal$$' + computedVal);
                        system.debug('rounded$$' + rounded);
                        calnp =  calnp + rounded;
                        system.debug('calnp$$' + calnp);
                    }
                }
                Decimal previousSegmentIndexUplift = mapOfUpliftBySegmentIndex.containsKey(i) ? mapOfUpliftBySegmentIndex.get(i) : 0;
                system.debug('calnp$$$' + calnp);
                system.debug('np111' + np);
                system.debug('uplift---' + previousSegmentIndexUplift);
                Decimal divededYearGrowth = previousSegmentIndexUplift / 100;
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
                applyExtendedOnQuote(i,mapQuoteData,quoteLinedata,missingPenny);
                system.debug('np333' + np);
                np = (np + (np * (previousSegmentIndexUplift / 100)));
                system.debug('np222' + np);
                np = np.setScale(2,RoundingMode.HALF_UP);
                system.debug('np444' + np);
            }
        }
    }
    
    /*
* - This method used to populate the Extended Net Monthly on the Quote line 
* - called from Missing Penny Methods according to the Segments FOR BIS
* - This Method adjust the Missing penny in quote line with highest amount 
*/
    public static void applyExtendedOnQuote(Integer segment, Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata , Decimal missingPenny){
        System.debug('missingP in ApplyExtended'+missingPenny);
        System.debug('segment In'+ segment);
        if (missingPenny != null) {
            Boolean added = false;
            Decimal highestAmount = 0;   
            String generatedFrom = CoreCPQCalculationService.convertToString(mapQuoteData ,'Generated_From__c');
            String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData, 'SBQQ__Type__c');
            String compositeKey = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');
            Boolean isTargetPriceOverriden = CoreCPQCalculationService.convertToBoolean(mapQuoteData,'Is_Target_Price_Overridden__c');
            Boolean isTargetPriceOrDDApplied = CoreCPQCalculationService.convertToBoolean(mapQuoteData,'isTargetPriceOrDDApplied');
            Decimal Negotiated_Price_Target = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'Negotiated_Price_Target__c');
            Decimal Discretionary_Discount = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'Discretionary_Discount__c');
            String bridgeProgram = CoreCPQCalculationService.convertToString(mapQuoteData, 'Bridge_ProgramF__c');
            Date westBridgeEndDate = CoreCPQCalculationService.convertToDate(mapQuoteData,'WestBridge_Bridge_End_Date__c');
            Decimal bridgeDiscount = CoreCPQCalculationService.convertToDecimal(mapQuoteData ,'Program_Discount__c');
            for(Map<String, Object> lineRec : quoteLinedata) {
                Decimal negotiatedPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRec ,'negoPriceMonth');
                Decimal negoDiscAmount = CoreCPQCalculationService.convertToDecimal(lineRec,'Negotiated_Disc_Amt__c');
                Decimal targetPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRec, 'Target_Price_Monthly__c');
                system.debug('negotiatedPriceMonthly--' + negotiatedPriceMonthly);
                Double segmentIndex = CoreCPQCalculationService.convertToInteger(lineRec, 'SBQQ__SegmentIndex__c');
                if(segmentIndex == segment){
                    system.debug('segmentIndex--' + segmentIndex);
                    lineRec.put('targetPriceMonthly', targetPriceMonthly);
                    system.debug('targetPriceMonthly -- ' + targetPriceMonthly);
                    if(highestAmount < targetPriceMonthly && quoteType != CPQConstants.QUOTE_TYPE_AMENDMENT){
                        highestAmount = targetPriceMonthly;
                        System.debug('highestAmount----:: '+ highestAmount);
                    } 
                    else if(quoteType == CPQConstants.QUOTE_TYPE_AMENDMENT){
                        Decimal highestAmountAbs = Math.abs(highestAmount);
                        Decimal targetPriceMonthlyAbs = Math.abs(targetPriceMonthly);
                        if(highestAmountAbs < targetPriceMonthlyAbs){
                            highestAmount = targetPriceMonthly;
                            System.debug('highestAmount----:::'+ highestAmount);
                        }
                        
                    }
                }
            }
            for (Map<String, Object> lineRec : quoteLinedata) {
                Decimal negotiatedDiscAmount;
                Decimal negoPriceMonth = CoreCPQCalculationService.convertToDecimal(lineRec, 'negoPriceMonth');
                Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRec ,'SBQQ__NonDiscountable__c');
                Double  segmentIndex = CoreCPQCalculationService.convertToDouble(lineRec, 'SBQQ__SegmentIndex__c');
                Decimal additionalDiscAmount = CoreCPQCalculationService.convertToDecimal(lineRec ,'SBQQ__AdditionalDiscountAmount__c');
                Double effectiveQuantity = CoreCPQCalculationService.convertToDouble(lineRec ,'SBQQ__EffectiveQuantity__c');
                Double prorateMultiplier = CoreCPQCalculationService.convertToDouble(lineRec ,'SBQQ__ProrateMultiplier__c');
                Decimal targetPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRec ,'Target_Price_Monthly__c');
                Decimal negoDiscAmt = CoreCPQCalculationService.convertToDecimal(lineRec ,'Negotiated_Disc_Amt__c');
                Decimal discount = CoreCPQCalculationService.convertToDecimal(lineRec ,'SBQQ__Discount__c');
                Decimal netMonthly = CoreCPQCalculationService.convertToDecimal(lineRec ,'Net_Monthly__c');
                
                Decimal Target_Price_Override = CoreCPQCalculationService.convertToDecimal(lineRec,'Target_Price_Override__c');
                
                Decimal finalTargetPrice = targetPriceMonthly - negoDiscAmt;
                finalTargetPrice = finalTargetPrice.setScale(2,RoundingMode.HALF_UP);
                system.debug('discount--' + discount);
                if(segmentIndex == segment && targetPriceMonthly != 0 && targetPriceMonthly != 0 && missingPenny != 0){
                    if (!nonDiscountable && (generatedFrom == 'AAR' || generatedFrom == 'Fixed Term Extension') && prorateMultiplier > 0){
                        negotiatedDiscAmount = (additionalDiscAmount * effectiveQuantity) / prorateMultiplier;
                        negotiatedDiscAmount = negotiatedDiscAmount.setScale(2,RoundingMode.HALF_UP);
                    }else if(!nonDiscountable){
                        negotiatedDiscAmount = (targetPriceMonthly * discount) / 100;
                        negotiatedDiscAmount = negotiatedDiscAmount.setScale(2,RoundingMode.HALF_UP);
                    }else{
                        negotiatedDiscAmount = 0; 
                    }
                    system.debug('SBQQ__ProductCode__c--' + CoreCPQCalculationService.convertToString(lineRec ,'SBQQ__ProductCode__c'));
                    system.debug('targetPriceMonthly--' + targetPriceMonthly);
                    system.debug('negotiatedDiscAmount--' + negotiatedDiscAmount);
                    Decimal computedVal = targetPriceMonthly - negotiatedDiscAmount;
                    system.debug('computedVal'+computedVal);
                    Decimal rounded  = computedVal.setScale(2,RoundingMode.HALF_UP);
                    system.debug('Testrounded123-- ' + rounded);
                    system.debug('highestAmount$$' + highestAmount);
                    
                    if(netMonthly != 0 && !added && highestAmount == targetPriceMonthly){
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
                    system.debug('Entered with 0 Penny ');
                    
                    lineRec.put('Extended_Net_Monthly__c', finalTargetPrice);
                    
                } 
                
                if((compositeKey == 'BIS' || compositeKey == 'RTIS' || compositeKey == 'Corp Legal') && generatedFrom == 'Renewal'&& isTargetPriceOrDDApplied==false && isTargetPriceOverriden == false && (Target_Price_Override ==null || Target_Price_Override ==0)  && (Discretionary_Discount == null || Discretionary_Discount ==0) && (Negotiated_Price_Target == null || Negotiated_Price_Target == 0) ){
                    lineRec.put('Extended_Net_Monthly__c', 0);
                    
                }
            }
        }
    } 
    
    /*
* - This Method Calculates the Negotiated Price for the Bundle and calculates the discounted negotiated price for the segment 1
*/   
    public static void calculateNegoPriceOnBundle(Map<String, Object> mapQuoteData,List<Map<String, Object>> quoteLinedata,Map<String, Decimal>mapOfBundleByMissingPenny){
        Map<String, Decimal> mapOfFirstSegmentListAmountPerBundle = new Map<String, Decimal>();
        for (Map<String, Object> lineRec : quoteLinedata) {
            String productCode = CoreCPQCalculationService.convertToString(lineRec, 'SBQQ__ProductCode__c');
            Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRec, 'SBQQ__SegmentIndex__c');
            String requiredByProdCode = CoreCPQCalculationService.convertToString(lineRec, 'bundleCode');
            Boolean isBundleProduct = CoreCPQCalculationService.convertToBoolean(lineRec,'SBQQ__Bundle__c');
            String ProductSubscriptionType = CoreCPQCalculationService.convertToString(lineRec,'SBQQ__ProductSubscriptionType__c');
            Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRec ,'SBQQ__NonDiscountable__c');
            if (segmentIndex <= 1 && !isBundleProduct && ProductSubscriptionType !='One-time' && ProductSubscriptionType != null && !nonDiscountable) {
                Decimal negotiatedPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRec, 'Negotiated_Price_Monthly__c');
                if(requiredByProdCode != null){
                    if (!mapOfFirstSegmentListAmountPerBundle.containsKey(requiredByProdCode)) {
                        mapOfFirstSegmentListAmountPerBundle.put(requiredByProdCode, negotiatedPriceMonthly);
                    } else {
                        mapOfFirstSegmentListAmountPerBundle.put(requiredByProdCode, mapOfFirstSegmentListAmountPerBundle.get(requiredByProdCode) + negotiatedPriceMonthly);
                    }
                    
                }else{
                    if (!mapOfFirstSegmentListAmountPerBundle.containsKey(productCode)) {
                        mapOfFirstSegmentListAmountPerBundle.put(productCode, negotiatedPriceMonthly);
                    } else {
                        mapOfFirstSegmentListAmountPerBundle.put(productCode, mapOfFirstSegmentListAmountPerBundle.get(productCode) + negotiatedPriceMonthly);
                    }
                    
                }
                
            }
        }
        
        System.debug('mapOfFirstSegmentListAmountPerBundle: ' + mapOfFirstSegmentListAmountPerBundle);
        
        for(Map<String, Object> lineRecord : quoteLinedata){
            String requiredByProductCode = CoreCPQCalculationService.convertToString(lineRecord,'bundleCode');
            String productCode = CoreCPQCalculationService.convertToString(lineRecord, 'SBQQ__ProductCode__c');
            Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRecord,'SBQQ__SegmentIndex__c');
            Boolean isBundleLine = CoreCPQCalculationService.convertToBoolean(lineRecord, 'SBQQ__Bundle__c');
            Decimal negotiatedPrice = CoreCPQCalculationService.convertToDecimal(lineRecord, 'Negotiated_Price_Monthly__c');
            Decimal firstSegmentFreeProductList = CoreCPQCalculationService.convertToDecimal(mapQuoteData,'FirstSegment_Free_Product_List__c');
            Decimal firstSegmentListAmount = 0;
            String ProductSubscriptionType = CoreCPQCalculationService.convertToString(lineRecord,'SBQQ__ProductSubscriptionType__c');
            Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRecord ,'SBQQ__NonDiscountable__c');
            if(!nonDiscountable){
                if (requiredByProductCode != null) {
                    if(segmentIndex <= 1 && ProductSubscriptionType !='One-time' && ProductSubscriptionType != null){
                        if(mapOfFirstSegmentListAmountPerBundle.containsKey(requiredByProductCode)){
                            firstSegmentListAmount = mapOfFirstSegmentListAmountPerBundle.get(requiredByProductCode);
                            
                        }
                        Decimal DistributorDiscount = CoreCPQCalculationService.convertToDecimal(lineRecord,'SBQQ__DistributorDiscount__c');
                        Decimal discountedNegotiatedPrice = (firstSegmentListAmount - ((firstSegmentListAmount - firstSegmentFreeProductList) * DistributorDiscount / 100) - firstSegmentFreeProductList);
                        discountedNegotiatedPrice =discountedNegotiatedPrice.setScale(2, RoundingMode.HALF_UP);
                        if (!mapOfBundleByMissingPenny.containskey(requiredByProductCode)) {    
                            system.debug('requiredByProductCode'+requiredByProductCode);
                            mapOfBundleByMissingPenny.put(requiredByProductCode, discountedNegotiatedPrice);
                        }
                    }
                } else{
                    if(segmentIndex <= 1 && !isBundleLine  && ProductSubscriptionType !='One-time' && ProductSubscriptionType != null){
                        if(mapOfFirstSegmentListAmountPerBundle.containsKey(productCode)) {
                            firstSegmentListAmount = mapOfFirstSegmentListAmountPerBundle.get(productCode);
                        }
                        Decimal DistributorDiscount = CoreCPQCalculationService.convertToDecimal(lineRecord,'SBQQ__DistributorDiscount__c');
                        Decimal discountedNegotiatedPrice = (firstSegmentListAmount - ((firstSegmentListAmount - firstSegmentFreeProductList) * DistributorDiscount / 100) - firstSegmentFreeProductList);
                        discountedNegotiatedPrice =discountedNegotiatedPrice.setScale(2, RoundingMode.HALF_UP);
                        if (!mapOfBundleByMissingPenny.containskey(productCode)) {  
                            system.debug('requiredByProductCode of single line'+productCode);
                            mapOfBundleByMissingPenny.put(productCode, discountedNegotiatedPrice);
                        }
                    }
                }
            }
            System.debug('mapOfBundleByMissingPennyone'+mapOfBundleByMissingPenny);
        }
        System.debug('mapOfBundleByMissingPennyone---'+ mapOfBundleByMissingPenny);
    }
    
    /*
* - This method aggregates the target price for bundle products present in the quote line
*/   
    public static void calculateTargetPriceOnBundle(Map<String, Object> mapQuoteData,List<Map<String, Object>> quoteLinedata,Map<String, Decimal>mapOfBundleByMissingPenny){
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData,'SBQQ__Type__c');
        for(Map<String, Object> lineRecord : quoteLinedata){
            String requiredByProductCode = CoreCPQCalculationService.convertToString(lineRecord,'bundleCode');
            Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRecord,'SBQQ__SegmentIndex__c');
            Decimal targetPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRecord, 'Target_Price_Monthly__c');
            String ProductSubscriptionType = CoreCPQCalculationService.convertToString(lineRecord,'SBQQ__ProductSubscriptionType__c');
            Boolean isBundleProduct = CoreCPQCalculationService.convertToBoolean(lineRecord,'SBQQ__Bundle__c');
            String productCode = CoreCPQCalculationService.convertToString(lineRecord, 'SBQQ__ProductCode__c');
            Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRecord ,'SBQQ__NonDiscountable__c');
            Decimal priorNetPrice = CoreCPQCalculationService.convertToDecimal(lineRecord, 'priorNetPrice');
            Decimal quantity = CoreCPQCalculationService.convertToDecimal(lineRecord, 'SBQQ__Quantity__c');
            Decimal prorateMultiplier = CoreCPQCalculationService.convertToDecimal(lineRecord, 'SBQQ__ProrateMultiplier__c');
            Decimal priorProrateMultiplier = CoreCPQCalculationService.convertToDecimal(lineRecord, 'priorProrateMultiplier');
            targetPriceMonthly = targetPriceMonthly.setScale(2, RoundingMode.HALF_UP);
            if(segmentIndex <= 1 && ProductSubscriptionType != 'One-time' && ProductSubscriptionType !=null && !isBundleProduct && !nonDiscountable){
                if(quoteType == CPQConstants.QUOTE_TYPE_AMENDMENT && quantity == 0 && priorNetPrice != null){
                    //targetPriceMonthly = -1 * priorNetPrice;
                    if(prorateMultiplier!= 0 && priorProrateMultiplier != 0){
                        //targetPriceMonthly = (targetPriceMonthly / priorProrateMultiplier ) * prorateMultiplier;
                    }
                }
                if (requiredByProductCode != null) {
                    if (!mapOfBundleByMissingPenny.containskey(requiredByProductCode)) {
                        mapOfBundleByMissingPenny.put(requiredByProductCode, targetPriceMonthly);
                    }else if(!isBundleProduct){
                        Decimal requiredBySum = mapOfBundleByMissingPenny.get(requiredByProductCode).setScale(2, RoundingMode.HALF_UP)  + targetPriceMonthly;
                        mapOfBundleByMissingPenny.put(requiredByProductCode, requiredBySum);
                    }
                } else {
                    if (!mapOfBundleByMissingPenny.containsKey(productCode)) {
                        mapOfBundleByMissingPenny.put(productCode, targetPriceMonthly);
                    } else {
                        mapOfBundleByMissingPenny.put(productCode, mapOfBundleByMissingPenny.get(productCode) + targetPriceMonthly);
                    }
                }
            }  
        }
        System.debug('mapOfBundleByMissingPenny Target Prices per Segment'+ mapOfBundleByMissingPenny );
    }
    
    /*
* - This Method calculates the Missing Penny on Bundle after Providing the Bundle Price Override.
* - This method calcultes missing penny for each bundle and adjust it on bundle level
*/    
    public static void calculateApplyExtendedForBundle(Map<String, Decimal> mapOfBundleByMissingPenny, List<Map<String, Object>> quoteLinedata, Map<String, Object> mapQuoteData){
        Map<String,Decimal> mapOfTargetPriceMonthly = new Map<String,Decimal>();
        Set<String> setOfPennyAddedBundle = new Set<String>();
        for(Map<String, Object> lineRecord : quoteLinedata){
            String requiredByProductCode = CoreCPQCalculationService.convertToString(lineRecord,'bundleCode');
            Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRecord,'SBQQ__SegmentIndex__c');
            Decimal targetPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRecord, 'Target_Price_Monthly__c');
            String ProductSubscriptionType = CoreCPQCalculationService.convertToString(lineRecord,'SBQQ__ProductSubscriptionType__c');
            Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRecord ,'SBQQ__NonDiscountable__c');
            if(segmentIndex <= 1 && ProductSubscriptionType != 'One-time' && ProductSubscriptionType !=null && !nonDiscountable){
                mapOfTargetPriceMonthly.put(requiredByProductCode,targetPriceMonthly);
            }
        }
        System.debug('mapOfTargetPriceMonthly'+mapOfTargetPriceMonthly);
        Map<String, Decimal> mapOfRequiredByHighestAmount = new Map<String, Decimal>();
        String generatedFrom = CoreCPQCalculationService.convertToString(mapQuoteData ,'Generated_From__c');
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData ,'SBQQ__Type__c');
        Boolean added = false;
        Decimal highestAmount = 0; 
        for(Map<String, Object> lineRecord : quoteLinedata){
            String requiredByProductCode = CoreCPQCalculationService.convertToString(lineRecord,'bundleCode');
            Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRecord,'SBQQ__SegmentIndex__c');
            String productCode = CoreCPQCalculationService.convertToString(lineRecord ,'SBQQ__ProductCode__c');
            String ProductSubscriptionType = CoreCPQCalculationService.convertToString(lineRecord,'SBQQ__ProductSubscriptionType__c');
            Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRecord ,'SBQQ__NonDiscountable__c');
            if(mapOfBundleByMissingPenny.containsKey(requiredByProductCode) && segmentIndex <= 1 
               && ProductSubscriptionType != 'One-time' && ProductSubscriptionType != null && !nonDiscountable){
                   Decimal missingPennyForBundle = mapOfBundleByMissingPenny.get(requiredByProductCode);
                   System.debug('missingPennyForBundle----'+missingPennyForBundle);
                   Decimal targetPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRecord, 'Target_Price_Monthly__c');
                   System.debug('targetPriceMonthlyone----'+targetPriceMonthly);
                   mapOfTargetPriceMonthly.put(requiredByProductCode,targetPriceMonthly);
                   System.debug('mapOfTargetPriceMonthly'+mapOfTargetPriceMonthly);
                   highestAmount = mapOfRequiredByHighestAmount.containsKey(requiredByProductCode) ? mapOfRequiredByHighestAmount.get(requiredByProductCode) : 0;
                   if(highestAmount < targetPriceMonthly && quoteType != CPQConstants.QUOTE_TYPE_AMENDMENT){
                       mapOfRequiredByHighestAmount.put(requiredByProductCode, targetPriceMonthly);
                       System.debug('highestAmount----:: '+ highestAmount);
                   } else if(quoteType == CPQConstants.QUOTE_TYPE_AMENDMENT){
                       Decimal highestAmountAbs = Math.abs(highestAmount);
                       Decimal targetPriceMonthlyAbs = Math.abs(targetPriceMonthly);
                       if(highestAmountAbs < targetPriceMonthlyAbs){
                           mapOfRequiredByHighestAmount.put(requiredByProductCode, targetPriceMonthly);
                           System.debug('highestAmount----:::'+ highestAmount);
                       }
                       
                   }
               }
        }
        System.debug('mapOfRequiredByHighestAmount'+mapOfRequiredByHighestAmount);
        system.debug('mapOfBundleByMissingPenny--' + mapOfBundleByMissingPenny);
        System.debug('mapOfTargetPriceMonthly-----'+mapOfTargetPriceMonthly);
        for(Map<String, Object> lineRecord : quoteLinedata){
            String requiredByProductCode = CoreCPQCalculationService.convertToString(lineRecord,'bundleCode');
            String productCode = CoreCPQCalculationService.convertToString(lineRecord ,'SBQQ__ProductCode__c');
            Decimal targetPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRecord, 'Target_Price_Monthly__c');
            Decimal negotiatedDiscAmount = 0;
            Boolean nonDiscountable = CoreCPQCalculationService.convertToBoolean(lineRecord ,'SBQQ__NonDiscountable__c');
            Double  segmentIndex = CoreCPQCalculationService.convertToDouble(lineRecord, 'SBQQ__SegmentIndex__c');
            Decimal additionalDiscAmount = CoreCPQCalculationService.convertToDecimal(lineRecord ,'SBQQ__AdditionalDiscountAmount__c');
            Double effectiveQuantity = CoreCPQCalculationService.convertToDouble(lineRecord ,'SBQQ__EffectiveQuantity__c');
            Double prorateMultiplier = CoreCPQCalculationService.convertToDouble(lineRecord ,'SBQQ__ProrateMultiplier__c');
            Decimal discount = CoreCPQCalculationService.convertToDecimal(lineRecord ,'SBQQ__Discount__c');
            String ProductSubscriptionType = CoreCPQCalculationService.convertToString(lineRecord,'SBQQ__ProductSubscriptionType__c');
            if(!nonDiscountable && targetPriceMonthly != 0 && segmentIndex <= 1 && ProductSubscriptionType != 'One-time' && ProductSubscriptionType !=null && mapOfRequiredByHighestAmount.containsKey(requiredByProductCode) ){
                if (!nonDiscountable && (generatedFrom == 'AAR' || generatedFrom == 'Fixed Term Extension') && prorateMultiplier > 0){
                    negotiatedDiscAmount = (additionalDiscAmount * effectiveQuantity) / prorateMultiplier;
                    negotiatedDiscAmount = negotiatedDiscAmount.setScale(2,RoundingMode.HALF_UP);
                }else if(!nonDiscountable){
                    negotiatedDiscAmount = (targetPriceMonthly * discount) / 100;
                    negotiatedDiscAmount = negotiatedDiscAmount.setScale(2,RoundingMode.HALF_UP);
                }else{
                    negotiatedDiscAmount = 0; 
                }
                system.debug('productCode--' + productCode);
                system.debug('targetPriceMonthly--' + targetPriceMonthly);
                system.debug('negotiatedDiscAmount--' + negotiatedDiscAmount);
                Decimal computedVal = targetPriceMonthly - negotiatedDiscAmount;
                Decimal rounded  = computedVal.setScale(2, RoundingMode.HALF_UP);
                System.debug('roundedOne-----'+rounded);
                Decimal missingValue = mapOfBundleByMissingPenny.get(requiredByProductCode);
                System.debug('missingValue'+missingValue);
                Decimal finalValue = rounded + missingValue;
                System.debug('finalValue'+finalValue.setScale(2, RoundingMode.HALF_UP));
                if(targetPriceMonthly != 0 && mapOfRequiredByHighestAmount.get(requiredByProductCode) == targetPriceMonthly && !setOfPennyAddedBundle.contains(requiredByProductCode)){
                    lineRecord.put('Extended_Net_Monthly__c', rounded + mapOfBundleByMissingPenny.get(requiredByProductCode));
                    setOfPennyAddedBundle.add(requiredByProductCode);
                    System.debug('Extended_Net_Monthly__c'+rounded + mapOfBundleByMissingPenny.get(requiredByProductCode));
                    System.debug('Extended_Net_Monthly__c'+CoreCPQCalculationService.convertToDecimal(lineRecord ,'Extended_Net_Monthly__c'));
                }else if(targetPriceMonthly != 0){
                    lineRecord.put('Extended_Net_Monthly__c', rounded);
                    System.debug('Extended Net Monthly 2'+rounded);
                }else{
                    lineRecord.put('Extended_Net_Monthly__c', 0);
                    System.debug('Extended net Monthly 3');
                }               
                
            }
        }
    }
    
    
    
    public static void setTargetPriceOverrideOnAutoRenewal(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        String quoteGeneratedFrom = CoreCPQCalculationService.convertToString(mapQuoteData, 'Generated_From__c');
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData, 'SBQQ__Type__c');  
        Integer subscriptionTerm = CoreCPQCalculationService.convertToInteger(mapQuoteData,'SBQQ__SubscriptionTerm__c');
        if(quoteGeneratedFrom == 'AAR' && quoteType == CPQConstants.QUOTE_TYPE_RENEWAL){
            for(Map<String, Object> lineRec: quoteLinedata){
                Boolean isBundleProduct = CoreCPQCalculationService.convertToBoolean(lineRec,'SBQQ__Bundle__c');
                Decimal TargetPriceOverride = CoreCPQCalculationService.convertToDecimal(lineRec, 'Target_Price_Override__c');
                if(isBundleProduct == true){
                    lineRec.put('Target_Price_Override__c', null);
                } 
            }
        }
        
    }
    /*
* - This method used to calculate FirstSegment Net Price for GNS on Quote.
* - It Sums up the Extended Net Monthly for the first segment. If Extended Net Monthly is 0, then it takes Target Price Monthly.
*/ 
    public static void calculateFirstSegmentNetPrice(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        Decimal firstSegmentNetPrice = 0;
        for(Map<String, Object> lineRec: quoteLinedata){
            String segmentIndex = CoreCPQCalculationService.convertToString(lineRec,'SBQQ__SegmentIndex__c');
            Decimal extendedNetMonthly = CoreCPQCalculationService.convertToDecimal(lineRec,'Extended_Net_Monthly__c');
            Decimal targetPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRec,'Target_Price_Monthly__c');
            System.debug('extendedNetMonthly - '+extendedNetMonthly);
            system.debug('targetPriceMonthly -'+targetPriceMonthly);
            system.debug('segmentIndex -'+segmentIndex);
            if(segmentIndex == '1'){
                if(extendedNetMonthly > 0){
                    firstSegmentNetPrice += extendedNetMonthly;
                }else{
                    firstSegmentNetPrice += targetPriceMonthly;
                }
            }
        }
        mapQuoteData.put('FirstSegment_Net_Price__c', firstSegmentNetPrice);
    }
    
    public static Map<String, Decimal> calculateNetMonthly(List<Map<String, Object>> quoteLineData) {
        Map<String, Decimal> netMonthlyMap = new Map<String, Decimal>();
        for (Map<String, Object> lineRec : quoteLineData) {
            String productCode = CoreCPQCalculationService.convertToString(lineRec, 'SBQQ__ProductCode__c');
            Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRec, 'SBQQ__SegmentIndex__c');
            
            Decimal netMonthly;
            if (CoreCPQCalculationService.convertToBoolean(lineRec, 'Excluded__c') || CoreCPQCalculationService.convertToBoolean(lineRec, 'Free_Product__c')) {
                netMonthly = 0;
            } else if (CoreCPQCalculationService.convertToDecimal(lineRec, 'Extended_Net_Monthly__c') != null &&
                       CoreCPQCalculationService.convertToDecimal(lineRec, 'Extended_Net_Monthly__c') != 0) {
                           netMonthly = CoreCPQCalculationService.convertToDecimal(lineRec, 'Extended_Net_Monthly__c').setScale(2, RoundingMode.HALF_UP);
                       } else {
                           Decimal targetPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRec, 'Target_Price_Monthly__c');
                           Decimal negotiatedDiscAmt = CoreCPQCalculationService.convertToDecimal(lineRec, 'Negotiated_Disc_Amt__c');
                           netMonthly = (targetPriceMonthly != null && negotiatedDiscAmt != null) ? 
                               (targetPriceMonthly - negotiatedDiscAmt).setScale(2, RoundingMode.HALF_UP) : 0;
                       }
            
            if (productCode != null && segmentIndex != null) {
                netMonthlyMap.put(productCode + '_' + segmentIndex, netMonthly);
            }
        }
        
        return netMonthlyMap;
    }
    /*
* - Calculates Product POS for each Quote Line based on quote type, segment, and contract data.
* - Handles scenarios like Quote, Replacement, Renewal, AAR and One-time products.
* - Updates POS on each quote line accordingly.
*/
    public static void calculatePosOnQuoteLine(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLineData,Map<String, SBQQ__Subscription__c> allSegmentsMap,List<Contract> contractRecords) {
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData, 'SBQQ__Type__c');
        String generatedFrom = CoreCPQCalculationService.convertToString(mapQuoteData, 'Generated_From__c');
        String contractId = CoreCPQCalculationService.convertToString(mapQuoteData, 'Contract__c');
        Decimal discount = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'SBQQ__PartnerDiscount__c');
        Decimal negotiatedPrice = CoreCPQCalculationService.convertToDecimal(mapQuoteData, 'Negotiated_Price__c');
        Date quoteStartDate = CoreCPQCalculationService.convertToDate(mapQuoteData, 'SBQQ__StartDate__c');
        Date priorSegmentStartDate = CoreCPQCalculationService.convertToDate(mapQuoteData, 'PriorSegmentStartDate__c');
        String cpqComposite = CoreCPQCalculationService.convertToString(mapQuoteData, 'CPQ_Composite__c');
        String priceType = CoreCPQCalculationService.convertToString(mapQuoteData,'Price_Type__c');
        Integer annualMultiplier = priceType == 'Annual' ? 1 : 12;
        Integer targetSegment;
        Date matchedSegmentStartDate;
        Contract contractRecord = !contractRecords.isEmpty() ? contractRecords[0] : null;
        // Identify the segment year in which Cancel & Replace was performed
        if (contractRecord != null && quoteType == 'Replacement' && quoteStartDate != null) {
            if (quoteStartDate >= contractRecord.First_Segment_Start_Date__c &&  quoteStartDate <= contractRecord.First_Segment_End_Date__c) {
                matchedSegmentStartDate = contractRecord.First_Segment_Start_Date__c;
            } else if ( quoteStartDate >= contractRecord.Second_Segment_Start_Date__c && quoteStartDate <= contractRecord.Second_Segment_End_Date__c) {
                matchedSegmentStartDate = contractRecord.Second_Segment_Start_Date__c;
            } else if ( quoteStartDate >= contractRecord.Third_Segment_Start_Date__c  && quoteStartDate <= contractRecord.Third_Segment_End_Date__c ) {
                matchedSegmentStartDate = contractRecord.Third_Segment_Start_Date__c;
            } else if ( quoteStartDate >= contractRecord.Fourth_Segment_Start_Date__c  && quoteStartDate <=contractRecord.Fourth_Segment_End_Date__c ) {
                matchedSegmentStartDate = contractRecord.Fourth_Segment_Start_Date__c;
            }else if(quoteStartDate >= contractRecord.Fifth_Segment_Start_Date__c  && quoteStartDate <=contractRecord.Fifth_Segment_End_Date__c){
                matchedSegmentStartDate = contractRecord.Fifth_Segment_Start_Date__c;
            }else if(quoteStartDate >= contractRecord.Sixth_Segment_Start_Date__c  && quoteStartDate <=contractRecord.Sixth_Segment_End_Date__c){
                matchedSegmentStartDate = contractRecord.Sixth_Segment_Start_Date__c;
            }
        }
        // Calculate the last segment index in case of Renewals
        if( contractRecord != null && contractRecord.EndDate != null && contractRecord.StartDate != null){
            Integer contractMonths  = ((contractRecord.EndDate.year() - contractRecord.StartDate.year()) * 12) + (contractRecord.EndDate.month() - contractRecord.StartDate.month()) + (contractRecord.EndDate.day() >= contractRecord.StartDate.day() ? 1 : 0);
            targetSegment = (Integer)Math.ceil(contractMonths / 12.0);
        }
        Map<String, Decimal> productSegmentNetMonthlyMap = calculateNetMonthly(quoteLineData);
        Map<String, Date> productSegmentStartDateMap = new Map<String, Date>();
        Map<String, Date> productSegmentEndDateMap = new Map<String, Date>();
        for (Map<String, Object> line : quoteLineData) {
            Date startDate = CoreCPQCalculationService.convertToDate(line, 'SBQQ__StartDate__c');
            Date endDate = CoreCPQCalculationService.convertToDate(line, 'SBQQ__EndDate__c');
            String productCode = CoreCPQCalculationService.convertToString(line, 'SBQQ__ProductCode__c');
            Integer index = CoreCPQCalculationService.convertToInteger(line, 'SBQQ__SegmentIndex__c');
            if (startDate != null) {
                productSegmentStartDateMap.put(productCode + '_' + index, startDate);
            }
            if (endDate != null) {
                productSegmentEndDateMap.put(productCode + '_' + index, endDate);
            }
        }
        
        Map<String, Integer> productMaxSegmentMap = new Map<String, Integer>();
        Map<String, Decimal> contractSegmentNetMonthlyMap = new Map<String, Decimal>();
        if (!String.isBlank(contractId)) {
            // Get subscription values for the matched segment in case of Cancel & Replace
            if (quoteType == 'Replacement' && quoteStartDate != null) {
                for (SBQQ__Subscription__c sub : allSegmentsMap.values()) {
                    Boolean validSub = sub.SBQQ__StartDate__c == matchedSegmentStartDate;
                    if (validSub) {
                        String productCode = sub.SBQQ__Product__r.ProductCode;
                        String key = productCode;
                        contractSegmentNetMonthlyMap.put(key, sub.Extended_Net_Price__c);
                    }
                }
            } 
            // Get subscription values for the last segment (Renewal case)
            else if (quoteType == 'Renewal' && targetSegment != null) {
                for (SBQQ__Subscription__c sub : allSegmentsMap.values()) {
                    Integer segmentIndex = sub.SBQQ__SegmentIndex__c != null ? sub.SBQQ__SegmentIndex__c.intValue() : 0;
                    Boolean validSub = sub.SBQQ__Product__r.ProductCode != null && segmentIndex != null && sub.SBQQ__SegmentIndex__c == targetSegment;
                    System.debug(' productCode - '+sub.SBQQ__Product__r.ProductCode);
                    System.debug(' segIndex INT Value - '+segmentIndex);
                    System.debug(' segIndex - '+sub.SBQQ__SegmentIndex__c);
                    System.debug(' TargetSegment - '+targetSegment);
                    if (validSub) {
                        String productCode = sub.SBQQ__Product__r.ProductCode;
                        Integer segIndex   = sub.SBQQ__SegmentIndex__c.intValue();
                        String key = productCode + '_' + segmentIndex;
                        contractSegmentNetMonthlyMap.put(key, sub.Extended_Net_Price__c);
                        productMaxSegmentMap.put(productCode, segmentIndex);
                    }else if(cpqComposite == 'United Kingdom'){
                        String productCode = sub.SBQQ__Product__r.ProductCode;
                        String key = productCode + '_' + segmentIndex;
                        contractSegmentNetMonthlyMap.put(key, sub.Extended_Net_Price__c);
                        productMaxSegmentMap.put(productCode, segmentIndex);
                    }
                }
            }
        }
        System.debug('productMaxSegmentMap '+productMaxSegmentMap);
        System.debug('contractSegmentNetMonthlyMap '+contractSegmentNetMonthlyMap);
        for (Map<String, Object> lineRec : quoteLineData) {
            String productSubscriptionType = CoreCPQCalculationService.convertToString(lineRec, 'SBQQ__ProductSubscriptionType__c');
            String productCode = CoreCPQCalculationService.convertToString(lineRec, 'SBQQ__ProductCode__c');
            Decimal prorateMultiplier = CoreCPQCalculationService.convertToDecimal(lineRec, 'SBQQ__ProrateMultiplier__c');
            Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRec, 'SBQQ__SegmentIndex__c');
            Date startDate = CoreCPQCalculationService.convertToDate(lineRec, 'SBQQ__StartDate__c');
            Date endDate = CoreCPQCalculationService.convertToDate(lineRec, 'SBQQ__EndDate__c');
            String requiredBy = CoreCPQCalculationService.convertToString(lineRec, 'SBQQ__RequiredBy__c');
            Decimal netMonthly;
            if (CoreCPQCalculationService.convertToBoolean(lineRec, 'Excluded__c') || CoreCPQCalculationService.convertToBoolean(lineRec, 'Free_Product__c')) {
                netMonthly = 0;
            } else if(CoreCPQCalculationService.convertToBoolean(lineRec, 'SBQQ__Bundle__c') && CoreCPQCalculationService.convertToDecimal(lineRec,'SBQQ__ListPrice__c') != null){
                netMonthly = CoreCPQCalculationService.convertToDecimal(lineRec,'Bundle_Amount__c');
            }
            else if (CoreCPQCalculationService.convertToDecimal(lineRec, 'Extended_Net_Monthly__c') != null &&
                       CoreCPQCalculationService.convertToDecimal(lineRec, 'Extended_Net_Monthly__c') != 0) {
                           netMonthly = CoreCPQCalculationService.convertToDecimal(lineRec, 'Extended_Net_Monthly__c').setScale(2,RoundingMode.HALF_UP);
                       } else {
                           Decimal targetPriceMonthly = CoreCPQCalculationService.convertToDecimal(lineRec, 'Target_Price_Monthly__c');
                           Decimal negotiatedDiscAmt = CoreCPQCalculationService.convertToDecimal(lineRec, 'Negotiated_Disc_Amt__c');
                           netMonthly = (targetPriceMonthly != null && negotiatedDiscAmt != null) ? (targetPriceMonthly - negotiatedDiscAmt).setScale(2,RoundingMode.HALF_UP) : 0;
                       }
            
            Decimal totalPOS = 0;
            // Calculate the POS for Fixed Term Extension 
            if (generatedFrom == 'Fixed Term Extension') {
                lineRec.put('Product_POS_Calculation__c', 0);
            } 
            // Calculate the POS for One time Products
            else if (productSubscriptionType == 'One-time') {
                totalPOS = (netMonthly != null && prorateMultiplier != null) ? netMonthly * prorateMultiplier : 0;
                lineRec.put('Product_POS_Calculation__c', totalPOS);
            }
            // Calculate the Porduct pos for New Busienss Quote
            else if (quoteType == 'Quote') {
                if(cpqComposite == 'United Kingdom' && (segmentIndex < 1 || requiredBy == null)){
                    totalPOS = netMonthly * prorateMultiplier;
                    lineRec.put('Product_POS_Calculation__c', totalPOS);
                    system.debug('totalPOS '+totalPOS);
                }else if (segmentIndex == 1 && startDate != null && endDate != null) {
                    Integer monthDiff = ((endDate.year() - startDate.year()) * 12 + (endDate.month() - startDate.month())) + (endDate.day() >= startDate.day() ? 1 : 0);
                    totalPOS = (monthDiff <= 3) ? netMonthly * prorateMultiplier : netMonthly * annualMultiplier;
                    lineRec.put('Product_POS_Calculation__c', totalPOS);
                } else if(segmentIndex == 2){
                    Date seg1StartDate = productSegmentStartDateMap.get(productCode + '_' + 1);
                    Date seg1EndDate = productSegmentEndDateMap.get(productCode + '_1');
                    Integer monthDiff = (seg1StartDate != null && seg1EndDate != null) ? ((seg1EndDate.year() - seg1StartDate.year()) * 12 +(seg1EndDate.month() - seg1StartDate.month()) +(seg1EndDate.day() >= seg1StartDate.day() ? 1 : 0)) : null;                    if(monthDiff <=3){
                        totalPOS =  netMonthly * annualMultiplier;
                        lineRec.put('Product_POS_Calculation__c', totalPOS);
                    }else{
                        Decimal prevSegmentNetMonthly = productSegmentNetMonthlyMap.get(productCode + '_' + (segmentIndex - 1));
                        totalPOS = (netMonthly != null && prevSegmentNetMonthly != null) ? (netMonthly - prevSegmentNetMonthly) * annualMultiplier : 0;
                        lineRec.put('Product_POS_Calculation__c', totalPOS);
                    }
                }
                else if (segmentIndex > 2 && segmentIndex <= 6) {
                    Decimal prevSegmentNetMonthly = productSegmentNetMonthlyMap.get(productCode + '_' + (segmentIndex - 1));
                    totalPOS = (netMonthly != null && prevSegmentNetMonthly != null) ? (netMonthly - prevSegmentNetMonthly) * annualMultiplier : 0;
                    lineRec.put('Product_POS_Calculation__c', totalPOS);
                }
            }
            // Calculate the Product POS for Renewal and Replacment 
            else {
                if ((quoteType == 'Replacement' || (cpqComposite == 'United Kingdom' && quoteType == 'Amendment'))  && segmentIndex <= 1) {
                    String key = productCode;
                    Decimal contractNetMonthly = contractSegmentNetMonthlyMap.get(key);
                    totalPOS = (netMonthly != null) ? ((contractNetMonthly != null) ? (netMonthly - contractNetMonthly) * annualMultiplier : netMonthly * annualMultiplier) : 0;
                    lineRec.put('Product_POS_Calculation__c', totalPOS);
                    
                } else if (quoteType == 'Renewal' && segmentIndex <= 1 && generatedFrom != 'Fixed Term Extension') {
                    Decimal currentSegmentCommitment = netMonthly;
                    Integer maxSeg = productMaxSegmentMap.containsKey(productCode) ? productMaxSegmentMap.get(productCode) : 0;
                    Decimal lastSegmentCommitment = contractSegmentNetMonthlyMap.get(productCode + '_' + maxSeg);
                    totalPOS = (lastSegmentCommitment != null) ? (currentSegmentCommitment - lastSegmentCommitment) * annualMultiplier : currentSegmentCommitment * annualMultiplier;
                    lineRec.put('Product_POS_Calculation__c', totalPOS);
                } else if (segmentIndex > 1 && segmentIndex <= 6) {
                    Decimal prevSegmentNetMonthly = productSegmentNetMonthlyMap.get(productCode + '_' + (segmentIndex - 1));
                    totalPOS = (netMonthly != null && prevSegmentNetMonthly != null) ? (netMonthly - prevSegmentNetMonthly) * annualMultiplier : 0;
                    lineRec.put('Product_POS_Calculation__c', totalPOS);
                }
            }
        }
    }
    
    /*
*  - Calculates Quote Total POS from quote lines.
*  - Adds total POS of Segment 1 if it's Greater then 3 Month, else uses Segment 2.
*/
    public static void calculatePosOnQuote(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLineData) {
        String quoteType = CoreCPQCalculationService.convertToString(mapQuoteData, 'SBQQ__Type__c');
        Decimal totalPOS = 0;
        Decimal segment1POS = 0;
        Decimal segment2POS = 0;
        Decimal oneTimePOS = 0;
        Boolean isSegment1ShortTerm = false;
        
        for (Map<String, Object> lineRec : quoteLineData) {
            String productSubscriptionType = CoreCPQCalculationService.convertToString(lineRec, 'SBQQ__ProductSubscriptionType__c');
            Integer segmentIndex = CoreCPQCalculationService.convertToInteger(lineRec, 'SBQQ__SegmentIndex__c');
            Decimal productPos = CoreCPQCalculationService.convertToDecimal(lineRec, 'Product_POS_Calculation__c');
            Date startDate = CoreCPQCalculationService.convertToDate(lineRec, 'SBQQ__StartDate__c');
            Date endDate = CoreCPQCalculationService.convertToDate(lineRec, 'SBQQ__EndDate__c');
            
            // One-time POS calculation
            if (productSubscriptionType == 'One-time') {
                oneTimePOS += productPos;
            }
            System.debug('oneTimePOS'+oneTimePOS);
            // Segment-based POS calculation
            if (quoteType == 'Quote') {
                if (segmentIndex == 1 && startDate != null && endDate != null) {
                    Integer monthDiff = ((endDate.year() - startDate.year()) * 12 + (endDate.month() - startDate.month())) + (endDate.day() >= startDate.day() ? 1 : 0);
                    if (monthDiff <= 3) {
                        isSegment1ShortTerm = true;
                    } else {
                        segment1POS += productPos;
                    }
                } else if (segmentIndex == 2) {
                    segment2POS += productPos;
                }
            } else {
                if (segmentIndex == 1) {
                    segment1POS += productPos;
                }
            }
        }
        if (quoteType == 'Quote') {
            totalPOS = (isSegment1ShortTerm ? segment2POS : segment1POS) + oneTimePOS;
        } else {
            totalPOS = segment1POS + oneTimePOS;
        }
        
        mapQuoteData.put('Total_POS_Calculation__c', totalPOS);
        System.debug('totalPOS'+totalPOS);
    }   
    
    
    /* 
* - This method calculates and populates all summary fields on the Quote by aggregating data from the Quote Line roll-ups.
* - These variables act as summary fields that are used in the Quote Template and other relevant calculations. 
*/ 
    public static void calculateRollupFieldsOnBISQuote(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata){
        Integer countHasDiligence = 0;
        Integer countHasCourtlink = 0;
        Integer countHasDiligenceAddedum = 0;
        Integer countHasNewsdesk = 0;
        Integer countHasDAAS = 0;
        Integer countHasNewswire = 0;
        Integer countHasNexisWealth = 0;
        Double transactionalDiscountPrice = 0;
        
        mapQuoteData.put('Has_DAAS__c', false);
        mapQuoteData.put('Has_Newswire__c', false);
        mapQuoteData.put('Has_Corporate_Academic_Addendum__c', false);
        mapQuoteData.put('Has_Courtlink_Addendum__c', false);
        mapQuoteData.put('Has_Diligence_Addedum__c', false);
        mapQuoteData.put('Has_Newsdesk_Addendum__c', false);
        mapQuoteData.put('Has_WealthNavigator_Addendum__c', false);
        
        for(Map<String, Object> lineRec: quoteLinedata){
            String bundleName = CoreCPQCalculationService.convertToString(lineRec,'bundleName');
            
            if(bundleName == 'Research Bundle' || bundleName == 'Nexis Development Professional'){
                countHasDiligence += 1;
            }
            if(bundleName == 'Courtlink'){
                countHasCourtlink += 1;
            }
            if(bundleName == 'Nexis Diligence+'){
                countHasDiligenceAddedum += 1;
            }
            if(bundleName == 'Newsdesk'){
                countHasNewsdesk += 1;
            }
            if(bundleName == 'Newswire'){
                countHasNewswire += 1;
            }
            if(bundleName == 'Nexis Web Services API' || bundleName == 'Nexis Bulk API' || bundleName == 'Nexis Metabase Search' || bundleName == 'Nexis Metabase Firehose' || bundleName == 'Nexis Metabase Adverse News' || bundleName == 'Nexis Metabase Adverse News'){
                countHasDAAS += 1;
            }
            if(bundleName == 'Nexis Wealth Navigator'){
                countHasNexisWealth += 1;

            }
            if(CoreCPQCalculationService.convertToBoolean(lineRec,'Is_Transactional_Prod__c')){
                transactionalDiscountPrice += CoreCPQCalculationService.convertToDecimal(lineRec,'SBQQ__OriginalPrice__c');
            }
        }
        if(countHasDiligence > 0){
            mapQuoteData.put('Has_Corporate_Academic_Addendum__c', true);
        }
        if(countHasCourtlink > 0){
            mapQuoteData.put('Has_Courtlink_Addendum__c', true);
        }
        if(countHasDiligenceAddedum > 0){
            mapQuoteData.put('Has_Diligence_Addedum__c', true);
        }
        if(countHasNewsdesk > 0){
            mapQuoteData.put('Has_Newsdesk_Addendum__c', true);
        }
        if(countHasDAAS > 0){
            mapQuoteData.put('Has_DAAS__c', true);
        }
        if(countHasNewswire > 0){
            mapQuoteData.put('Has_Newswire__c', true);
        }
        if(countHasDiligence > 0){
            mapQuoteData.put('Has_Corporate_Academic_Addendum__c', true);
        }
        if(countHasNexisWealth > 0){
                          
            mapQuoteData.put('Has_WealthNavigator_Addendum__c', true);
        }
        mapQuoteData.put('Negotiated_TD_Price__c', transactionalDiscountPrice);
          
        // Debugging logs
        System.debug('Has_DAAS__c: ' + mapQuoteData.get('Has_DAAS__c') +
                     ' Has_Newswire__c: ' + mapQuoteData.get('Has_Newswire__c') +
                     ' Has_Corporate_Academic_Addendum__c: ' + mapQuoteData.get('Has_Corporate_Academic_Addendum__c') +
                     ' Has_Courtlink_Addendum__c: ' + mapQuoteData.get('Has_Courtlink_Addendum__c') +
                     ' Has_Diligence_Addedum__c: ' + mapQuoteData.get('Has_Diligence_Addedum__c') +
                     ' Has_Newsdesk_Addendum__c: ' + mapQuoteData.get('Has_Newsdesk_Addendum__c') +
                     ' Negotiated_TD_Price__c: ' + mapQuoteData.get('Negotiated_TD_Price__c') );
    }
    /* 
* - This method checks if the quote has a GCA (Global Corporate Agreement) based on the billing start date and the account's global documents.
*/  
    public static void populateHasGCAOnQuote(Map<String, Object> mapQuoteData, List<Map<String,Object>> quoteLineData) {
        mapQuoteData.put('Has_GCA__c', false);
        Date billingStartDate = CoreCPQCalculationService.convertToDate(mapQuoteData, 'Billing_Start_Date__c');
        String accountId = CoreCPQCalculationService.convertToString(mapQuoteData,'SBQQ__Account__c');
        String cpqComposite = CoreCPQCalculationService.convertToString(mapQuoteData,'CPQ_Composite__c');
        String subSegmentFilter;
        if (cpqComposite == CPQConstants.CPQ_COMPOSITE_BIS) {
            subSegmentFilter = CPQConstants.Sub_Segment_gNS;
        } 
        else {
            subSegmentFilter = cpqComposite;
        }
        
        List<Global_Documents__c>globalDocument = [
            SELECT Id , End_Date__c, Account__c,Start_Date__c,Type__c,Sub_Segment__c
            FROM Global_Documents__c 
            WHERE Account__r.id =: accountId AND  Sub_Segment__c =:subSegmentFilter AND Type__c = 'GCA' order by End_Date__c desc
        ];
        
        
        if(globalDocument.isempty()){
            mapQuoteData.put('Has_GCA__c', true);
        }
        
        Global_Documents__c maxEndDateRecord;
        Global_Documents__c maxStartDateRecord;
        
        if(!globalDocument.isempty()){
            // Find the record with the greatest End_Date__c
            for (Global_Documents__c globalDoc : globalDocument) {
                if (globalDoc.End_Date__c != null) {
                    if (maxEndDateRecord == null || globalDoc.End_Date__c > maxEndDateRecord.End_Date__c) {
                        maxEndDateRecord = globalDoc;
                        
                    }
                }
                if (globalDoc.Start_Date__c != null) {
                    if (maxStartDateRecord == null || globalDoc.Start_Date__c > maxStartDateRecord.Start_Date__c) {
                        maxStartDateRecord = globalDoc;
                        
                    }
                }
            }
            if(maxEndDateRecord == null){
                for (Global_Documents__c globalDoc : globalDocument) {
                    if (globalDoc.End_Date__c == null) {
                        maxEndDateRecord = globalDoc;
                        break;
                    }
                }
            }
            if(maxStartDateRecord == null){
                for (Global_Documents__c globalDoc : globalDocument) {
                    if (globalDoc.Start_Date__c == null) {
                        maxStartDateRecord = globalDoc;
                        break;
                    }
                }
            }
            // Decide Has_GCA__c based on the record with the greatest End_Date__c
            if (maxEndDateRecord != null && (maxEndDateRecord.End_Date__c < billingStartDate ||maxEndDateRecord.End_Date__c == Null )) {
                mapQuoteData.put('Has_GCA__c', true);
            }  
            if (maxStartDateRecord != null ) {
                mapQuoteData.put('GCA_Start_Date__c',maxEndDateRecord.Start_Date__c);
            }
        }
        // Debugging logs
        System.debug('Has_GCA__c: ' + mapQuoteData.get('Has_GCA__c') + ' ' + 'GCA_Start_Date__c: ' + mapQuoteData.get('GCA_Start_Date__c'));
    }
    
    
    /*Calculates and updates the List Price ('SBQQ__ListPrice__c') for Nexis Data Bundle products on quote lines based on tiered pricing and multipliers.*/
    public static void calculateTierBasedListPriceForNexisDataBundle(Map<String, Object> mapQuoteData, List<Map<String, Object>> quoteLinedata) {
        
        // Map to store Tier Pricing records categorized by product and bundle
        Map<String, List<Tier_Pricing__c>> mapOfTierPricing = new Map<String, List<Tier_Pricing__c>>();
        // Set to store all unique bundle codes present in quote lines
        Set<String>setOfBundleName = new Set<String>();
        Set<String>articleBands = new Set<String>();
        Map<String, gNS_Nexis_Data_Bundle_Multiplier__mdt> mapOfCustomMetadata = new Map<String, gNS_Nexis_Data_Bundle_Multiplier__mdt>();
        Set<String>setOfProductId = new Set<String>();
        
        // Loop through quote lines 
        for (Map<String, Object> lineRecord : quoteLinedata) {
            String productId = CoreCPQCalculationService.convertToString(lineRecord, 'Product_Id__c');
            String bundleName = CoreCPQCalculationService.convertToString(lineRecord, 'Bundle_Name__c');
            String articleBand = CoreCPQCalculationService.convertToString(lineRecord, 'Articles__c');
            
            if (String.isNotBlank(bundleName)) {
                setOfBundleName.add(bundleName);
            }
            
            if(productId == '1542769' || productId == '1542904' || productId == '1525607'){
                articleBands.add(articleBand);
            }
        }
        
        if(!articleBands.isEmpty() ){
            List<gNS_Nexis_Data_Bundle_Multiplier__mdt> listOfNexisDataBundleMultiplier = [Select Id, Article_Bands__c, Multiplier__c From gNS_Nexis_Data_Bundle_Multiplier__mdt WHERE Article_Bands__c IN :articleBands];
            if(!listOfNexisDataBundleMultiplier.isEmpty()){
                for(gNS_Nexis_Data_Bundle_Multiplier__mdt mtdt: listOfNexisDataBundleMultiplier){
                    String metadataKey = mtdt.Article_Bands__c;
                    mapOfCustomMetadata.put(metadataKey,mtdt);
                } 
            }
        }
        
        Map<String, List<Tier_Pricing__c>> pricingMap = new Map<String, List<Tier_Pricing__c>>();
        pricingMap = CoreCPQCalculationHelper.getTierPricingByProductAndBundle(setOfBundleName);
        
        for (Map<String, Object> lineRecord : quoteLinedata) {
            String product = CoreCPQCalculationService.convertToString(lineRecord, 'SBQQ__Product__c');
            String articleBand = CoreCPQCalculationService.convertToString(lineRecord, 'Articles__c');
            Integer reader = CoreCPQCalculationService.convertToInteger(lineRecord, 'Readers__c');
            Integer hours = CoreCPQCalculationService.convertToInteger(lineRecord, 'Hours__c');
            Integer entity = CoreCPQCalculationService.convertToInteger(lineRecord, 'Entity__c');
            String searchDocCt = CoreCPQCalculationService.convertToString(lineRecord, 'Searches_Doc_Ct__c');
            
            String bundleName = CoreCPQCalculationService.convertToString(lineRecord, 'Bundle_Name__c');
            system.debug('inside entity 1585'+searchDocCt);
            Decimal multiplier;
            String key = product + ',' + bundleName;
            Boolean priceSet = false;
            
            if(mapOfCustomMetadata.containsKey(articleBand)){
                multiplier = mapOfCustomMetadata.get(articleBand).Multiplier__c;
            }
            
            if(bundleName != null){
                if (pricingMap.containsKey(key)) {
                    for (Tier_Pricing__c tier : pricingMap.get(key)) {
                        if(product == tier.Product__c){
                            if(articleBand != null && reader >=tier.Lower_Bound__c && reader <=tier.Upper_Bound__c){
                                lineRecord.put('SBQQ__ListPrice__c', tier.Price__c * multiplier);
                                priceSet = true;
                                break;
                            }
                            else if(hours == tier.Lower_Bound__c ){
                                lineRecord.put('SBQQ__ListPrice__c', tier.Price__c);
                                priceSet = true;
                                break;
                            }
                            else if(entity != null && entity >=tier.Lower_Bound__c && entity <=tier.Upper_Bound__c ){
                                lineRecord.put('SBQQ__ListPrice__c', tier.Price__c);
                                priceSet = true;
                                break;
                            }
                            else if(searchDocCt != null && tier.Searches_Doc_Ct__c != null && searchDocCt == tier.Searches_Doc_Ct__c){
                                lineRecord.put('SBQQ__ListPrice__c', tier.Price__c);
                                priceSet = true;
                                break;
                            }
                        }
                    }
                }
                if(!priceSet){
                    lineRecord.put('SBQQ__ListPrice__c',(Decimal) lineRecord.get('SBQQ__OriginalPrice__c'));
                }
            }
        }  
    }
    
	}