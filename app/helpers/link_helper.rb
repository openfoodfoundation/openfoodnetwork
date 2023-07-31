# frozen_string_literal: true

module LinkHelper
  def link_to_service(baseurl, name, html_options = {}, &)
    return if name.blank?

    html_options = html_options.merge target: '_blank'
    link_to(ext_url(baseurl, name), html_options, &)
  end

  def ext_url(prefix, url)
    if url =~ %r{^https?://}i
      url
    else
      prefix + url
    end
  end
end
