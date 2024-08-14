import { LightningElement, api, wire, track } from 'lwc';
import getOpportunityLineItems from '@salesforce/apex/OpportunityProductController.getOpportunityLineItems';

export default class OpportunityProductTable extends LightningElement {
    @api recordId;

    @track columns = [
        { label: 'Nom du produit', fieldName: 'productName', type: 'text' },
        { label: 'Prix unitaire', fieldName: 'unitPrice', type: 'currency' },
        { label: 'Prix Total', fieldName: 'totalPrice', type: 'currency' },
        { label: 'Quantité', fieldName: 'quantity', type: 'number' },
        { label: 'Quantité en Stock', fieldName: 'quantityInStock', type: 'number' }
    ];

    @track products;

    @wire(getOpportunityLineItems, { opportunityId: '$recordId' })
wiredOpportunityProducts({ error, data }) {
    if (data) {
        // S'assurer que products est undefined si data est vide pour activer le template if:false
        this.products = data.length > 0 ? data : undefined;
        this.error = undefined;
    } else if (error) {
        this.error = error;
        this.products = undefined;
        console.error('Error loading opportunity line items:', error);
    }
}
}
