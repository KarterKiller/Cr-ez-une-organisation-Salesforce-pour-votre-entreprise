import { LightningElement, api, wire, track } from 'lwc';
import getOpportunityLineItems from '@salesforce/apex/OpportunityProductController.getOpportunityLineItems';
import isUserCommercial from '@salesforce/apex/OpportunityProductController.isUserCommercial';
import deleteOpportunityLineItemAndProduct from '@salesforce/apex/OpportunityProductController.deleteOpportunityLineItemAndProduct';
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
 
    @api recordId; // @Api décorateur rendant une propriété publique accessible depuis l'extérieur. expose les propriétés aux composants parents. 
    @track hasNegativeQuantity = false; // Décorateur rendant une propriété réactive. 
    @track isCommercial = false; // propriété réactive booléenne suivie

    get formattedLabel() {
        // balises HTML pour le style (gras et rouge)
        return `<strong style="color: red;">${this.label.PricebookAndAddProduct}</strong>`;

    }


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
                alignment: 'right'
            }
        },
        { label: this.label.quantityInStockLabel, fieldName: 'quantityInStock', type: 'number' },
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

    @track products = null;
    @track isProductListEmpty = false;
    @track hasProducts = false;

    // Vérification si l'utilisateur a le profil "Commercial"
    @wire(isUserCommercial)
    wiredIsCommercial({ error, data }) {
        if (data) {
            this.isCommercial = data;
            this.setColumns();
        } else if (error) {
            console.error('Error checking user profile:', error);
        }
    }

    // Récupération des lignes de produits afin d'y appliquer un style de couleur en fonction du résultat de l'opération. ( rouge ou vert)
    @wire(getOpportunityLineItems, { opportunityId: '$recordId' }) 
    wiredOpportunityProducts({ error, data }) {
        if (data) {
            console.log('Data received:', data);
            this.products = data.map(item => {
                const stockDifference = item.quantityInStock - item.quantity;
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
                    quantityStyle
                };
            });
            this.hasProducts = this.products.length > 0; 
            this.isProductListEmpty = !this.hasProducts;
        } else if (error) {
            console.error('Error fetching opportunity line items:', error);
            this.error = error; // en cas d"erreur, stock l'erreur dans this.error
            this.products = [];
            this.isProductListEmpty = true; // Si errror alors réinitialiser la liste des produits
            this.hasProducts = false;
        }
    }

    // Gestion des actions des boutons dans les lignes du tableau
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

    // Méthode de Navigation vers la page du produit spécifique à Salesforce. 
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

    // Suppression de l'OpportunityLineItem et du produit associé. 
    deleteOpportunityLineItem(opportunityLineItemId) {
        console.log('Deleting Opportunity Line Item with ID:', opportunityLineItemId);
        deleteOpportunityLineItemAndProduct({ opportunityLineItemId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Opportunity Line Item ans associated Product deleted',
                        variant: 'success'
                    })
                );
                return refreshApex(this.wiredOpportunityProducts); // Rafraichissement des données serveur avec @wire. Force la récupération des données. 
            })
            .catch(error => {
                this.dispatchEvent( // Méthode pour créer et déclencher un événement ShowToastEvent affichant le message d'erreur. 
                    new ShowToastEvent({
                        title: 'Error deleting record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }

    // Mise à jour des colonnes en fonction du profil de l'utilisateur
    setColumns() {
        if (this.isCommercial) {
            this.columns = this.columns.filter(column => column.label !== 'Voir Produit');
        }
    }
}
