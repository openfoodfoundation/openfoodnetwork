import "controllers";
import "swiper/css/bundle";
import "../js/turbo";
import "../js/hotkeys";
import "../js/cable_ready_responses";
import "../js/matomo";
import "../js/moment";

require.context("../fonts", true);
const images = require.context("../images", true);
const imagePath = (name) => images(name, true);
