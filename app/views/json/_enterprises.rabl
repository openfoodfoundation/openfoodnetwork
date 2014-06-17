# DON'T USE DIRECTLY - for inheritance
attributes :name, :id, :description

node :email do |enterprise|
  enterprise.email.to_s.reverse
end

child :address do
  extends "json/partials/address"
end

node :path do |enterprise|
  shop_enterprise_path(enterprise) 
end

node :hash do |enterprise|
  enterprise.to_param
end
