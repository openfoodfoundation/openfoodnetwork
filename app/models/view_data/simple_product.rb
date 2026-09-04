# frozen_string_literal: true

# This represent a simple read only Product value object, it doesn't include related variants.
ViewData::SimpleProduct = Data.define(:id, :name)
