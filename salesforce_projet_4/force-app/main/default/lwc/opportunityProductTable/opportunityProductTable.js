import { LightningElement, api, wire, track } from 'lwc';
import getOpportunityLineItems from '@salesforce/apex/OpportunityProductController.getOpportunityLineItems';
import isUserCommercial from '@salesforce/apex/OpportunityProductController.isUserCommercial';
import deleteOpportunityLineItemAndProduct from '@salesforce/apex/OpportunityProductController.deleteOpportunityLineItemAndProduct';
import updateOpportunityProduct from '@salesforce/apex/OpportunityProductController.updateOpportunityProduct';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import LINE_QUANTITY_PROBLEM from '@salesforce/label/c.lineQuantityproblem';
import PRICE_BOOK_AND_ADD_PRODUCT from '@salesforce/label/c.PricebookAndAddProduct';
import QUANTITY_IN_STOCK_LABEL from '@salesforce/label/c.quantityInStockLabel';
import UNIT_PRICE_LABEL from '@salesforce/label/c.UnitPriceLabel';
import TOTAL_PRICE_LABEL from '@salesforce/label/c.TotalPriceLabel';
import SEE_PRODUCT_LABEL from '@salesforce/label/c.SeeProductLabel';
import PRODUCT_NAME_LABEL from '@salesforce/label/c.ProductNameLabel';
import DELETE_LABEL from '@salesforce/label/c.DeleteLabel';
import OPPORTUNITY_PRODUCTS_LABEL from '@salesforce/label/c.opportunityProductsLabel';
import QUANTITY_LABEL from '@salesforce/label/c.QuantityLabel';
import VIEW_PRODUCT_BUTTON from '@salesforce/label/c.ViewProductButton';

export default class OpportunityProductTable extends NavigationMixin(LightningElement) {
    // Custom Labels
    label = {
        lineQuantityProblem: LINE_QUANTITY_PROBLEM,
        PricebookAndAddProduct: PRICE_BOOK_AND_ADD_PRODUCT,
        quantityInStockLabel: QUANTITY_IN_STOCK_LABEL,
        QuantityLabel: QUANTITY_LABEL,
        UnitPriceLabel: UNIT_PRICE_LABEL,
        TotalPriceLabel: TOTAL_PRICE_LABEL,
        SeeProductLabel: SEE_PRODUCT_LABEL,
        ProductNameLabel: PRODUCT_NAME_LABEL,
        DeleteLabel: DELETE_LABEL,
        opportunityProductsLabel: OPPORTUNITY_PRODUCTS_LABEL,
        ViewProductButton: VIEW_PRODUCT_BUTTON
    };

    @api recordId; // Id de l'opportunité de laquelle on récupère les produits. @api permet de rendre cette variable accessible depuis les composants Lightning.
    @track hasNegativeQuantity = false; // 
    @track isCommercial = false; // Permet de savoir si l'utilisateur est commercial ou non
    @track draftValues = []; // Liste des valeurs de mise en ligne pour les produits
    @track products = null; // Liste des produits associés à l'opportunité
    @track isProductListEmpty = false; // Indique si la liste des produits est vide
    @track hasProducts = false; // Indique si la liste des produits est vide

    wiredOpportunityProductsResult; // Variable pour stocker le résultat de la requête d'apex
    
    get formattedLabel() {
        return `<strong style="color: black;">${this.label.PricebookAndAddProduct}</strong>`; 
    }
    // Liste des colonnes à afficher dans le tableau
    @track columns = [ 
        { label: this.label.ProductNameLabel, fieldName: 'productName', type: 'text' },
        { label: this.label.UnitPriceLabel, fieldName: 'unitPrice', type: 'currency' },
        { label: this.label.TotalPriceLabel, fieldName: 'totalPrice', type: 'currency' },
        { 
            label: this.label.QuantityLabel, 
            fieldName: 'quantity', 
            type: 'number',
            cellAttributes: {
                style: { fieldName: 'quantityStyle' },
                class: { fieldName: 'quantityClass' },
                alignment: 'right'
            }
        },
        { label: this.label.quantityInStockLabel, fieldName: 'quantityInStock', type: 'number', editable: true },
        {
            label: this.label.SeeProductLabel,
            type: 'button',
            typeAttributes: {
                label: this.label.ViewProductButton,
                name: 'view',
                iconName: 'utility:preview',
                iconPosition: 'left',
                variant: 'brand'
            }
        },
        {
            label: this.label.DeleteLabel,
            type: 'button-icon',
            typeAttributes: {
                iconName: 'utility:delete',
                name: 'delete',
                variant: 'bare',
                alternativeText: 'Delete',
                title: 'Delete'
            }
        }
    ];
    // Méthode pour initialiser les colonnes en fonction de l'utilisateur
    @wire(isUserCommercial)
    wiredIsCommercial({ error, data }) {
        if (data) {
            this.isCommercial = data;
            this.setColumns();
        } else if (error) {
            console.error('Error checking user profile:', error);
        }
    }
    // Méthode pour récupérer les produits associés à l'opportunité
    @wire(getOpportunityLineItems, { opportunityId: '$recordId' }) // Utilisation de la méthode getOpportunityLineItems de OpportunityProductController.cls
    wiredOpportunityProducts(result) { // Récupération du résultat de la requête d'apex
        this.wiredOpportunityProductsResult = result; // Stockez le résultat pour refreshApex
        if (result.data) {
            console.log('Data received:', result.data);
            this.products = result.data.map(item => {
                const stockDifference = item.quantityInStock - item.quantity;
                const quantityClass = stockDifference < 0 ? 'slds-box slds-theme_shade slds-theme_alert-texture' : ''; // Utilisation de la classe CSS pour mettre en évidence les produits en stock en rayures grises et blanches
                console.log('Stock Difference:', stockDifference);

                let quantityStyle = ''; 
                if (stockDifference < 0) {
                    quantityStyle = 'color: red; font-weight: bold;';
                    this.hasNegativeQuantity = true;
                } else {
                    quantityStyle = 'color: green; font-weight: bold;';
                }

                return {
                    ...item,
                    opportunityLineItemId: item.opportunityLineItemId, 
                    quantityStyle,
                    quantityClass
                };
            });
            this.hasProducts = this.products.length > 0; // Indique si la liste des produits est vide
            this.isProductListEmpty = !this.hasProducts; 
        } else if (result.error) {
            console.error('Error fetching opportunity line items:', result.error);
            this.error = result.error;
            this.products = []; 
            this.isProductListEmpty = true;
            this.hasProducts = false;
        }
    }
    // Méthode pour gérer les actions sur les lignes du tableau 
    handleRowAction(event) {
        const actionName = event.detail.action.name; 
        const row = event.detail.row;
        console.log('Action Name:', actionName);
        console.log('Row Data:', row);

        switch (actionName) {
            case 'view':
                console.log('Navigating to product:', row.opportunityLineItemId);
                this.navigateToProduct(row.opportunityLineItemId);
                break;
            case 'delete':
                this.deleteOpportunityLineItem(row.opportunityLineItemId);
                break;
            default:
                break;
        }
    }
    // Méthode pour naviguer vers la page de produit
    navigateToProduct(productId) { 
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: productId,
                objectApiName: 'Product2',
                actionName: 'view'
            }
        });
    }
    // Méthode pour supprimer un produit associé à une ligne de l'opportunité
    deleteOpportunityLineItem(opportunityLineItemId) {
        console.log('Deleting Opportunity Line Item with ID:', opportunityLineItemId);
        deleteOpportunityLineItemAndProduct({ opportunityLineItemId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Opportunity Line Item and associated Product deleted',
                        variant: 'success'
                    })
                );
                return refreshApex(this.wiredOpportunityProductsResult);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error deleting record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
    // Méthode pour gérer les changements de valeurs dans les cellules du tableau
    handleCellChange(event) {
        this.draftValues = event.detail.draftValues;
        console.log('Draft Values on cell change:', this.draftValues);  // Débogage
    }
    // Méthode pour enregistrer les changements de valeurs de mise en ligne après avoir cliquer sur le boutton save
    handleSave(event) {
        console.log('Save button clicked');
        const updatedFields = event.detail.draftValues; // Récupération des valeurs modifiées ds le tableau
        console.log('Updated Fields to Save:', updatedFields);

        if (updatedFields.length === 0) { // Vérifie si aucune modification n'a été faite (si updatedFields est vide). sinon la fonction handlesave s'arrete. 
            console.warn('No changes to save.');
            return;
        }

        const fieldsWithId = updatedFields.map(field => ({ // On crée une nouvelle liste avec les champs avec l'ID
            ...field,
            Id: field.opportunityLineItemId,  // Utilisation du champ correct pour l'ID
            Quantity: field.quantityInStock   // Envoie de la nouvelle quantité à Apex
        })).filter(item => item.Id);

        console.log('Fields with IDs:', fieldsWithId);

        if (fieldsWithId.length === 0) {
            console.error('No valid Ids found for update.');
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'No valid Ids found for update.',
                    variant: 'error'
                })
            );
            return;
        }
        // On envoie les champs avec l'ID à la méthode updateOpportunityProduct de OpportunityProductController.cls
        updateOpportunityProduct({ opportunityLineItem: fieldsWithId[0] })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Quantity In Stock updated successfully.',
                        variant: 'success'
                    })
                );
                this.draftValues = [];
                return refreshApex(this.wiredOpportunityProductsResult);  // Rafraîchit les données après mise à jour
            })
            .catch(error => {
                console.error('Error updating record:', error);
                const errorMessage = error.body ? error.body.message : JSON.stringify(error);
                console.log('Complete Error Message:', errorMessage);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: errorMessage,
                        variant: 'error'
                    })
                );
            });
    }
    // Méthode pour définir les colonnes en fonction de l'utilisateur
    setColumns() {
        if (this.isCommercial) {
            this.columns = this.columns.filter(column => column.label !== this.label.SeeProductLabel);
        }
    }
}