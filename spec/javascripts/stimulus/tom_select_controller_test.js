/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import { fireEvent, waitFor } from "@testing-library/dom";
import tom_select_controller from "controllers/tom_select_controller";

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

const expectEmptyDropdown = () => {
  expect(document.querySelector(".ts-dropdown-content")?.textContent).toBe("");
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
      fetch.mockRejectedValueOnce(new Error("Network error"));

      openDropdown();

      await waitFor(() => {
        expectEmptyDropdown();
      });
    });
  });
});
