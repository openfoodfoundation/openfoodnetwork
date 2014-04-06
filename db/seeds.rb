# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

# -- Spree
unless Spree::Country.find_by_name 'Australia'
  puts "[db:seed] Seeding Spree"
  Spree::Core::Engine.load_seed if defined?(Spree::Core)
  Spree::Auth::Engine.load_seed if defined?(Spree::Auth)
end

# -- States
unless Spree::State.find_by_name 'Victoria'
  country = Spree::Country.find_by_name('Australia')
  puts "[db:seed] Seeding states"

  [
   ['ACT', 'ACT'],
   ['New South Wales', 'NSW'],
   ['Northern Territory', 'NT'],
   ['Queensland', 'QLD'],
   ['South Australia', 'SA'],
   ['Tasmania', 'Tas'],
   ['Victoria', 'Vic'],
   ['Western Australia', 'WA']
  ].each do |state|
    Spree::State.create!({"name"=>state[0], "abbr"=>state[1], :country=>country}, :without_protection => true)
  end
end

# -- Landing page images
unless LandingPageImage.find_by_photo_file_name("potatoes.jpg")
  LandingPageImage.create photo: File.open(File.join(Rails.root, "lib", "seed_data", "carrots.jpg"))
  LandingPageImage.create photo: File.open(File.join(Rails.root, "lib", "seed_data", "tomatoes.jpg"))
  LandingPageImage.create photo: File.open(File.join(Rails.root, "lib", "seed_data", "potatoes.jpg"))
end

# -- Seeding suburbs
require File.expand_path('../suburb_seeds', __FILE__)
SuburbSeeder.seed_suburbs unless Suburb.find_by_name("Dayton")
