object current_distributor
attributes :name, :id

if current_distributor
  child suppliers: :producers do
    extends "json/producer"
  end
end
