object @enterprise_relationship

attributes :parent_id, :child_id

node :parent_name do |enterprise_relationship|
  enterprise_relationship.parent.name
end

node :child_name do |enterprise_relationship|
  enterprise_relationship.child.name
end
