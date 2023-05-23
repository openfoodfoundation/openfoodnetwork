import "controllers";
import "@hotwired/turbo";
import "../js/mrujs";
import "../js/matomo";
import "../js/moment";

require.context("../fonts", true);
const images = require.context("../images", true);
const imagePath = (name) => images(name, true);
