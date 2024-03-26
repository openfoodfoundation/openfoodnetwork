# frozen_string_literal: true

namespace :ofn do
  namespace :import do
    desc "Importing images for products from CSV"
    task :product_images, [:filename] => [:environment] do |_task, args|
      puts "Warning: use only with trusted URLs. This script will download whatever it can, " \
           "including local secrets, and expose the file as an image file."

      raise "Filename required" if args[:filename].blank?

      columns = %i[producer name image_url].freeze

      csv = CSV.read(args[:filename], headers: true, header_converters: :symbol)
      raise "CSV columns reqired: #{columns.map(&:to_s)}" if (columns - csv.headers).present?

      csv.each.with_index do |entry, index|
        puts "#{index} #{entry[:producer]}, #{entry[:name]}"
        enterprise = Enterprise.find_by! name: entry[:producer]

        product = Spree::Product.where(supplier: enterprise,
                                       name: entry[:name],
                                       deleted_at: nil).first
        if product.nil?
          puts " product not found."
          next
        end

        if product.image.nil?
          ImageImporter.new.import(entry[:image_url], product)
          puts " image added."
        else
          # image = product.images.first
          # image.update(attachment: entry[:image_url])
          puts " image exists, not updated."
        end
      end
    end
  end
end
