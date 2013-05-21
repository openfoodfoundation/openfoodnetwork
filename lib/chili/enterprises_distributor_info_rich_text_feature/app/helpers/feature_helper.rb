module FeatureHelper
  def strip_html(html)
    strip_tags(html).gsub(/&nbsp;/i, ' ').gsub(/&amp;/i, '&')
  end
end
