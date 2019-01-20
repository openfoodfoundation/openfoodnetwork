module Features
  module DatepickerHelper
    def choose_today_from_datepicker
      within(".ui-datepicker-calendar") do
        find(".ui-datepicker-today").click
      end
    end
  end
end
