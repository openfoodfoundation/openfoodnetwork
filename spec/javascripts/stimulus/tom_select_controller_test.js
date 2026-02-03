/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import { fireEvent, waitFor } from "@testing-library/dom";
import tom_select_controller from "controllers/tom_select_controller";
import showHttpError from "js/services/show_http_error";

jest.mock("js/services/show_http_error", () => ({
  __esModule: true,
  default: jest.fn(),
}));

/* ------------------------------------------------------------------
 * Helpers
 * ------------------------------------------------------------------ */

const buildResults = (count, start = 1) =>
  Array.from({ length: count }, (_, i) => ({
    value: String(start + i),
    label: `Option ${start + i}`,
  }));

const setupDOM = (html) => {
  document.body.innerHTML = html;
};

const getSelect = () => document.getElementById("select");
const getTomSelect = () => getSelect().tomselect;

const openDropdown = () => fireEvent.click(document.getElementById("select-ts-control"));

const mockRemoteFetch = (...responses) => {
  responses.forEach((response) => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => response,
    });
  });
};

const mockDropdownScroll = (
  dropdown,
  { scrollHeight = 1000, clientHeight = 300, scrollTop = 700 } = {},
) => {
  Object.defineProperty(dropdown, "scrollHeight", {
    configurable: true,
    value: scrollHeight,
  });

  Object.defineProperty(dropdown, "clientHeight", {
    configurable: true,
    value: clientHeight,
  });

  Object.defineProperty(dropdown, "scrollTop", {
    configurable: true,
    writable: true,
    value: scrollTop,
  });

  fireEvent.scroll(dropdown);
};

/* ------------------------------------------------------------------
 * Expectation helpers
 * ------------------------------------------------------------------ */

const expectOptionsCount = (count) => {
  expect(document.querySelectorAll('.ts-dropdown-content [role="option"]').length).toBe(count);
};

const expectDropdownToContain = (text) => {
  expect(document.querySelector(".ts-dropdown-content")?.textContent).toContain(text);
};

const expectDropdownWithNoResults = () => {
  expect(document.querySelector(".ts-dropdown-content")?.textContent).toBe("No results found");
};


/* ------------------------------------------------------------------
 * Specs
 * ------------------------------------------------------------------ */

describe("TomSelectController", () => {
  let application;

  beforeAll(() => {
    application = Application.start();
    application.register("tom-select", tom_select_controller);
  });

  beforeEach(() => {
    global.fetch = jest.fn();
    global.I18n = { t: (key) => key };
  });

  afterEach(() => {
    document.body.innerHTML = "";
    jest.clearAllMocks();
  });

  describe("connect()", () => {
    beforeEach(() => {
      setupDOM(`
        <select id="select" data-controller="tom-select">
          <option value="">Default Option</option>
          <option value="1">Option 1</option>
          <option value="2">Option 2</option>
        </select>
      `);
    });

    it("initializes TomSelect with default options", () => {
      const settings = getTomSelect().settings;

      expect(settings.placeholder).toBe("Default Option");
      expect(settings.maxItems).toBe(1);
      expect(settings.plugins).toEqual(["dropdown_input"]);
      expect(settings.allowEmptyOption).toBe(true);
    });
  });

  describe("connect() with custom values", () => {
    beforeEach(() => {
      setupDOM(`
        <select
          id="select"
          data-controller="tom-select"
          data-tom-select-placeholder-value="Choose an option"
          data-tom-select-options-value='{"maxItems": 3, "plugins": ["remove_button"]}'
        >
          <option value="1">Option 1</option>
          <option value="2">Option 2</option>
        </select>
      `);
    });

    it("applies custom placeholder and options", () => {
      const settings = getTomSelect().settings;

      expect(settings.placeholder).toBe("Choose an option");
      expect(settings.maxItems).toBe(3);
      expect(settings.plugins).toEqual(["remove_button"]);
    });
  });

  describe("connect() with remoteUrl", () => {
    beforeEach(() => {
      setupDOM(`
        <select
          id="select"
          data-controller="tom-select"
          data-tom-select-options-value='{"plugins":["virtual_scroll"]}'
          data-tom-select-remote-url-value="https://ofn-tests.com/api/search"
        ></select>
      `);
    });

    it("configures remote loading callbacks", () => {
      const settings = getTomSelect().settings;

      expect(settings.valueField).toBe("value");
      expect(settings.labelField).toBe("label");
      expect(settings.searchField).toBe("label");
      expect(settings.load).toEqual(expect.any(Function));
      expect(settings.firstUrl).toEqual(expect.any(Function));
      expect(settings.onFocus).toEqual(expect.any(Function));
    });

    it("fetches page 1 on focus", async () => {
      mockRemoteFetch({
        results: buildResults(1),
        pagination: { more: false },
      });

      openDropdown();

      await waitFor(() => expect(fetch).toHaveBeenCalledTimes(1));

      expect(fetch).toHaveBeenCalledWith(expect.stringContaining("q=&page=1"));

      await waitFor(() => {
        expectOptionsCount(1);
        expectDropdownToContain("Option 1");
      });
    });

    it("fetches remote options using search query", async () => {
      const appleOption = { value: "apple", label: "Apple" };
      mockRemoteFetch({
        results: [...buildResults(1), appleOption],
        pagination: { more: false },
      });

      openDropdown();

      await waitFor(() => {
        expectOptionsCount(2);
      });

      mockRemoteFetch({
        results: [appleOption],
        pagination: { more: false },
      });

      fireEvent.input(document.getElementById("select-ts-control"), {
        target: { value: "apple" },
      });

      await waitFor(() =>
        expect(fetch).toHaveBeenCalledWith(expect.stringContaining("q=apple&page=1")),
      );

      await waitFor(() => {
        expectOptionsCount(1);
        expectDropdownToContain("Apple");
      });
    });

    it("loads next page on scroll (infinite scroll)", async () => {
      mockRemoteFetch(
        {
          results: buildResults(30),
          pagination: { more: true },
        },
        {
          results: buildResults(1, 31),
          pagination: { more: false },
        },
      );

      openDropdown();

      await waitFor(() => {
        expectOptionsCount(30);
      });

      const dropdown = document.querySelector(".ts-dropdown-content");
      mockDropdownScroll(dropdown);

      await waitFor(() => {
        expectOptionsCount(31);
      });

      expect(fetch).toHaveBeenCalledTimes(2);
    });

    it("handles fetch errors gracefully", async () => {
      fetch.mockRejectedValueOnce(new Error("Fetch error"));

      openDropdown();

      await waitFor(() => {
        expectDropdownWithNoResults();
      });

      expect(showHttpError).not.toHaveBeenCalled();
    });

    it("displays HTTP error on failure", async () => {
      fetch.mockResolvedValueOnce({
        ok: false,
        status: 500,
        json: async () => ({}),
      });

      openDropdown();

      await waitFor(() => {
        expect(showHttpError).toHaveBeenCalledWith(500);
      });

      expectDropdownWithNoResults();
    });

    it("controls loading behavior based on user interaction", () => {
      const settings = getTomSelect().settings;

      // Initial state: openedByClick is false, query is empty
      expect(settings.shouldLoad("")).toBe(false);

      // Simulating opening the dropdown
      settings.onDropdownOpen();
      expect(settings.shouldLoad("")).toBe(true);

      // Simulating typing
      settings.onType();
      expect(settings.shouldLoad("")).toBe(false);

      // Query present
      expect(settings.shouldLoad("a")).toBe(true);
    });
  });
});
