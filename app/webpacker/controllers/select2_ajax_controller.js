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

    const ajaxUrl = this.urlValue;
    if (!ajaxUrl) return;

    const selectName = this.element.name;
    const selectId = this.element.id;
    const isMultiple = this.element.multiple;

    const container = document.createElement("div");
    container.dataset.select2HiddenContainer = "true";

    this.element.replaceWith(container);

    // select2 methods are accessible via jQuery
    // Plus, ajax calls with multi-select require a hidden input in select2
    const $select2Input = $('<input type="hidden" />');
    $select2Input.attr("id", selectId);
    container.appendChild($select2Input[0]);

    // IN-MEMORY cache to avoid repeated ajax calls for same query/page
    const ajaxCache = {};

    const select2Options = {
      ajax: {
        url: ajaxUrl,
        dataType: "json",
        quietMillis: 300,
        data: function (term, page) {
          return {
            q: term || "",
            page: page || 1,
          };
        },
        transport: function (params) {
          const term = params.data.q || "";
          const page = params.data.page || 1;
          const cacheKey = `${term}::${page}`;

          if (ajaxCache[cacheKey]) {
            params.success(ajaxCache[cacheKey]);
            return;
          }

          const request = $.ajax(params);

          request.then((data) => {
            ajaxCache[cacheKey] = data;
            params.success(data);
          });

          return request;
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
      formatResult: (item) => item.text,
      formatSelection: (item) => item.text,
    };

    // Initialize select2 with ajax options on hidden input
    $select2Input.select2(select2Options);

    // Rails-style array submission requires multiple hidden inputs with same name
    const syncHiddenInputs = (values) => {
      // remove old inputs
      container.querySelectorAll(`input[name="${selectName}"]`).forEach((e) => e.remove());

      values.forEach((value) => {
        const input = document.createElement("input");
        input.type = "hidden";
        input.name = selectName;
        input.value = value;
        container.appendChild(input);
      });
    };

    // On change → rebuild hidden inputs to submit filter values
    $select2Input.on("change", () => {
      const valuesString = $select2Input.val() || "";
      const values = valuesString.split(",") || [];

      syncHiddenInputs(Array.isArray(values) ? values : [values]);
    });
  }
}
