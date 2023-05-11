import "controllers";
import "@hotwired/turbo";
import "../js/mrujs";

require.context("../fonts", true);
const images = require.context("../images", true);
const imagePath = (name) => images(name, true);
