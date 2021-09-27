process.env.NODE_ENV = process.env.NODE_ENV || "development"

const environment = require("./environment")

// Trigger recompile in dev when views change.
const chokidar = require("chokidar")
if (process.env.RAILS_ENV == "development") {
  environment.config.merge({
    devServer: {
      before: (app, server) => {
        chokidar.watch(
          [
            "app/views/**/*.html.erb",
            "app/views/**/*.html.haml",
            "app/components/**/*.html.haml",
            "app/assets/javascript/templates/**/*.html.haml",
            "engines/**/*.html.haml",
          ],
          { awaitWriteFinish: true }
        ).on("change", () => server.sockWrite(server.sockets, "content-changed"))
      }
    }
  })  
}

module.exports = environment.toWebpackConfig()
