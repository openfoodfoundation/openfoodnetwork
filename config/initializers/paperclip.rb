Paperclip::Attachment.default_options[:source_file_options] = {
  all: "-auto-orient"
}

url_adapters = [
  "Paperclip::UriAdapter",
  "Paperclip::HttpUrlProxyAdapter",
  "Paperclip::DataUriAdapter"
]

# Remove Paperclip URL adapters from registered handlers
Paperclip.io_adapters.registered_handlers.delete_if do |_proc, adapter_class|
  url_adapters.include? adapter_class.to_s
end

if Paperclip::VERSION.to_f < 3.5
  if Rails::VERSION::MAJOR > 4
    # Patches an error for missing method #silence_stream with Rails 5.0
    # Can be removed after Paperclip is upgraded to 3.5+
    module Paperclip
      class GeometryDetector
        def silence_stream(_stream, &block)
          yield
        end
      end
    end
  end
else
  Rails.logger.warn "The Paperclip::GeometryDetector patch can now be removed."
end

module UpdatedUrlGenerator
  def escape_url(url)
    (url.respond_to?(:escape) ? url.escape : URI::Parser.new.escape(url)).
      gsub(/(\/.+)\?(.+\.)/, '\1%3F\2')
  end
end

Paperclip::UrlGenerator.prepend(UpdatedUrlGenerator)
