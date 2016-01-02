class CreateLandingPageImages < ActiveRecord::Migration
  def change
    create_table :landing_page_images, &:timestamps
  end
end
