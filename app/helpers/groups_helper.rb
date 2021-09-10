# frozen_string_literal: true

module GroupsHelper
  def link_to_service(baseurl, name, html_options = {}, &block)
    return if name.blank?

    html_options = html_options.merge target: '_blank'
    link_to ext_url(baseurl, name), html_options, &block
  end

  def ext_url(prefix, url)
    if url =~ %r{^https?://}i
      url
    else
      prefix + url
    end
  end

  def strip_url(url)
    url&.sub(%r{^https?://}i, '')
  end
end
