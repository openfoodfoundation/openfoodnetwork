class DropLandingPageImages < ActiveRecord::Migration
  def up
    drop_table :landing_page_images
  end

  def down
    create_table :landing_page_images do |t|
      t.string :photo_file_name
      t.string :photo_content_type
      t.integer :photo_file_size
      t.datetime :photo_updated_at

      t.timestamps
    end
  end
end
