class UpdateInstagramData < ActiveRecord::Migration
  def change
    Enterprise.where("instagram like ?", "%instagram.com%").find_each do |e|
      e.instagram = e.instagram.split('/').last
      e.save
    end
  end
end
