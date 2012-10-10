module ApplicationHelper
  def cms_elrte_include_tags
    stylesheet_link_tag(     'comfortable_mexican_sofa/codemirror') +
      stylesheet_link_tag(   'comfortable_mexican_sofa/elrte') +
      javascript_include_tag('comfortable_mexican_sofa/application')
  end
end
