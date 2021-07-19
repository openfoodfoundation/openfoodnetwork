const railsWebpackEnv = require("../config/webpack/development");

module.exports = {
  stories: ["../spec/components/stories/**/*.stories.json"],
  addons: ["@storybook/addon-docs", "@storybook/addon-controls"],
  webpackFinal: async (config) => {
    config.module.rules = [
      ...config.module.rules,
      ...railsWebpackEnv.module.rules,
    ];
    return config;
  },
};
