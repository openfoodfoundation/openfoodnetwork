import { Controller } from "stimulus";

export default class extends Controller {
  static values = {
    url: String,
  };

  connect() {
    // Wait for jQuery and select2 to be available
    if (typeof $ === "undefined" || typeof $.fn.select2 === "undefined") {
      console.error("Select2 AJAX Controller: jQuery or Select2 not loaded");
      return;
    }

    const $element = $(this.element);

    // Skip if already initialized
    if ($element.hasClass("select2-hidden-accessible")) {
      return;
    }

    const ajaxUrl = this.urlValue;

    if (!ajaxUrl) {
      console.warn("Select2 AJAX: No URL provided");
      return;
    }

    // Store original select element details
    const selectName = this.element.name;
    const selectId = this.element.id;
    const isMultiple = this.element.multiple;

    // Get selected values to pre-populate
    const selectedValues = $element.val() || [];

    // Create a hidden input to replace the select
    const $hiddenInput = $('<input type="hidden" />');
    $hiddenInput.attr("name", selectName);
    $hiddenInput.attr("id", selectId);
    if (isMultiple) {
      $hiddenInput.attr("multiple", "multiple");
    }

    // Replace select with hidden input
    $element.replaceWith($hiddenInput);

    const select2Options = {
      ajax: {
        url: ajaxUrl,
        dataType: "json",
        quietMillis: 500,
        data: function (term, page) {
          return {
            q: term || "",
            page: page || 1,
          };
        },
        results: function (data, _page) {
          return {
            results: data.results || [],
            more: (data.pagination && data.pagination.more) || false,
          };
        },
      },
      allowClear: true,
      minimumInputLength: 0,
      multiple: isMultiple,
      width: "100%",
      formatResult: function (item) {
        return item.text;
      },
      formatSelection: function (item) {
        return item.text;
      },
    };

    // Initialize Select2 on the hidden input
    $hiddenInput.select2(select2Options);

    // Store reference to the new element
    this.select2Element = $hiddenInput[0];

    // Pre-populate selected values if any
    if (selectedValues && selectedValues.length > 0) {
      $hiddenInput.val(selectedValues).trigger("change.select2");
    }
  }

  disconnect() {
    // Clean up the select2 element we created
    if (this.select2Element) {
      const $element = $(this.select2Element);
      if ($element.hasClass("select2-hidden-accessible")) {
        $element.select2("destroy");
      }
    }
  }
}
