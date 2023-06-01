import { Controller } from "stimulus";
import { computePosition, offset, arrow } from "@floating-ui/dom";

export default class extends Controller {
  static targets = ["element", "tooltip", "arrow"];
  static values = {
    tip: String,
    placement: { type: String, default: "top" },
  };

  connect() {
    if (this.hasTipValue) { this.insertToolTipMarkup() }

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

  insertToolTipMarkup() {
    let container = document.createElement("div");
    let tooltip = document.createElement("div");
    let arrow = document.createElement("div");
    let text = document.createTextNode(this.tipValue);

    container.classList.add("tooltip-container");
    tooltip.classList.add("tooltip");
    tooltip.setAttribute("data-tooltip-target", "tooltip");
    arrow.classList.add("arrow");
    arrow.setAttribute("data-tooltip-target", "arrow");

    container.appendChild(tooltip);
    tooltip.appendChild(text);
    tooltip.appendChild(arrow);

    this.elementTarget.appendChild(container);
  }
}
