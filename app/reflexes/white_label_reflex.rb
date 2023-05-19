# frozen_string_literal: true

class WhiteLabelReflex < ApplicationReflex
  include EnterpriseConcern
  delegate :view_context, to: :controller

  def remove_logo
    @enterprise.update!(white_label_logo: nil)
    # delete the white_label_logo_link attribute as well since it has no meaning without the logo
    @enterprise.update!(white_label_logo_link: "")

    f = ActionView::Helpers::FormBuilder.new(:enterprise, @enterprise, view_context, {})

    html = with_locale {
      render(partial: "admin/enterprises/form/white_label",
             locals: { f: f, enterprise: @enterprise })
    }
    morph "#white_label_panel", html

    flash[:success] = with_locale {
      I18n.t("admin.enterprises.form.white_label.remove_logo_success")
    }
    cable_ready.dispatch_event(name: "modal:close")
    morph_admin_flashes
  end
end
