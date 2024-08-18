public with sharing class OpportunityProductController {
    
    @AuraEnabled(cacheable=true)
    public static List<OpportunityProductWrapper> getOpportunityLineItems(Id opportunityId) {
        List<OpportunityProductWrapper> items = new List<OpportunityProductWrapper>();
        for (OpportunityLineItem item : [
            SELECT Id, Product2.Name, Product2.Id, UnitPrice, TotalPrice, Quantity,
                   Product2.QuantityInStock__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
        ]) {
            items.add(new OpportunityProductWrapper(
                item.Product2.Name, 
                item.UnitPrice, 
                item.TotalPrice, 
                item.Quantity, 
                item.Product2.QuantityInStock__c,
                item.Product2.Id  // ID du produit ici
            ));
        }
        return items;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isUserCommercial() {
        String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
        return profileName == 'Commercial'; // Remplacez 'Commercial' par le nom exact du profil des commerciaux dans votre organisation
    }

    public class OpportunityProductWrapper {
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public Decimal unitPrice { get; set; }
        @AuraEnabled public Decimal totalPrice { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
        @AuraEnabled public Decimal quantityInStock { get; set; }
        @AuraEnabled public String productId { get; set; }

        public OpportunityProductWrapper(String productName, Decimal unitPrice, Decimal totalPrice, Decimal quantity, Decimal quantityInStock, String productId) {
            this.productName = productName;
            this.unitPrice = unitPrice;
            this.totalPrice = totalPrice;
            this.quantity = quantity;
            this.quantityInStock = quantityInStock;
            this.productId = productId;
        }
    }
}