collection @products
attributes :id, :name, :description, :price, :permalink, :count_on_hand, :on_demand, :group_buy

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
  attributes :id, :is_master, :price, :count_on_hand, :options_text, :count_on_hand, :on_demand, :group_buy
  child :images => :images do
    attributes :id, :alt
    node do |img|
      {:small_url => img.attachment.url(:small, false)}
    end
  end
end

