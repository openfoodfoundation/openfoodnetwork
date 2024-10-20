import "controllers";
import "../js/turbo";
import "../js/hotkeys";
import "../js/ujs";
import "../js/matomo";
import "../js/moment";

require.context("../fonts", true);
const images = require.context("../images", true);
const imagePath = (name) => images(name, true);
