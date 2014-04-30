# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

# -- Spree
unless Spree::Country.find_by_name 'Australia'
  puts "[db:seed] Seeding Spree"
  Spree::Core::Engine.load_seed if defined?(Spree::Core)
  Spree::Auth::Engine.load_seed if defined?(Spree::Auth)
end

# -- Landing page images
unless LandingPageImage.find_by_photo_file_name("potatoes.jpg")
  LandingPageImage.create photo: File.open(File.join(Rails.root, "lib", "seed_data", "carrots.jpg"))
  LandingPageImage.create photo: File.open(File.join(Rails.root, "lib", "seed_data", "tomatoes.jpg"))
  LandingPageImage.create photo: File.open(File.join(Rails.root, "lib", "seed_data", "potatoes.jpg"))
end

