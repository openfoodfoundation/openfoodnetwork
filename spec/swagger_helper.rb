# frozen_string_literal: true

require 'spec_helper'

RSpec.configure do |config|
  config.swagger_root = Rails.root.join('swagger').to_s
  config.swagger_docs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'The Open Food Network',
        description: 'This spec is auto generated using the rswag gem. It is incomplete and not yet valid for openapi 3.0.1. Do not publish this. \
Some endpoints are public and require no authorization; others require authorization. Talk to us to get your credentials set up. \
Check out our repo! https://github.com/openfoodfoundation/openfoodnetwork',
        version: '0.1',
      },
      components: {
        securitySchemes: {
          api_key: {
              type: :apiKey,
              name: 'X-Spree-Token',
              in: :header
          }
        },
        schemas: {
          Order_Concise: {
            type: 'object',
            properties: {
              id: { type: 'integer' },
              number: { type: 'string' },
              full_name: { type: 'string' },
              email: { type: 'string' },
              phone: { type: 'string' },
              completed_at: { type: 'string' },
              display_total: { type: 'string' },
              show_path: { type: 'string' },
              edit_path: { type: 'string' },
              state: { type: 'string' },
              payment_state: { type: 'string' },
              shipment_state: { type: 'string' },
              payments_path: { type: 'string' },
              shipments_path: { type: 'string' },
              ship_path: { type: 'string' },
              ready_to_ship: { type: 'string' },
              created_at: { type: 'string' },
              distributor_name: { type: 'string' },
              special_instructions: { type: 'string' },
              payment_capture_path: { type: 'string' },
              distributor: {
                type: 'object',
                properties: {
                  id: { type: 'integer' }
                }
              },
              order_cycle: {
                type: 'object',
                properties: {
                  id: { type: 'integer' }
                }
              }
            }
          }
        }
      },
      paths: {},
      servers: [
        {
          url: 'https://staging.katuma.org/api'
        }
      ]
    }
  }
  config.swagger_format = :yaml
end
