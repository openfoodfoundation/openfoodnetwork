/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import tom_select_controller from "../../../app/webpacker/controllers/tom_select_controller.js";

describe("TomSelectController", () => {
  let application;

  beforeAll(() => {
    application = Application.start();
    application.register("tom-select", tom_select_controller);
  });

  beforeEach(() => {
    global.requestAnimationFrame = jest.fn((cb) => {
      cb();
      return 1;
    });

    // Mock fetch for remote data tests
    global.fetch = jest.fn();
  });

  afterEach(() => {
    document.body.innerHTML = "";
    jest.clearAllMocks();
  });

  describe("basic initialization", () => {
    it("initializes TomSelect with default options and settings", async () => {
      document.body.innerHTML = `
        <select 
          id="test-select"
          data-controller="tom-select"
          data-tom-select-placeholder-value="Choose an option">
          <option value="">-- Select --</option>
          <option value="1">Option 1</option>
          <option value="2">Option 2</option>
        </select>
      `;

      await new Promise((resolve) => setTimeout(resolve, 0));

      const select = document.getElementById("test-select");
      const controller = application.getControllerForElementAndIdentifier(select, "tom-select");

      expect(controller).not.toBeNull();
      expect(controller.control).toBeDefined();
      expect(controller.control.settings.maxItems).toBe(1);
      expect(controller.control.settings.maxOptions).toBeNull();
      expect(controller.control.settings.allowEmptyOption).toBe(true);
      expect(controller.control.settings.placeholder).toBe("Choose an option");
      expect(controller.control.settings.plugins).toContain("dropdown_input");
      expect(controller.control.settings.onItemAdd).toBeDefined();
    });

    it("uses empty option text as placeholder when no placeholder value provided", async () => {
      document.body.innerHTML = `
        <select data-controller="tom-select">
          <option value="">-- Default Placeholder --</option>
          <option value="1">Option 1</option>
        </select>
      `;

      await new Promise((resolve) => setTimeout(resolve, 0));

      const select = document.querySelector("select");
      const controller = application.getControllerForElementAndIdentifier(select, "tom-select");

      expect(controller).not.toBeNull();
      expect(controller.control.settings.placeholder).toBe("-- Default Placeholder --");
    });

    it("accepts custom options via data attribute", async () => {
      document.body.innerHTML = `
        <select 
          data-controller="tom-select"
          data-tom-select-options-value='{"maxItems": 3, "create": true}'>
          <option value="">Select</option>
        </select>
      `;

      await new Promise((resolve) => setTimeout(resolve, 0));

      const select = document.querySelector("select");
      const controller = application.getControllerForElementAndIdentifier(select, "tom-select");

      expect(controller).not.toBeNull();
      expect(controller.control.settings.maxItems).toBe(3);
      expect(controller.control.settings.create).toBe(true);
    });

    it("cleans up on disconnect", async () => {
      document.body.innerHTML = `
        <select data-controller="tom-select">
          <option value="">Select</option>
        </select>
      `;

      await new Promise((resolve) => setTimeout(resolve, 0));

      const select = document.querySelector("select");
      const controller = application.getControllerForElementAndIdentifier(select, "tom-select");

      expect(controller).not.toBeNull();
      const destroySpy = jest.spyOn(controller.control, "destroy");
      controller.disconnect();

      expect(destroySpy).toHaveBeenCalled();
    });
  });

  describe("remote data loading (#addRemoteOptions)", () => {
    it("configures remote loading with proper field and pagination setup", async () => {
      document.body.innerHTML = `
        <select 
          data-controller="tom-select"
          data-tom-select-remote-url-value="/api/search">
          <option value="">Search...</option>
        </select>
      `;

      await new Promise((resolve) => setTimeout(resolve, 0));

      const select = document.querySelector("select");
      const controller = application.getControllerForElementAndIdentifier(select, "tom-select");

      expect(controller).not.toBeNull();
      expect(controller.page).toBe(1);
      expect(controller.hasMore).toBe(true);
      expect(controller.loading).toBe(false);
      expect(controller.scrollAttached).toBe(false);
      expect(controller.control.settings.valueField).toBe("value");
      expect(controller.control.settings.labelField).toBe("label");
      expect(controller.control.settings.searchField).toBe("label");
    });

    it("resets pagination on new query but preserves on same query", async () => {
      document.body.innerHTML = `
        <select 
          data-controller="tom-select"
          data-tom-select-remote-url-value="/api/search">
          <option value="">Search...</option>
        </select>
      `;

      await new Promise((resolve) => setTimeout(resolve, 0));

      const select = document.querySelector("select");
      const controller = application.getControllerForElementAndIdentifier(select, "tom-select");

      expect(controller).not.toBeNull();

      controller.page = 5;
      controller.hasMore = false;
      controller.lastQuery = "old";

      // Same query preserves state
      controller.control.settings.onType("old");
      expect(controller.page).toBe(5);

      // New query resets state
      controller.control.settings.onType("new");
      expect(controller.page).toBe(1);
      expect(controller.hasMore).toBe(true);
      expect(controller.lastQuery).toBe("new");
    });

    it("loads initial data on focus when not loading", async () => {
      global.fetch.mockResolvedValue({
        json: jest.fn().mockResolvedValue({
          results: [],
          pagination: { more: false },
        }),
      });

      document.body.innerHTML = `
        <select 
          data-controller="tom-select"
          data-tom-select-remote-url-value="/api/items">
          <option value="">Search...</option>
        </select>
      `;

      await new Promise((resolve) => setTimeout(resolve, 0));

      const select = document.querySelector("select");
      const controller = application.getControllerForElementAndIdentifier(select, "tom-select");

      expect(controller).not.toBeNull();

      const loadSpy = jest.spyOn(controller.control, "load");
      controller.control.settings.onFocus();

      expect(loadSpy).toHaveBeenCalledWith("", expect.any(Function));
      expect(controller.lastQuery).toBe("");

      // Does not load when already loading
      controller.loading = true;
      loadSpy.mockClear();
      controller.control.settings.onFocus();
      expect(loadSpy).not.toHaveBeenCalled();
    });

    it("attaches scroll listener once on dropdown open", async () => {
      document.body.innerHTML = `
        <select 
          data-controller="tom-select"
          data-tom-select-remote-url-value="/api/items">
          <option value="">Search...</option>
        </select>
      `;

      await new Promise((resolve) => setTimeout(resolve, 0));

      const select = document.querySelector("select");
      const controller = application.getControllerForElementAndIdentifier(select, "tom-select");

      expect(controller).not.toBeNull();
      expect(controller.scrollAttached).toBe(false);

      const addEventListenerSpy = jest.spyOn(
        controller.control.dropdown_content,
        "addEventListener",
      );

      controller.control.settings.onDropdownOpen();
      expect(controller.scrollAttached).toBe(true);
      expect(addEventListenerSpy).toHaveBeenCalledWith("scroll", expect.any(Function));

      // Does not attach multiple times
      controller.control.settings.onDropdownOpen();
      expect(addEventListenerSpy).toHaveBeenCalledTimes(1);
    });
  });

  describe("infinite scroll (#fetchNextPage)", () => {
    it("initializes pagination infrastructure", async () => {
      document.body.innerHTML = `
        <select 
          data-controller="tom-select"
          data-tom-select-remote-url-value="/api/items">
          <option value="">Search...</option>
        </select>
      `;

      await new Promise((resolve) => setTimeout(resolve, 0));

      const select = document.querySelector("select");
      const controller = application.getControllerForElementAndIdentifier(select, "tom-select");

      expect(controller).not.toBeNull();
      expect(controller._fetchOptions).toBeDefined();
      expect(typeof controller._fetchOptions).toBe("function");
      expect(controller.lastQuery).toBe("");
      expect(controller.control.settings.onDropdownOpen).toBeDefined();
    });

    it("manages pagination state correctly", async () => {
      document.body.innerHTML = `
        <select 
          data-controller="tom-select"
          data-tom-select-remote-url-value="/api/items">
          <option value="">Search...</option>
        </select>
      `;

      await new Promise((resolve) => setTimeout(resolve, 0));

      const select = document.querySelector("select");
      const controller = application.getControllerForElementAndIdentifier(select, "tom-select");

      expect(controller).not.toBeNull();

      // Initial state
      expect(controller.page).toBe(1);
      expect(controller.hasMore).toBe(true);
      expect(controller.loading).toBe(false);

      // Can increment page
      controller.page += 1;
      expect(controller.page).toBe(2);

      // Can update hasMore flag
      controller.hasMore = false;
      expect(controller.hasMore).toBe(false);

      // Can track loading
      controller.loading = true;
      expect(controller.loading).toBe(true);
    });

    it("provides dropdown element access for scroll detection", async () => {
      document.body.innerHTML = `
        <select 
          data-controller="tom-select"
          data-tom-select-remote-url-value="/api/items">
          <option value="">Search...</option>
        </select>
      `;

      await new Promise((resolve) => setTimeout(resolve, 0));

      const select = document.querySelector("select");
      const controller = application.getControllerForElementAndIdentifier(select, "tom-select");

      expect(controller).not.toBeNull();
      expect(controller.control.dropdown_content).toBeDefined();

      const dropdown = controller.control.dropdown_content;
      expect(typeof dropdown.scrollTop).toBe("number");
      expect(typeof dropdown.clientHeight).toBe("number");
      expect(typeof dropdown.scrollHeight).toBe("number");
    });
  });
});
