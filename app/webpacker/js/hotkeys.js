import hotkeys from "hotkeys-js";

// Enable hotkeys on form elements
hotkeys.filter = function (event) {
  var tagName = (event.target || event.srcElement).tagName;
  hotkeys.setScope(/^(INPUT|TEXTAREA|SELECT|BUTTON)$/.test(tagName) ? "input" : "other");
  return true;
};

// Submit form
// Although 'enter' will submit the form in many cases, it doesn't cover elements such
// as select and textarea. This shortcut is a standard used across many major websites.
hotkeys("ctrl+enter, command+enter", function (event, handler) {
  const form = event.target.form;

  // If element has a non-angular form
  if (form && !form.classList.contains("ng")) {
    form.submit();
  }
});
