module.exports = function (api) {
  const defaultConfigFunc = require("shakapacker/package/babel/preset.js");
  const resultConfig = defaultConfigFunc(api);

  return resultConfig;
};
