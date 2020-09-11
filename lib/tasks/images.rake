# frozen_string_literal: true

namespace :images do
  task reset_styles: :environment do
    klass = Paperclip::Task.obtain_class
    names = Paperclip::Task.obtain_attachments(klass)
    styles = obtain_styles

    names.each do |name|
      Kernel.const_get(klass).attachment_definitions[name][:styles] = styles
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
