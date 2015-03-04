module GroupsHelper

  def link_to_service(baseurl, name, html_options = {})
    return if name.blank?
    html_options = html_options.merge target: '_blank'
    link_to ext_url(baseurl, name), html_options do
      yield
    end
  end

  def ext_url(prefix, url)
    if url =~ /^https?:\/\//i
      url
    else
      prefix + url
    end
  end

  def strip_url(url)
    url.andand.sub(/^https?:\/\//i, '')
  end

end
