'use strict';
require('dotenv').config();
const axios = require('axios');
const stripe = require('stripe')(process.env.STRIPE_KEY);
const { v4: uuid } = require('uuid');

/**
 * Order.js controller
 *
 * @description: A set of functions called "actions" for managing `Order`.
 */

module.exports = {

  /**
   * Retrieve order records.
   *
   * @return {Object|Array}
   */

  find: async (ctx, next, { populate } = {}) => {
    if (ctx.query._q) {
      return strapi.services.order.search(ctx.query);
    } else {
      return strapi.services.order.fetchAll(ctx.query, populate);
    }
  },

  /**
   * Retrieve a order record.
   *
   * @return {Object}
   */

  findOne: async (ctx) => {
    if (!ctx.params._id.match(/^[0-9a-fA-F]{24}$/)) {
      return ctx.notFound();
    }

    return strapi.services.order.fetch(ctx.params);
  },

  /**
   * Count order records.
   *
   * @return {Number}
   */

  count: async (ctx) => {
    return strapi.services.order.count(ctx.query);
  },

  /**
   * Create a/an order record.
   *
   * @return {Object}
   */

  create: async (ctx) => {
    const { amount, products, customer, source } = ctx.request.body
    const { email } = ctx.state.user;

    const charge = {
      amount: Number(amount) * 100,
      currency: 'usd',
      customer,
      payment_method: source,
      receipt_email: email
    };

    const idempotencyKey = uuid();

    const paymentIntent = await stripe.paymentIntents.create(charge, {
      idempotencyKey: idempotencyKey
    });

    await stripe.paymentIntents.confirm(
      paymentIntent.id,
      {payment_method: source}
    );

    return strapi.services.order.add({
      amount,
      products: JSON.parse(products),
      user: ctx.state.user
    });
  },

  /**
   * Update a/an order record.
   *
   * @return {Object}
   */

  update: async (ctx, next) => {
    return strapi.services.order.edit(ctx.params, ctx.request.body) ;
  },

  /**
   * Destroy a/an order record.
   *
   * @return {Object}
   */

  destroy: async (ctx, next) => {
    return strapi.services.order.remove(ctx.params);
  }
};
