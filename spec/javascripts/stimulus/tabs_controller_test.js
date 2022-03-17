/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import tabs_controller from "../../../app/webpacker/controllers/tabs_controller";

describe("TabsController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("tabs", tabs_controller);
  });

  describe("#select", () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <div data-controller="tabs">
          <button data-tabs-target="tab" data-action="click->tabs#select">Dogs</button>
          <button data-tabs-target="tab" data-action="click->tabs#select">Cats</button>
          <button data-tabs-target="tab" data-action="click->tabs#select">Birds</button>

          <div class="content-area" data-tabs-target="content" >
            Dogs content
          </div>
          <div class="content-area" data-tabs-target="content" >
            Cats content
          </div>
          <div class="content-area" data-tabs-target="content" >
            Birds content
          </div>
        </div>
      `;
    });

    it("shows the corresponding content when a tab button is clicked", () => {
      const dogs_button = document.querySelectorAll('button')[0];
      const cats_button = document.querySelectorAll('button')[1];
      const birds_button = document.querySelectorAll('button')[2];
      const dogs_content = document.querySelectorAll('.content-area')[0];
      const cats_content = document.querySelectorAll('.content-area')[1];
      const birds_content = document.querySelectorAll('.content-area')[2];

      expect(dogs_content.hidden).toBe(false);
      expect(cats_content.hidden).toBe(true);
      expect(birds_content.hidden).toBe(true);

      expect(document.querySelectorAll('button.active').length).toBe(1);
      expect(document.querySelectorAll('button.active')[0]).toBe(dogs_button);

      birds_button.click();

      expect(dogs_content.hidden).toBe(true);
      expect(cats_content.hidden).toBe(true);
      expect(birds_content.hidden).toBe(false);

      expect(document.querySelectorAll('button.active').length).toBe(1);
      expect(document.querySelectorAll('button.active')[0]).toBe(birds_button);

      cats_button.click();

      expect(dogs_content.hidden).toBe(true);
      expect(cats_content.hidden).toBe(false);
      expect(birds_content.hidden).toBe(true);

      expect(document.querySelectorAll('button.active').length).toBe(1);
      expect(document.querySelectorAll('button.active')[0]).toBe(cats_button);
    });
  });
});
