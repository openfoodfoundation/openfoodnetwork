import { Controller } from "stimulus";

export default class extends Controller {
  static values = {
    url: String,
  };

  connect() {
    if (typeof $ === "undefined" || typeof $.fn.select2 === "undefined") {
      console.error("Select2 AJAX Controller: jQuery or Select2 not loaded");
      return;
    }

    const $element = $(this.element);

    if ($element.hasClass("select2-hidden-accessible")) return;

    const ajaxUrl = this.urlValue;
    if (!ajaxUrl) return;

    const selectName = this.element.name; // e.g. supplier_id_in[]
    const selectId = this.element.id;
    const isMultiple = this.element.multiple;
    const selectedValues = $element.val() || [];

    const container = document.createElement("div");
    container.dataset.select2HiddenContainer = "true";

    this.element.replaceWith(container);

    const $select2Input = $('<input type="hidden" />');
    $select2Input.attr("id", selectId);
    container.appendChild($select2Input[0]);

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
      formatResult: item => item.text,
      formatSelection: item => item.text,
    };

    $select2Input.select2(select2Options);
    this.select2Element = $select2Input[0];

    // Rails-style array submission
    const syncHiddenInputs = values => {
      // remove old inputs
      container
        .querySelectorAll(`input[name="${selectName}"]`)
        .forEach(e => e.remove());

      values.forEach(value => {
        const input = document.createElement("input");
        input.type = "hidden";
        input.name = `${selectName}`;
        input.value = value;
        container.appendChild(input);
      });
    };

    // On change → rebuild hidden inputs
    $select2Input.on("change", () => {
      const valuesString = $select2Input.val() || "";
      const values = valuesString.split(',') || [];

      syncHiddenInputs(Array.isArray(values) ? values : [values]);
    });

    // Pre-populate
    if (selectedValues.length > 0) {
      $select2Input.val(selectedValues).trigger("change");
    }
  }

  disconnect() {
    if (this.select2Element) {
      const $el = $(this.select2Element);
      if ($el.hasClass("select2-hidden-accessible")) {
        $el.select2("destroy");
      }
    }
  }
}
