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

  // Simulate a click on the first available submit button. This seems to be the most robust option,
  // ensuring that event handlers are handled first (eg for StimulusReflex). If there's no submit
  // button, nothing happens (eg for Angular forms).
  const submit = form && form.querySelector('input[type="submit"], button[type="submit"]');
  submit && submit.click();
});
