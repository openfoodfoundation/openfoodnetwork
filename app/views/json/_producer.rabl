attributes :id, :name, :description, :long_description, :website, :instagram, :facebook, :linkedin, :twitter

node :promo_image do |producer| 
  producer.promo_image(:large) 
end
node :logo do |producer| 
  producer.logo(:medium) 
end

node :path do |producer|
  main_app.producer_path(producer) 
end

node :hash do |producer|
  producer.to_param
end
