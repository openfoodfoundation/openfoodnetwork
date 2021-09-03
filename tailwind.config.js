const plugin = require("tailwindcss/plugin");

module.exports = {
  purge: {
    enabled: true,
    content: [
      "./app/views/**/*.html.haml",
      "./app/assets/javascript/templates**/*.js",
    ],
  },
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {},
  },
  variants: {
    extend: {},
  },
  plugins: [
    plugin(function ({ addBase, theme }) {
      addBase({
        img: { display: "inline-block" },
      });
    }),
  ],
};
