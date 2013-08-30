object @line_item
attributes :id, :quantity

node(:name) { |p| p.variant.name }
