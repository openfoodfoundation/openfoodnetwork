module MenuHelper
  def open_login_modal
    find(:link, text: "LOG IN").click
  end
end
