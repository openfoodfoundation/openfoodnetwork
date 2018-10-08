class UpdateInstagramData < ActiveRecord::Migration
  def change
    enterprises = Enterprise.where("instagram like ?", "%instagram.com%")
    enterprises.each do |e|
      e.instagram = "@#{e.instagram.split('/').last}"
      e.save
    end
  end
end
