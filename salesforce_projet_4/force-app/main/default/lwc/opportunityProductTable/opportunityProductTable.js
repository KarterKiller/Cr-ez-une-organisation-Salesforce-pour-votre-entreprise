import { LightningElement, api, wire, track } from 'lwc';
import getOpportunityLineItems from '@salesforce/apex/OpportunityProductController.getOpportunityLineItems';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class OpportunityProductTable extends NavigationMixin(LightningElement) {
    @api recordId;
    @track hasNegativeQuantity = false;

    @track columns = [
        { label: 'Product Name', fieldName: 'productName', type: 'text' },
        { label: 'Unit Price', fieldName: 'unitPrice', type: 'currency' },
        { label: 'Total Price', fieldName: 'totalPrice', type: 'currency' },
        { 
            label: 'Quantity', 
            fieldName: 'quantity', 
            type: 'number',
            cellAttributes: {
                style: { fieldName: 'quantityStyle' },
                alignment: 'right'
            }
        },
        { label: 'Quantity In Stock', fieldName: 'quantityInStock', type: 'number' },
        {
            label: 'Voir Produit',
            type: 'button',
            typeAttributes: {
                label: 'Voir',
                name: 'view',
                iconName: 'utility:preview',
                iconPosition: 'left',
                variant: 'brand'
            }
        },
        {
            label: 'Supprimer',
            type: 'button-icon',
            typeAttributes: {
                iconName: 'utility:delete',
                name: 'delete',
                variant: 'bare',
                alternativeText: 'Supprimer',
                title: 'Supprimer'
            }
        }
    ];

    @track products = null;  // Initial state, null to indicate loading
    @track isProductListEmpty = false;
    @track hasProducts = false;  // New variable to track if there are products
    
    @wire(getOpportunityLineItems, { opportunityId: '$recordId' })
    wiredOpportunityProducts({ error, data }) {
        if (data) {
            this.products = data.map(item => {
                const stockDifference = item.quantityInStock - item.quantity;
    
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
            this.hasProducts = this.products.length > 0;  // Check if there are any products
            this.isProductListEmpty = !this.hasProducts;  // Inverse of hasProducts
        } else if (error) {
            this.error = error;
            this.products = [];
            this.isProductListEmpty = true;
            this.hasProducts = false;  // No products in case of an error
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        console.log('Action Name:', actionName);  // Vérifie le nom de l'action
        console.log('Row Data:', row);  // Vérifie les données de la ligne

    
        switch (actionName) {
            case 'view':
                console.log('Navigating to product:', row.productId);  //  log pour vérifier l'appel de la méthode
                this.navigateToProduct(row.productId);
                break;
            case 'delete':
                this.deleteProduct(row.productId);
                break;
            default:
                break;
        }
    }
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
    deleteProduct(productId) {
        deleteRecord(productId)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Product deleted',
                        variant: 'success'
                    })
                );
                return refreshApex(this.products);
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
}
