module HtmlHelper
  def strip_html(html)
    strip_tags(html).andand.gsub(/&nbsp;/i, ' ').andand.gsub(/&amp;/i, '&')
  end
end
