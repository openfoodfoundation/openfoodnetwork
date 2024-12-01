# frozen_string_literal: true

# rails g migration AddSubjectToSemanticLinks subject:references{polymorphic}
#
# We want to add links to Exchanges as well as Variants.
# The word subject comes from the triple structure of the Semantic Web:
#
#   Subject predicate object (variant has linke URL)
class AddSubjectToSemanticLinks < ActiveRecord::Migration[7.0]
  def change
    # We allow `null` until we filled the new columns with existing data.
    add_reference :semantic_links, :subject, polymorphic: true, null: true
  end
end
