# DON'T USE DIRECTLY - for inheritance
attributes :name, :id

child :taxons => :taxons do
  attributes :name, :id
end

child :address do
  extends "json/partials/address"
end
