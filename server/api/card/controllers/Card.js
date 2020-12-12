'use strict';

require('dotenv').config();
const stripe = require('stripe')(process.env.STRIPE_KEY);

/**
 * A set of functions called "actions" for `Card`
 */

module.exports = {
   index: async (ctx, next) => {
     try {
       const customerId = ctx.request.querystring;
       const cardData = await stripe.paymentMethods.list({customer: customerId, type: 'card'});

       ctx.send(cardData);
     } catch (err) {
       ctx.status = err.statusCode || err.status || 500
       ctx.body = 'Stripe Err: customer id is wrong or data corrupt.';
     }
   },
   add: async (ctx, next) => {
     try {
       const {customer, source} = ctx.request.body;
       const card = await stripe.paymentMethods.attach(source,{customer});

       ctx.send(card);
     } catch (err) {
       ctx.status = err.statusCode || err.status || 500
       ctx.body = 'Stripe Err: Could not add card.';
     }
   }
};
