export const useOpenAndCloseAsAModal = (controller) => {
  Object.assign(controller, {
    open: function () {
      this.backgroundTarget.style.display = "block";
      this.modalTarget.style.display = "block";

      setTimeout(() => {
        this.modalTarget.classList.add("in");
        this.backgroundTarget.classList.add("in");
        document.querySelector("body").classList.add("modal-open");
      });
    }.bind(controller),

    close: function (_event, remove = false) {
      // displatch closing event so other controller can trigger action when the modal closes
      this.dispatch("closing");
      // Only execute close if the current modal is open
      if (!this.modalTarget.classList.contains("in")) return;

      this.modalTarget.classList.remove("in");
      this.backgroundTarget.classList.remove("in");
      document.querySelector("body").classList.remove("modal-open");

      setTimeout(() => {
        this.backgroundTarget.style.display = "none";
        this.modalTarget.style.display = "none";
        if (remove) {
          this.element.remove();
        }
      }, 200);
    }.bind(controller),

    closeIfEscapeKey: function (e) {
      if (e.code == "Escape") {
        this.close();
      }
    }.bind(controller),
  });
};
