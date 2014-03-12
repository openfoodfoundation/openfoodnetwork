module HtmlHelper
  def strip_html(html)
    squeeze_linebreaks substitute_entities strip_tags add_linebreaks html
  end

  def substitute_entities(html)
    html.andand.gsub(/&nbsp;/i, ' ').andand.gsub(/&amp;/i, '&')
  end

  def add_linebreaks(html)
    # I know Cthulu is coming for me. Forgive me.
    # http://stackoverflow.com/a/1732454/2720566
    html.andand.gsub(/<\/h[^>]>|<br[^>]*>|<\/p>|<\/div>/, "\\1\n")
  end

  def squeeze_linebreaks(html)
    html.andand.squeeze "\n"
  end

end
