const plugin = require("tailwindcss/plugin");

module.exports = {
  mode: "jit",
  purge: {
    enabled: true,
    content: [
      "./app/views/**/*.html.erb",
      "./app/views/**/*.html.haml",
      "./app/assets/javascript/templates/**/*.html.haml",
      "./engines/**/*.html.haml",
    ],
  },
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {},
  },
  variants: {
    extend: {},
  },
  corePlugins: {
    preflight: false,
  },
};
