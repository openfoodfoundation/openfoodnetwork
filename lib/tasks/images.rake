# frozen_string_literal: true

namespace :images do
  # Images can be lost for several reasons, for example:
  #
  # - file loss on disk
  # - failed upload
  # - file loss on bucket
  # - file loss when changing storage
  #
  # If we can't recover the image, we should delete the record in the database
  # as well. Otherwise operations like regenerating thumbnails will try to
  # find those images every time which costs time and bandwidth.
  task delete_orphans: :environment do
    puts "To identify orphaned images, update the metadata first:"
    puts ""
    puts "  bundle exec rake paperclip:refresh:metadata CLASS=Spree::Image"
    puts ""

    orphaned_images = Spree::Image.where(attachment_file_size: 0)
    total = Spree::Image.count
    really_delete_images = ENV.fetch("DELETE_IMAGES", false)

    if really_delete_images
      puts "Deleting #{orphaned_images.count} out of #{total} images!"
      [3, 2, 1].each do |i|
        print "#{i} "
        sleep 1
      end
      puts ""
      deleted = orphaned_images.delete_all
      puts "Done. #{deleted} image records were deleted."
    else
      puts "Found #{orphaned_images.count} out of #{total} images could be deleted."
      puts "Set environment variable DELETE_IMAGES=true to delete them."
    end
  end

  task reset_styles: :environment do
    klass = Paperclip::Task.obtain_class
    names = Paperclip::Task.obtain_attachments(klass)
    styles = obtain_styles

    names.each do |name|
      Kernel.const_get(klass).attachment_definitions[name][:styles] = styles
    end
  end

  desc "Regenerates thumbnails for a given CLASS (and optional ATTACHMENT and STYLES splitted by comma)."
  task regenerate_thumbnails: :environment do
    klass = Paperclip::Task.obtain_class
    names = Paperclip::Task.obtain_attachments(klass)
    styles = (ENV['STYLES'] || ENV['styles'] || '').split(',').map(&:to_sym)
    names.each do |name|
      Paperclip.each_instance_with_attachment(klass, name) do |instance|
        instance.send(name).reprocess!(*styles)
        unless instance.errors.blank?
          puts "errors while processing #{klass} ID #{instance.id}:"
          puts " " + instance.errors.full_messages.join("\n ") + "\n"
        end
      end
    end
  end

  desc "Restyle thumbnails for a future deployment."
  task restyle: ["images:reset_styles", "paperclip:refresh:thumbnails"]

  def obtain_styles
    # Env var STYLES is used by paperclip for a list of styles.
    # Choosing a different name for a hash of style definitions here.
    styles = ENV.fetch("STYLE_DEFS") do
      raise 'Must specify styles like STYLE_DEFS=\'{"small":["227x227#","jpg"]}\''
    end

    Spree::Image.format_styles(JSON.parse(styles))
  end
end
