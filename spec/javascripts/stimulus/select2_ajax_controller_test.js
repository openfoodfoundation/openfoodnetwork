/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import select2_ajax_controller from "../../../app/webpacker/controllers/select2_ajax_controller.js";

describe("Select2AjaxController", () => {
  let select2InitOptions = null;
  let application;

  beforeAll(() => {
    application = Application.start();
    application.register("select2-ajax", select2_ajax_controller);
  });

  beforeEach(() => {
    select2InitOptions = null;

    // Mock jQuery and select2
    const mockVal = jest.fn(function (value) {
      if (value !== undefined) {
        this._value = value;
        return this;
      }
      return this._value || "";
    });

    const mockOn = jest.fn().mockReturnThis();

    const mockSelect2 = jest.fn(function (options) {
      if (typeof options === "string" && options === "destroy") {
        return this;
      }
      select2InitOptions = options;
      return this;
    });

    const jQueryMock = jest.fn((selector) => {
      let element;
      if (typeof selector === "string" && selector.startsWith("<input")) {
        element = document.createElement("input");
        element.type = "hidden";
      } else {
        element = selector;
      }

      const jqObject = {
        val: mockVal,
        trigger: jest.fn().mockReturnThis(),
        select2: mockSelect2,
        hasClass: jest.fn().mockReturnValue(false),
        attr: jest.fn(function (name, value) {
          if (value !== undefined && element) {
            element.setAttribute(name, value);
          }
          return this;
        }),
        on: mockOn,
        0: element,
        _value: "",
      };

      return jqObject;
    });

    jQueryMock.fn = { select2: jest.fn() };
    global.$ = jQueryMock;

    document.body.innerHTML = `
      <select 
        id="test-select" 
        name="test_name[]"
        data-controller="select2-ajax" 
        data-select2-ajax-url-value="/api/search">
        <option value="">Select...</option>
      </select>
    `;
  });

  afterEach(() => {
    document.body.innerHTML = "";
    delete global.$;
  });

  describe("#connect", () => {
    it("initializes select2 with correct AJAX URL", () => {
      expect(select2InitOptions).not.toBeNull();
      expect(select2InitOptions.ajax.url).toBe("/api/search");
    });

    it("configures select2 with correct options", () => {
      expect(select2InitOptions.ajax.dataType).toBe("json");
      expect(select2InitOptions.ajax.quietMillis).toBe(300);
      expect(select2InitOptions.allowClear).toBe(true);
      expect(select2InitOptions.minimumInputLength).toBe(0);
      expect(select2InitOptions.width).toBe("100%");
    });

    it("configures AJAX data function", () => {
      const dataFunc = select2InitOptions.ajax.data;
      const result = dataFunc("search term", 2);

      expect(result).toEqual({
        q: "search term",
        page: 2,
      });
    });

    it("handles empty search term", () => {
      const dataFunc = select2InitOptions.ajax.data;
      const result = dataFunc(null, null);

      expect(result).toEqual({
        q: "",
        page: 1,
      });
    });

    it("configures results function with pagination", () => {
      const resultsFunc = select2InitOptions.ajax.results;
      const mockData = {
        results: [{ id: 1, text: "Item 1" }],
        pagination: { more: true },
      };

      const result = resultsFunc(mockData, 1);

      expect(result).toEqual({
        results: mockData.results,
        more: true,
      });
    });

    it("handles missing pagination", () => {
      const resultsFunc = select2InitOptions.ajax.results;
      const mockData = {
        results: [{ id: 1, text: "Item 1" }],
      };

      const result = resultsFunc(mockData, 1);

      expect(result).toEqual({
        results: mockData.results,
        more: false,
      });
    });

    it("configures format functions", () => {
      const item = { id: 1, text: "Test Item" };

      expect(select2InitOptions.formatResult(item)).toBe("Test Item");
      expect(select2InitOptions.formatSelection(item)).toBe("Test Item");
    });
  });
});
