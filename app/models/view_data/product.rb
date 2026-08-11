# frozen_string_literal: true

# This represent a read only Product value object, to be used in the view.
# `:variants` is an array of ViewData::Variant
ViewData::Product = Data.define(:id, :name, :description, :image, :images,
                                :properties_including_inherited, :variants)
