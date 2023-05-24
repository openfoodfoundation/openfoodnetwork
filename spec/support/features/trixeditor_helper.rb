# frozen_string_literal: true

module Features
  module TrixEditorHelper
    def fill_in_trix_editor(id, with:)
      find(:xpath, "//trix-editor[@input='#{id}']").click.set(with)
    end
  end
end
