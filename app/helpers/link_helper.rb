# frozen_string_literal: true

module LinkHelper
  def link_to_or_disabled(name = nil, options = nil, html_options = nil, &block)
    html_options, options, name = options, name, block if block_given?
    html_options ||= {}

    if !!html_options.delete(:disabled)
      # https://www.scottohara.me/blog/2021/05/28/disabled-links.html
      html_options.merge!(
        'aria-disabled': true,
        class: (html_options[:class].to_s.split + ["disabled"]).uniq.join(" "),
        role: "link"
      )
      if block_given?
        content_tag("a", name, **html_options, &block)
      else
        content_tag("a", name, **html_options)
      end
    elsif block_given?
      link_to options, html_options, &block
    else
      link_to name, options, html_options
    end
  end

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

  def new_tab_option
    if feature?(:open_in_same_tab, spree_current_user)
      {}
    else
      { target: "_blank" }
    end
  end
end
