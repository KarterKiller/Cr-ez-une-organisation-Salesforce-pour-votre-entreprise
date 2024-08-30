@isTest
public class TestDataFactory {

    // Méthode pour créer un compte de test
    public static Account createTestAccount() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        return acc;
    }

    // Méthode pour créer une opportunité de test
    public static Opportunity createTestOpportunity(Id accountId) {
        // Vérification que l'ID du compte n'est pas nul
        System.assertNotEquals(null, accountId, 'L\'ID du compte fourni est nul.');
    
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = accountId
        );
        
        insert opp;
        return opp;
    }

    // Méthode pour créer un produit de test
    public static Product2 createTestProduct() {
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP-001',
            QuantityInStock__c = 100
        );
        insert prod;
        return prod;
    }

    // Méthode pour créer un PricebookEntry de test
    public static Id createTestPricebookEntry(Id productId) {
           
        Id standardPricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPriceEntry = new PricebookEntry(
            IsActive = true,
            Product2Id = productId,
            Pricebook2Id = standardPricebookId,
            UnitPrice = 100,
            UseStandardPrice = false
        );
            insert standardPriceEntry;
            return standardPriceEntry.Id;
    }
    public static OpportunityLineItem createTestOpportunityLineItem(Id opportunityId, Id pricebookEntryId) {
        // Vérifications pour s'assurer que les IDs ne sont pas nuls
        System.assertNotEquals(null, opportunityId, 'L\'ID de l\'opportunité fourni est nul.');
        System.assertNotEquals(null, pricebookEntryId, 'L\'ID du PricebookEntry fourni est nul.');

        //Création de OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
           OpportunityId = opportunityId, // Ici opportunity.Id = c'est l'Id de l'opportunité créée précédemment.
           PricebookEntryId = pricebookEntryId,
           Quantity = 10,
           UnitPrice = 100
        );

        // Insertion de l'OpportunityLineItem
        insert oli; // Insertion OK d'après le Log : Op:Insert|Type:OpportunityLineItem|Rows:1

        // Debug pour vérifier l'insertion
        System.debug('OpportunityLineItem créé avec ID: ' + oli.Id + ' pour l\'opportunité ID: ' + opportunityId);

        // Vérification que l'OpportunityLineItem a bien été inséré
        System.assertNotEquals(null, oli.Id, 'L\'OpportunityLineItem n\'a pas été créé correctement.');

        return oli;
    }
}
