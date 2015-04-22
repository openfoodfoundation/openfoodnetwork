#!/usr/bin/env ruby

Spree::Config.use_s3 = false
Spree::PaymentMethod.update_all environment: 'development'
