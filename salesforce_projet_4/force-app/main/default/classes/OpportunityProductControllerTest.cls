@isTest(seeAllData=false)
private class OpportunityProductControllerTest {

   
    
    static Account testAccount = TestDataFactory.createTestAccount();
    static Opportunity testOpportunity = TestDataFactory.createTestOpportunity(testAccount.Id);
    static Product2 testProduct = TestDataFactory.createTestProduct();
    static Id pricebookEntryId = TestDataFactory.createTestPricebookEntry(testProduct.Id);
    static OpportunityLineItem oli = TestDataFactory.createTestOpportunityLineItem(testOpportunity.Id, pricebookEntryId);
    

    @isTest
    static void testGetOpportunityLineItems() {
        // Récupérer l'opportunité créée dans setupTestData
        Test.startTest();
        //Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        List<OpportunityLineItem> olis = [SELECT Id, OpportunityId FROM OpportunityLineItem WHERE OpportunityId = :testOpportunity.Id]; // !!!!!Probleme ici. La requete récupérer mal l'opportunityitemLine générée dans TestDataFactory
        Test.stopTest();

        // Vérifier que l'opportunité existe
        System.assertNotEquals(null, testOpportunity, 'The testOpportunity should exist');
        System.debug('ID de l\'opportunité utilisée : ' + testOpportunity.Id);
        
        // Requête pour récupérer les OpportunityLineItems après les données de test
        System.debug('OpportunityLineItems trouvés immédiatement après création : ' + olis.size());

        // Vérifier que l'OpportunityLineItem est bien inséré
        System.assert(olis.size() > 0, 'Les OpportunityLineItems doivent exister pour l\'opportunité.');

        //Test.startTest();
        // Appeler la méthode à tester
        List<OpportunityProductController.OpportunityProductWrapper> results = OpportunityProductController.getOpportunityLineItems(testOpportunity.Id);
        //Test.stopTest();

        // Vérifier qu'il y a au moins un élément de ligne d'opportunité retourné
        System.debug('Résultats retournés par getOpportunityLineItems : ' + results.size());
        System.assertNotEquals(0, results.size(), 'There should be at least one Opportunity Line Item returned');
    }

    @isTest
    static void testIsUserCommercial() {
        Test.startTest();
        Boolean isCommercial = OpportunityProductController.isUserCommercial();
        Test.stopTest();

        System.assertNotEquals(null, isCommercial, 'The result should not be null');
    }
    @isTest
    static void testDeleteOpportunityLineItemAndProduct() {
        List<OpportunityLineItem> testOLIs = [SELECT Id, OpportunityId FROM OpportunityLineItem LIMIT 1]; //SOQL_EXECUTE_END|[51]|Rows:1
        
        // Vérifiez que l'OpportunityLineItem existe bien
        System.assertEquals(1, testOLIs.size(), 'Il devrait y avoir un Opportunity Line Item');
        OpportunityProductController.deleteOpportunityLineItemAndProduct(testOLIs[0].Id); // Pourquoi aller chercher la méthode dans le fichier non test ? switch sur la méthode dans OPC.cls

        // Vérifiez que l'OpportunityLineItem a bien été supprimé
        Integer count = [SELECT count() FROM OpportunityLineItem WHERE Id = :testOLIs[0].Id];
        System.assertEquals(0, count, 'L\'Opportunity Line Item devrait être supprimé');
    }
}
