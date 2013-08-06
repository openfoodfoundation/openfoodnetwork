class CreateLandingPageImages < ActiveRecord::Migration
  def change
    create_table :landing_page_images do |t|
      t.timestamps
    end
  end
end
