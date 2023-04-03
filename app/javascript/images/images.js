const images = require.context("./", true);
const imagePath = (name) => images(name, true);
