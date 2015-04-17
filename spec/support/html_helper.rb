module OpenFoodNetwork
  module HtmlHelper
    def save_and_open(html)
      require "launchy"
      file = Tempfile.new('html')
      file.write html
      Launchy.open(file.path)
    end
  end
end
