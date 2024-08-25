public with sharing class OpportunityProductController {

    @AuraEnabled(cacheable=true)
    public static List<OpportunityProductWrapper> getOpportunityLineItems(Id opportunityId) {
        if (!Schema.sObjectType.OpportunityLineItem.isAccessible()) {
            throw new CustomException('Vous n\'avez pas les permissions nécessaires pour accéder aux Opportunity Line Items.');
        }

        List<OpportunityProductWrapper> items = new List<OpportunityProductWrapper>();
        for (OpportunityLineItem item : [
            SELECT Product2.Name, UnitPrice, TotalPrice, Quantity,
                   Product2.QuantityInStock__c, Product2.Id, Id
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
        ]) {
            items.add(new OpportunityProductWrapper(
                item.Product2.Name, 
                item.UnitPrice, 
                item.TotalPrice, 
                item.Quantity, 
                item.Product2.QuantityInStock__c,
                item.Product2.Id, // Utilisation de l'Id de Product2 pour la suppression
                item.Id // Utilisation de l'Id de OpportunityLineItem pour la suppression
            ));
        }
        return items;
    }

    @AuraEnabled
    public static void deleteOpportunityLineItemAndProduct(Id opportunityLineItemId) {
        System.debug('OpportunityLineItem ID received for deletion: ' + opportunityLineItemId);

        if (!Schema.sObjectType.OpportunityLineItem.isDeletable()) {
            throw new CustomException('Vous n\'avez pas les permissions nécessaires pour supprimer les Opportunity Line Items.');
        }

        try {
            // Récupérer l'OpportunityLineItem et le produit associé
            OpportunityLineItem lineItem = [
                SELECT Id, Product2Id 
                FROM OpportunityLineItem 
                WHERE Id = :opportunityLineItemId LIMIT 1
            ];

            Product2 product = [SELECT Id FROM Product2 WHERE Id = :lineItem.Product2Id LIMIT 1];

            // Supprimer l'OpportunityLineItem
            delete lineItem;
            System.debug('OpportunityLineItem deleted successfully with ID: ' + opportunityLineItemId);

            // Supprimer le produit associé
            delete product;
            System.debug('Product deleted successfully with ID: ' + product.Id);

        } catch (Exception e) {
            System.debug('Error occurred while deleting OpportunityLineItem or Product: ' + e.getMessage());
            throw new CustomException('Failed to delete the Opportunity Line Item or Product: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isUserCommercial() {
        if (!Schema.sObjectType.Profile.isAccessible()) {
            throw new CustomException('Vous n\'avez pas les permissions nécessaires pour accéder aux profils.');
        }

        Profile p = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
        return p.Name == 'Commercial';
    }

    public class CustomException extends Exception {}

    public class OpportunityProductWrapper {
        @AuraEnabled public String productName { get; set; }
        @AuraEnabled public Decimal unitPrice { get; set; }
        @AuraEnabled public Decimal totalPrice { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
        @AuraEnabled public Decimal quantityInStock { get; set; }
        @AuraEnabled public Id productId { get; set; } // Utilisation de l'Id de Product2
        @AuraEnabled public Id opportunityLineItemId { get; set; } // Utilisation de l'Id de OpportunityLineItem

        public OpportunityProductWrapper(String productName, Decimal unitPrice, Decimal totalPrice, Decimal quantity, Decimal quantityInStock, Id productId, Id opportunityLineItemId) {
            this.productName = productName;
            this.unitPrice = unitPrice;
            this.totalPrice = totalPrice;
            this.quantity = quantity;
            this.quantityInStock = quantityInStock;
            this.productId = productId;
            this.opportunityLineItemId = opportunityLineItemId;
        }
    }
}