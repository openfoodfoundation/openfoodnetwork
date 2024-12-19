# frozen_string_literal: true

module Features
  module DatepickerHelper
    def choose_today_from_datepicker
      within(".flatpickr-calendar.open") do
        find("button", text: "Today").click
      end
    end

    def select_dates_from_daterangepicker(from, to)
      # Once the datepicker is open,
      # it simply consist to select the 'from' date and then the 'to' date
      select_date_from_datepicker(from)
      select_date_from_datepicker(to)
    end

    def select_datetime_from(element, datetime)
      datetime = Time.zone.parse(datetime) if datetime.is_a? String

      # Wait for timepicker element to be loaded:
      expect(page).to have_css "#{element}.datetimepicker"

      find(element).click
      select_datetime_from_datepicker(datetime)
      close_datepicker
    end

    def select_date_from_datepicker(date)
      within ".flatpickr-calendar.open" do
        # Unfortunately, flatpickr doesn't notice a change of year when we do
        #
        #     fill_in "Year", with: date.year
        #
        # A working alternative is:
        find(".cur-year").send_keys(date.year.to_s)
        select date.strftime("%B"), from: "Month"

        aria_date = date.strftime("%B %-d, %Y")
        find("[aria-label='#{aria_date}']").click
      end
    end

    def select_datetime_from_datepicker(datetime)
      select_date_from_datepicker(datetime)
      fill_in "Hour", with: datetime.strftime("%H")
      fill_in "Minute", with: datetime.strftime("%M")

      # Flatpickr needs time to update the time.
      # Otherwise submitting the form may not work.
      # CI experimentation: 10ms ->   7% success
      #                     50ms ->  87% success
      #                    100ms -> 100% success in 112 runs
      # Let's double that to reduce flakiness even further.
      sleep 0.2
    end

    def pick_datetime(calendar_selector, datetime_selector)
      find(calendar_selector).click
      select_datetime_from_datepicker datetime_selector
      find("body").send_keys(:escape)
    end

    def close_datepicker
      within(".flatpickr-calendar.open") do
        click_button "Close"
      end
    end
  end
end
