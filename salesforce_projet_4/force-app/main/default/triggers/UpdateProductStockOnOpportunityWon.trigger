trigger UpdateProductStockOnOpportunityWon on Opportunity (after update) {
    // Vérifiez les permissions CRUD pour l'objet OpportunityLineItem
    if (!Schema.sObjectType.OpportunityLineItem.isAccessible() || !Schema.sObjectType.Product2.isAccessible()) {
        System.debug('L\'utilisateur n\'a pas les permissions nécessaires pour accéder aux objets requis.');
        return;
    }

    // Map pour stocker les quantités à déduire par produit
    Map<Id, Decimal> productStockUpdates = new Map<Id, Decimal>();
    Set<Id> opportunityIds = new Set<Id>();
    
    // Collecte des opportunités qui sont passées à "Closed Won"
    for (Opportunity opp : Trigger.new) {
        Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
        
        if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
            opportunityIds.add(opp.Id);
        }
    }
    
    if (opportunityIds.size() > 0) {
        // Vérifiez les permissions CRUD avant de faire une requête sur OpportunityLineItem
        if (Schema.sObjectType.OpportunityLineItem.fields.Product2Id.isAccessible()) {
            // Récupère les lignes de produit associées aux opportunités
            List<OpportunityLineItem> lineItems = [
                SELECT Id, Quantity, Product2Id, Product2.QuantityInStock__c 
                FROM OpportunityLineItem 
                WHERE OpportunityId IN :opportunityIds
            ];
            
            // Vérifie si la quantité demandée dépasse la quantité en stock
            for (OpportunityLineItem item : lineItems) {
                if (item.Quantity > item.Product2.QuantityInStock__c) {
                    // Si la quantité demandée dépasse la quantité en stock, déclenche une erreur
                    Trigger.newMap.get(item.OpportunityId).addError('La quantité demandée pour le produit ' + item.Product2.Name + 
                                 ' dépasse la quantité en stock. Aucun produit ne sera mis à jour.');
                    return;
                }
            }
            
            // Si toutes les vérifications sont passées, prépare la mise à jour des stocks
            for (OpportunityLineItem item : lineItems) {
                if (productStockUpdates.containsKey(item.Product2Id)) {
                    productStockUpdates.put(item.Product2Id, productStockUpdates.get(item.Product2Id) + item.Quantity);
                } else {
                    productStockUpdates.put(item.Product2Id, item.Quantity);
                }
            }
            
            // Vérifiez les permissions CRUD avant de mettre à jour les produits
            if (Schema.sObjectType.Product2.isUpdateable()) {
                // Met à jour les produits avec les nouvelles quantités en stock
                List<Product2> productsToUpdate = new List<Product2>();
                for (Id productId : productStockUpdates.keySet()) {
                    Product2 prod = [SELECT Id, QuantityInStock__c FROM Product2 WHERE Id = :productId];
                    prod.QuantityInStock__c -= productStockUpdates.get(productId);
                    productsToUpdate.add(prod);
                }
                
                if (productsToUpdate.size() > 0) {
                    update productsToUpdate;
                }
            } else {
                System.debug('L\'utilisateur n\'a pas les permissions nécessaires pour mettre à jour les enregistrements de Product2.');
            }
        }
    }
}
