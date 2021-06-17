# frozen_string_literal: true

module MarkdownHelper
  def render_markdown(markdown)
    md ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML, no_intra_emphasis: true, tables: true,
                                                            autolink: true, superscript: true)
    md.render markdown
  end
end
