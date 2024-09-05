public with sharing class OpportunityProductController {

    @AuraEnabled(cacheable=true) // cacheable permet de mettre en cache les résultats de l'appel à la méthode.
    public static List<OpportunityProductWrapper> getOpportunityLineItems(Id opportunityId) { // Elle prends en paramètre l'Id d'un op. 
        if (!Schema.sObjectType.OpportunityLineItem.isAccessible()) { // Vérification si l'utilisateur à les permissions necessaires. 
            throw new CustomException('Vous n\'avez pas les permissions nécessaires pour accéder aux Opportunity Line Items.'); // CustomException permet de définir une exception personnalisée.
        }
        // Requête SOQL pour récupérer les OpportunityLineItems associés à l'opportunité spécifiée par opportunityId.
        List<OpportunityProductWrapper> items = new List<OpportunityProductWrapper>();
        for (OpportunityLineItem item : [
            SELECT Product2.Name, UnitPrice, TotalPrice, Quantity, // Requete SOQL pour récupérer les OpportunityLineItems associés à l'opportunité spécifiée par opportunityId.
                   Product2.QuantityInStock__c, Product2.Id, Id
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
        ]) {
            items.add(new OpportunityProductWrapper( // Les résultats sont encapsulés dans des objets OpportunityProductWrapper pour faciliter leur utilisation.
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
    //Peut etre appelé à partir de composants LWC/Aura
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
    // Méthode pour vérifier si l'utilisateur est commercial
    @AuraEnabled(cacheable=true)
    public static Boolean isUserCommercial() {
        if (!Schema.sObjectType.Profile.isAccessible()) {
            throw new CustomException('Vous n\'avez pas les permissions nécessaires pour accéder aux profils.');
        }

        Profile p = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()]; 
        return p.Name == 'Commercial';
    }


    // Méthode pour mettre à jour quantityInStock
    @AuraEnabled
public static void updateOpportunityProduct(OpportunityLineItem opportunityLineItem) {
    // Vérifier si l'utilisateur a le profil "Administrateur système"
    Profile currentUserProfile = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
    
    if (currentUserProfile.Name != 'System Administrator') {
        throw new CustomException('Seuls les utilisateurs ayant le profil "Administrateur Système" sont autorisés à effectuer cette modification. Si Vous souhaitez modifier la quantité en Stock, contactez votre Administrateur Système.');
    }
    
    if (!Schema.sObjectType.OpportunityLineItem.isUpdateable()) {
        throw new CustomException('Vous n\'avez pas les permissions nécessaires pour mettre à jour les Opportunity Line Items.');
    }

    // Vérifier que l'Id est présent
    if (opportunityLineItem == null || opportunityLineItem.Id == null) {
        throw new CustomException('L\'ID de l\'Opportunity Line Item est requis pour la mise à jour.');
    }

    try {
        System.debug('OpportunityLineItem reçu pour mise à jour: ' + opportunityLineItem); 
        
        // Récupérer l'OpportunityLineItem et le Product2 associé
        OpportunityLineItem existingRecord = [SELECT Id, Product2Id FROM OpportunityLineItem WHERE Id = :opportunityLineItem.Id LIMIT 1];
        Product2 productToUpdate = [SELECT Id, QuantityInStock__c FROM Product2 WHERE Id = :existingRecord.Product2Id LIMIT 1];
        
        System.debug('Valeur actuelle de QuantityInStock du produit avant mise à jour: ' + productToUpdate.QuantityInStock__c);
        
        // Mettre à jour la quantité en stock du produit
        Decimal newQuantityInStock = opportunityLineItem.Quantity; 
        productToUpdate.QuantityInStock__c = newQuantityInStock;  // Mise à jour de la quantité en stock avec la nouvelle valeur
        
        update productToUpdate;  // Met à jour l'enregistrement Product2 dans Salesforce

        System.debug('Opportunity Line Item mis à jour avec ID: ' + opportunityLineItem.Id);
        System.debug('Valeur mise à jour de QuantityInStock du produit après mise à jour: ' + productToUpdate.QuantityInStock__c);
        
    } catch (DmlException e) { 
        System.debug('Error occurred while updating Opportunity Line Item: ' + e.getMessage());
        throw new CustomException('Error updating Opportunity Product: ' + e.getMessage());
    } catch (Exception e) {
        System.debug('Unexpected error: ' + e.getMessage());
        throw new CustomException('An unexpected error occurred: ' + e.getMessage());
    }
}
    
    
    // classe Apex utilisée pour encapsuler et transférer des informations relatives à un produit et à sa relation avec une opportunité dans Salesforce, facilitant ainsi la manipulation de ces données dans des interfaces utilisateur telles que les composants Lightning.
    public class CustomException extends Exception {} 

    public class OpportunityProductWrapper { 
        @AuraEnabled public String productName { get; set; } 
        @AuraEnabled public Decimal unitPrice { get; set; }
        @AuraEnabled public Decimal totalPrice { get; set; }
        @AuraEnabled public Decimal quantity { get; set; }
        @AuraEnabled public Decimal quantityInStock { get; set; }
        @AuraEnabled public Id productId { get; set; } // Utilisation de l'Id de Product2
        @AuraEnabled public Id opportunityLineItemId { get; set; } // Utilisation de l'Id de OpportunityLineItem
        // Encapsulation des champs spécifiques d'un enregsitrement Salesforce. 
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