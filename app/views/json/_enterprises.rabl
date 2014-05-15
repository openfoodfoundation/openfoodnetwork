# DON'T USE DIRECTLY - for inheritance
attributes :name, :id, :description

child :address do
  extends "json/partials/address"
end
