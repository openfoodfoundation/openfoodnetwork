module.exports = {
  stories: ["../spec/components/stories/**/*.stories.json"],
  addons: [
    "@storybook/addon-docs",
    "@storybook/addon-controls",
    {
      name: "@storybook/addon-postcss",
      options: {
        postcssLoaderOptions: {
          implementation: require("postcss"),
        },
      },
    },
  ],
};
