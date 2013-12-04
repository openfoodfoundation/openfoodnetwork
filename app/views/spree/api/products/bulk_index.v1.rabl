collection @products.order('id ASC')
extends "spree/api/products/bulk_show"
attributes :variant_unit, :variant_unit_scale, :variant_unit_name