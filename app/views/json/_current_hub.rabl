object current_distributor
extends 'json/partials/enterprise'

child suppliers: :producers do
  attributes :id
end
