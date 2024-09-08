@isTest
public class OpportunityProductControllerTest {

    @isTest
    static void testGetOpportunityLineItems_success() {
        try {
            // Setup data
            Account testAccount = TestDataFactory.createTestAccount();
            Opportunity testOpportunity = TestDataFactory.createTestOpportunity(testAccount.Id);
            Product2 testProduct = TestDataFactory.createTestProduct();
            Id pricebookEntryId = TestDataFactory.createTestPricebookEntry(testProduct.Id);
            OpportunityLineItem oli = TestDataFactory.createTestOpportunityLineItem(testOpportunity.Id, pricebookEntryId);

            // Execution du test
            Test.startTest();
            List<OpportunityProductController.OpportunityProductWrapper> result = OpportunityProductController.getOpportunityLineItems(testOpportunity.Id);
            Test.stopTest();

            System.assertNotEquals(null, result, 'The result should not be null.');
            System.assertEquals(1, result.size(), 'The result size should be 1.');
            System.assertEquals(oli.Id, result[0].opportunityLineItemId, 'The OpportunityLineItem ID should match.');
        } catch (Exception e) {
            System.debug('Exception dans testGetOpportunityLineItems_success: ' + e.getMessage());
            System.assert(false, 'Une exception ne devrait pas être levée dans ce test.');
        }
    }

    @isTest
    static void testGetOpportunityLineItems_noAccess() {
        // Simule un contexte où l'utilisateur n'a pas accès aux OpportunityLineItems
        Profile restrictedProfile = [SELECT Id FROM Profile WHERE Name = 'Standard Platform User' LIMIT 1];

        // Création d'un utilisateur de test 
        User restrictedUser = new User(
            Alias = 'ruser',
            Email = 'restricteduser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'RestrictedUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = restrictedProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'restricteduser@test.com'
        );
        insert restrictedUser;

        // Test en exécutant comme le nouvel utilisateur de test avec des accès restreints
        System.runAs(restrictedUser) {
            Test.startTest();
            try {
                OpportunityProductController.getOpportunityLineItems(null);
                System.assert(false, 'Exception should have been thrown due to lack of access.');
            } catch (OpportunityProductController.CustomException e) {
                System.assertEquals('Vous n\'avez pas les permissions nécessaires pour accéder aux Opportunity Line Items.', e.getMessage(), 'The exception message should match.');
            } catch (Exception e) {
                System.assert(false, 'Une exception inattendue a été levée : ' + e.getMessage());
            }
            Test.stopTest();
        }
    }

    @isTest
    static void testDeleteOpportunityLineItemAndProduct_success() {
        try {
            // Setup data using TestDataFactory
            Account testAccount = TestDataFactory.createTestAccount();
            Opportunity testOpportunity = TestDataFactory.createTestOpportunity(testAccount.Id);
            Product2 testProduct = TestDataFactory.createTestProduct();
            Id pricebookEntryId = TestDataFactory.createTestPricebookEntry(testProduct.Id);
            OpportunityLineItem oli = TestDataFactory.createTestOpportunityLineItem(testOpportunity.Id, pricebookEntryId);

            // Test the successful deletion of Opportunity Line Item and associated Product
            Test.startTest();
            OpportunityProductController.deleteOpportunityLineItemAndProduct(oli.Id);
            Test.stopTest();

            // Verify that the OpportunityLineItem and Product2 have been deleted
            Integer count = [SELECT COUNT() FROM OpportunityLineItem WHERE Id = :oli.Id];
            System.assertEquals(0, count, 'L\'Opportunity Line Item devrait être supprimé.');
        } catch (Exception e) {
            System.debug('Exception dans testDeleteOpportunityLineItemAndProduct_success: ' + e.getMessage());
            System.assert(false, 'Une exception ne devrait pas être levée dans ce test.');
        }
    }

    @isTest
    static void testIsUserCommercial_success() {
        try {
            // Crée un profil de test avec le nom 'Commercial'
            Profile commercialProfile = [SELECT Id FROM Profile WHERE Name = 'Commercial' LIMIT 1];

            // Crée un utilisateur de test avec le profil 'Commercial'
            User commercialUser = new User(
                Alias = 'cuser',
                Email = 'commercialuser@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = commercialProfile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'commercialuser@test.com'
            );
            insert commercialUser;

            // Test en exécutant comme le nouvel utilisateur de test
            System.runAs(commercialUser) {
                Test.startTest();
                Boolean result = OpportunityProductController.isUserCommercial();
                Test.stopTest();

                // Vérifier que le résultat est true car l'utilisateur a le profil 'Commercial'
                System.assertEquals(true, result, 'L\'utilisateur avec le profil Commercial doit retourner true.');
            }
        } catch (Exception e) {
            System.debug('Exception dans testIsUserCommercial_success: ' + e.getMessage());
            System.assert(false, 'Une exception ne devrait pas être levée dans ce test.');
        }
    }

    @isTest
    static void testIsUserCommercial_failure() {
        try {
            // Crée un profil de test différent de 'Commercial'
            Profile otherProfile = [SELECT Id FROM Profile WHERE Name != 'Commercial' LIMIT 1];

            // Crée un utilisateur de test avec un profil différent de 'Commercial'
            User otherUser = new User(
                Alias = 'ouser',
                Email = 'otheruser@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = otherProfile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'otheruser@test.com'
            );
            insert otherUser;

            // Test en exécutant comme le nouvel utilisateur de test
            System.runAs(otherUser) {
                Test.startTest();
                Boolean result = OpportunityProductController.isUserCommercial();
                Test.stopTest();

                // Vérifier que le résultat est false car l'utilisateur n'a pas le profil 'Commercial'
                System.assertEquals(false, result, 'L\'utilisateur sans le profil Commercial doit retourner false.');
            }
        } catch (Exception e) {
            System.debug('Exception dans testIsUserCommercial_failure: ' + e.getMessage());
            System.assert(false, 'Une exception ne devrait pas être levée dans ce test.');
        }
    }

    @isTest
    static void testIsUserCommercial_noAccess() {
        Profile restrictedProfile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1]; // Modif ici 

        // Crée un utilisateur de test avec ce profil
        User restrictedUser = new User(
            Alias = 'ruser',
            Email = 'restricteduser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'RestrictedUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = restrictedProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'restricteduser@test.com'
        );
        insert restrictedUser;

        // Test en exécutant comme le nouvel utilisateur de test avec des accès restreints
        System.runAs(restrictedUser) {
            Test.startTest();
            try {
                OpportunityProductController.isUserCommercial();
                System.assert(false, 'Exception should have been thrown due to lack of access to Profile.');
            } catch (OpportunityProductController.CustomException e) {
                System.assertEquals('Vous n\'avez pas les permissions nécessaires pour accéder aux profils.', e.getMessage(), 'The exception message should match.');
            } catch (Exception e) {
                System.assert(false, 'Une exception inattendue a été levée : ' + e.getMessage());
            }
            Test.stopTest();
        }
    }

    // New Methods for updateOpportunityProduct

    @isTest
    static void testUpdateOpportunityProduct_success() {
        // Crée un utilisateur de test avec le profil "System Administrator"
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User adminUser = new User(
            Alias = 'auser',
            Email = 'adminuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'AdminUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'adminusertestok@test.com'
        );
        insert adminUser;

        System.runAs(adminUser) {
            try {
                // Création des données de test
                Account testAccount = TestDataFactory.createTestAccount();
                Opportunity testOpportunity = TestDataFactory.createTestOpportunity(testAccount.Id);
                Product2 testProduct = TestDataFactory.createTestProduct();
                Id pricebookEntryId = TestDataFactory.createTestPricebookEntry(testProduct.Id);
                OpportunityLineItem oli = TestDataFactory.createTestOpportunityLineItem(testOpportunity.Id, pricebookEntryId);

                // Modifie la quantité pour tester la mise à jour
                oli.Quantity = 150.0;

                // Exécution de la méthode à tester
                Test.startTest();
                OpportunityProductController.updateOpportunityProduct(oli);
                Test.stopTest();

                // Vérification que la quantité en stock a été mise à jour
                Product2 updatedProduct = [SELECT QuantityInStock__c FROM Product2 WHERE Id = :testProduct.Id];
                System.assertEquals(150.0, updatedProduct.QuantityInStock__c, 'La quantité en stock devrait être mise à jour à 150.0.');
            } catch (Exception e) {
                System.debug('Exception dans testUpdateOpportunityProduct_success: ' + e.getMessage());
                System.assert(false, 'Une exception ne devrait pas être levée dans ce test.');
            }
        }
    }

    @isTest
    static void testUpdateOpportunityProduct_noAdmin() {
        // Crée un utilisateur de test avec un profil autre que "System Administrator"
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User standardUser = new User(
            Alias = 'suser',
            Email = 'standarduser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'StandardUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standardusertest@test.com'
        );
        insert standardUser;

        System.runAs(standardUser) {
            Test.startTest();
            try {
                OpportunityLineItem oli = new OpportunityLineItem();
                OpportunityProductController.updateOpportunityProduct(oli);
                System.assert(false, 'Exception should have been thrown due to non-admin user.');
            } catch (OpportunityProductController.CustomException e) {
                System.assertEquals('Seuls les utilisateurs ayant le profil "Administrateur Système" sont autorisés à effectuer cette modification. Si Vous souhaitez modifier la quantité en Stock, contactez votre Administrateur Système.', e.getMessage());
            }
            Test.stopTest();
        }
    }
 

    @isTest
    static void testUpdateOpportunityProduct_nullId() {
        // Crée un utilisateur de test avec le profil "System Administrator"
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User adminUser = new User(
            Alias = 'auser',
            Email = 'adminuser2@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'AdminUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'adminuser2test@test.com'
        );
        insert adminUser;
        
        System.runAs(adminUser) {
            Test.startTest();
            try {
                OpportunityLineItem oli = new OpportunityLineItem();
                OpportunityProductController.updateOpportunityProduct(oli);
                System.assert(false, 'Exception should have been thrown due to null OpportunityLineItem ID.');
            } catch (OpportunityProductController.CustomException e) {
                System.assertEquals('L\'ID de l\'Opportunity Line Item est requis pour la mise à jour.', e.getMessage());
            }
            Test.stopTest();
        }
    }
}
