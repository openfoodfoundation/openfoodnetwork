/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import vertical_ellipsis_menu_controller from "../../../app/components/vertical_ellipsis_menu_component/vertical_ellipsis_menu_controller";

describe("VerticalEllipsisMenuController test", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("vertical-ellipsis-menu", vertical_ellipsis_menu_controller);
  });

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="vertical-ellipsis-menu" id="root">
        <div data-action="click->vertical-ellipsis-menu#toggle" id="button">...</div>
        <div data-vertical-ellipsis-menu-target="content" id="content">
          
        </div>
      </div>
    `;
    const button = document.getElementById("button");
    const content = document.getElementById("content");
  });

  it("add show class to content when toggle is called", () => {
    expect(content.classList.contains("show")).toBe(false);
    button.click();
    expect(content.classList.contains("show")).toBe(true);
  });

  it("remove show class from content when clicking button", () => {
    button.click();
    expect(content.classList.contains("show")).toBe(true);
    button.click();
    expect(content.classList.contains("show")).toBe(false);
  });

  it("remove show class from content when clicking outside", () => {
    button.click();
    expect(content.classList.contains("show")).toBe(true);
    document.body.click();
    expect(content.classList.contains("show")).toBe(false);
  });
});
