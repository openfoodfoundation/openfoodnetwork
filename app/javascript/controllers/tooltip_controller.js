import { Controller } from "stimulus";
import { computePosition, offset, arrow } from "@floating-ui/dom";

export default class extends Controller {
  static targets = ["element", "tooltip", "arrow"];
  static values = {
    placement: {
      type: String,
      default: "top",
    },
  };

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

  showTooltip() {
    this.tooltipTarget.style.display = "block";
    this.update();
  }

  hideTooltip() {
    this.tooltipTarget.style.display = "";
  }
}
