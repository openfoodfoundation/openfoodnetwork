object current_distributor
attributes :name, :id

child suppliers: :producers do
  extends "json/producer"
end
