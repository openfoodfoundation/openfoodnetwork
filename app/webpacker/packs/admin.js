import "controllers";
import "channels";
import "../js/turbo";
import "../js/hotkeys";
import "../js/mrujs";
import "../js/matomo";
import "../js/moment";

import bigDecimal from "js-big-decimal";
window.bigDecimal = bigDecimal;

import Trix from "trix";

document.addEventListener("trix-file-accept", (event) => {
  event.preventDefault();
});

