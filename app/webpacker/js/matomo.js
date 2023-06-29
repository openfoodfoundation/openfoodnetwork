// Call Matomo on asynchronous page loads
["turbo:load", "ujs:afterMorph"].forEach((listener) =>
  document.addEventListener(listener, (event) => {
    if (typeof event?.detail?.timing === "object" && Object.keys(event?.detail?.timing).length === 0) {
      return;
    }

    window._mtm?.push({ "event": "mtm.PageView" });
  })
);
