module GroupsHelper

  def link_to_ext(url)
    link_to strip_url(url), ext_url(url), target: '_blank'
  end

  def ext_url(url)
    if (url =~ /^https?:\/\//i)
      return url
    else
      return 'http://' + url
    end
  end

  def strip_url(url)
    url.andand.sub(/^https?:\/\//i, '')
  end

end
