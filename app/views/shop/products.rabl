collection @products
attributes :id, :name, :permalink, :count_on_hand, :on_demand, :group_buy
node do |product|
  {
    notes: strip_tags(product.notes),
    description: strip_tags(product.description),
    price: product.master.price_with_fees(current_distributor, current_order_cycle) 
  }
end

child :supplier => :supplier do
  attributes :id, :name, :description
end

child :master => :master do
  attributes :id, :is_master, :count_on_hand, :options_text, :count_on_hand, :on_demand
  child :images => :images do
    attributes :id, :alt
    node do |img|
      {:small_url => img.attachment.url(:small, false)}
    end
  end
end

child :variants => :variants do |variant|
  attributes :id, :is_master, :count_on_hand, :options_text, :count_on_hand, :on_demand, :group_buy
  node do |variant|
    {
      price: variant.price_with_fees(current_distributor, current_order_cycle)  
    }
  end
  child :images => :images do
    attributes :id, :alt
    node do |img|
      {:small_url => img.attachment.url(:small, false)}
    end
  end
end

child :taxons => :taxons do |taxon|
  attributes :name 
end

child :properties => :properties do |property|
  attributes :name, :presentation 
end
