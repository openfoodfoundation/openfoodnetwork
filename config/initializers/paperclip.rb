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
