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

    public class OpportunityProductWrapper {
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public Decimal unitPrice { get; set; }
        @AuraEnabled public Decimal totalPrice { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
        @AuraEnabled public Decimal quantityInStock { get; set; }
        @AuraEnabled public Id productId { get; set; }  // Propriété pour stocker l'ID du produit

        public OpportunityProductWrapper(String productName, Decimal unitPrice, Decimal totalPrice, Decimal quantity, Decimal quantityInStock, Id productId) {
            this.productName = productName;
            this.unitPrice = unitPrice;
            this.totalPrice = totalPrice;
            this.quantity = quantity;
            this.quantityInStock = quantityInStock;
            this.productId = productId;
        }
    }
}

