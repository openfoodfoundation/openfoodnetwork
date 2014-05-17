module HtmlHelper
  def strip_html(html)
    strip_surrounding_whitespace substitute_entities strip_tags add_linebreaks html
  end

  def substitute_entities(html)
    html.andand.gsub(/&nbsp;/i, ' ').andand.gsub(/&amp;/i, '&')
  end

  def add_linebreaks(html)
    # I know Cthulu is coming for me. Forgive me.
    # http://stackoverflow.com/a/1732454/2720566
    html.
      andand.gsub(/<\/h[^>]>|<\/p>|<\/div>/, "\\1\n\n").
      andand.gsub(/<br[^>]*>/, "\\1\n")
  end

  def strip_surrounding_whitespace(html)
    html.andand.strip
  end
end
