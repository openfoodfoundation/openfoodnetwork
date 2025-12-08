/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import FlatpickrController from "../../../app/webpacker/controllers/flatpickr_controller.js";

describe("FlatpickrController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("flatpickr", FlatpickrController);
  });

  describe("#importFlatpickrLocale", () => {
    describe("returns null to trigger flatpickr fallback to english", () => {
      test.each([
        ["when no base_locale is set", {}],
        ["when base_locale doesn't match a Flatpickr locale", { base_locale: "invalid-locale" }],
        ["when base_locale is 'en'", { base_locale: "en" }],
      ])("%s", async (_description, i18n) => {
        const controller = new FlatpickrController();
        const locale = await controller.importFlatpickrLocale(i18n.base_locale);
        expect(locale).toBeNull();
      });
    });

    it("returns locale object for a supported locale (fr)", async () => {
      const controller = new FlatpickrController();
      const locale = await controller.importFlatpickrLocale("fr");
      expect(locale).toBeInstanceOf(Object);
      expect(locale).toHaveProperty("weekAbbreviation");
      expect(locale.weekAbbreviation).toBe("Sem");
    });
  });
});
