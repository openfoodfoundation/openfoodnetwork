import { Controller } from "stimulus";
import { computePosition, offset, arrow } from "@floating-ui/dom";

// This is meant to be used with the follwing html where element can be a
// "div", "a", "span" or "button", etc... :
//
//  <div data-controller="tooltip">
//    <element data-tooltip-target="element">
//    <div class="tooltip-container">
//      <div class="tooltip" data-tooltip-target="tooltip">
//        tooltip_text
//        <div class=arrow data-tooltip-target="arrow"></div>
//      </div>
//    </div>
//  </div>
//
//  You can also use this partial app/views/admin/shared/_tooltip.html.haml

export default class extends Controller {
  static targets = ["element", "tooltip", "arrow"];
  static values = {
    placement: { type: String, default: "top" },
  };

  connect() {
    this.elementTarget.addEventListener("mouseenter", this.showTooltip);
    this.elementTarget.addEventListener("mouseleave", this.hideTooltip);
  }

  disconnect() {
    this.elementTarget.removeEventListener("mouseenter", this.showTooltip);
    this.elementTarget.removeEventListener("mouseleave", this.hideTooltip);
  }

  update() {
    computePosition(this.elementTarget, this.tooltipTarget, {
      placement: this.placementValue,
      middleware: [offset(6), arrow({ element: this.arrowTarget })],
    }).then(({ x, y, placement, middlewareData }) => {
      Object.assign(this.tooltipTarget.style, {
        left: `${x}px`,
        top: `${y}px`,
      });
      const { x: arrowX, y: arrowY } = middlewareData.arrow;

      const staticSide = {
        top: "bottom",
        right: "left",
        bottom: "top",
        left: "right",
      }[placement.split("-")[0]];

      Object.assign(this.arrowTarget.style, {
        left: arrowX != null ? `${arrowX}px` : "",
        top: arrowY != null ? `${arrowY}px` : "",
        right: "",
        bottom: "",
        [staticSide]: "-4px",
      });
    });
  }

  showTooltip = () => {
    this.tooltipTarget.style.display = "block";
    this.update();
  };

  hideTooltip = () => {
    this.tooltipTarget.style.display = "";
  };
}
