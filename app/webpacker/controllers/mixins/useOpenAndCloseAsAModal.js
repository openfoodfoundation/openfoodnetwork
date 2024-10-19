export const useOpenAndCloseAsAModal = (controller) => {
  Object.assign(controller, {
    open: function () {
      this.backgroundTarget.style.display = "block";
      this.modalTarget.style.display = "block";
      let modalOpen = new Event('modal-open', { bubbles: true });

      setTimeout(() => {
        this.modalTarget.classList.add("in");
        this.backgroundTarget.classList.add("in");
        document.querySelector("body").classList.add("modal-open");
        this.element.dispatchEvent(modalOpen);
      });
    }.bind(controller),

    close: function (_event, remove = false) {
      // Only execute close if there is an open modal
      if (!document.querySelector("body").classList.contains('modal-open')) return;

      this.modalTarget.classList.remove("in");
      this.backgroundTarget.classList.remove("in");
      let modalClose = new Event('modal-close', { bubbles: true });
      document.querySelector("body").classList.remove("modal-open");

      setTimeout(() => {
        this.backgroundTarget.style.display = "none";
        this.modalTarget.style.display = "none";
        this.element.dispatchEvent(modalClose)
        if (remove) { this.element.remove() }
      }, 200);
    }.bind(controller),

    closeIfEscapeKey: function (e) {
      if (e.code == "Escape") {
        this.close();
      }
    }.bind(controller),
  });
};
