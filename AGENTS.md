The Open Food Network is an online marketplace for local food.

## Tech stack

- Rails monolith (Ruby version in `.ruby-version`, Node in `.node-version`, Yarn 1).
  The Gemfile enforces the exact Ruby version.
- Postgres
- Redis
- Sidekiq (Background Jobs)
- Rspec (testing)

## Setup

Ruby, gems, Postgres, Redis, Node and Chrome are all needed for specs. Setup steps for
a typical machine are in `GETTING_STARTED.md`; `script/setup-debian` sets up Ubuntu
containers as well and checks for missing tools.

- Develop natively; the `Dockerfile` setup is too slow for active work and not maintained
- Start the dev server with `bundle exec foreman start`
- After pulling new code, run `bin/setup`


## Testing

- Run rails test with `bundle exec rspec`
- Run tests for a specific file with `bundle exec rspec spec/path/to_spec.rb`
- Run javascript test with `yarn jest`
- Run AngularJs test with karma 'script/karma run'
- Add or update tests for the code you change, even if nobody asked.
- Prefer **request specs** over controller specs. Don't test private methods via `send`.
  If no request can reach a branch, remove the dead code instead of testing it.
- Run RuboCop on changed files. Metrics cops are enforced: split classes/specs rather
  than adding to `.rubocop_todo.yml`.
- Lint changed files only:
  ```bash
  ./script/rubocop-diff.sh
  ```
  Use `-a` to autocorrect. It only checks uncommitted changes (diff against `HEAD`), so run it before committing.
  ```bash
  bundle exec haml-lint $(git diff --name-only --diff-filter=AM origin/master -- '*.haml')
  ```
- Check JavaScript formatting with `yarn prettier --check <files>` (use `--write` to fix)
- System specs run on **Cuprite** (Ferrum, Chrome DevTools protocol;
  `spec/system/support/cuprite_setup.rb`), not Selenium or chromedriver. `HEADLESS=false`
  shows the browser, and JS errors fail specs. Ferrum is already bundled: use it for
  ad-hoc headless-Chrome scripts instead of adding Puppeteer or Selenium.
- Karma uses ChromeHeadless: if it reports "No binary for ChromeHeadless", set
  `CHROME_BIN`. Grep its output for `FAILED`.

## Project structure

| Area | Location |
| --- | --- |
| Spree-derived core models/controllers | `app/models/spree/`, `app/controllers/spree/admin/`, `lib/spree/` |
| Services, queries, forms | `app/services/`, `app/queries/`, `app/forms/` |
| ViewComponents (new UI) | `app/components/<name>_component.rb` + sidecar dir `<name>_component/` (`.html.haml`, `.scss`, `_controller.js`) |
| Stimulus controllers | `app/webpacker/controllers/` (component controllers sit next to the component) |
| StimulusReflex | `app/reflexes/` |
| Webpack (Shakapacker) packs & SCSS | `app/webpacker/packs/`, `app/webpacker/css/{darkswarm,admin}/` |
| Legacy AngularJS / CoffeeScript (Sprockets) | `app/assets/javascripts/{darkswarm,admin,shared,templates}` |
| Engines (path gems) | `engines/{dfc_provider,order_management,catalog,web}` |
| DFC (Data Food Consortium) API | `engines/dfc_provider/` (+ `app/services/fdc_*`, `dfc_catalog_importer.rb`, `app/jobs/stock_sync_job.rb`) |
| Routes | `config/routes.rb` + `config/routes/{admin,api,spree,shopfront}.rb` (shopfront loads last) |
| Feature toggles (Flipper) | `lib/open_food_network/feature_toggle.rb`, `config/initializers/flipper.rb` |
| API v0 / v1 controllers (plain Rails, not Grape) | `app/controllers/api/{v0,v1}/` |
| API v1 schema / docs | `app/json_schemas/`, `swagger/` |
| Translations | `config/locales/en.yml` only (other locales sync via Transifex) |
| Specs | `spec/` (RSpec), `spec/javascripts/stimulus/` (Jest), `spec/javascripts/unit` (Karma, AngularJS) |


## Architecture notes and gotchas

- **Two frontends coexist.** The shopfront (`layouts/darkswarm`) and admin still use
  AngularJS in many places, with `data-turbo="false"` on `<body>`. New work uses
  ViewComponents + Stimulus + Turbo. Prefer the new stack; don't add AngularJS. 
  A `data-turbo-method` link also needs `data: { turbo: true }`, or it falls through to a plain GET
  (see `app/views/spree/admin/taxons/index.html.haml`). Don't put `data-turbo="true"` on
  a whole AngularJS form: Turbo Drive visits break the Angular app. Scope it to a frame.
- CableReady/StimulusReflex is slated for removal (reliability). For new work, prefer
  Turbo/Stimulus.
- `ViewData::*` objects are `Data` classes with required members; adding a member
  breaks every constructor (specs, `Admin::ProductPreviewController`).
- `lib/` is required, not autoloaded: restart the dev server after editing it.
- Many queries (`.or`, `SELECT DISTINCT`) have no `ORDER BY`. Specs comparing them
  with `eq([a, b])` or `.first` are flaky — use `match_array` / explicit records.
- DFC API auth (`AuthorizationControl`) resolves the user in this order: OIDC bearer
  JWT (verified against per-issuer public keys), OFN API token (`X-Api-Token`), then
  the Warden/Devise session. API docs are served at `/api-docs`.
- ActiveJob runs on Sidekiq; Redis is required in every environment.
- Reporting (`lib/reporting`) has its own Zeitwerk loader (the `ofn.reports`
  initializer in `config/application.rb`), separate from the main autoloader.
- Payment/shipping calculators (`Calculator::*`) are registered explicitly in
  `config/application.rb`, not auto-discovered: register new ones there.
- Turbo isn't loaded in Karma, so a `<turbo-frame>` there is a plain element: set its
  source from Angular with `setAttribute('src', url)`, not `frame.src =`.
- Toggles: use Flipper. `FeatureToggle.enabled?(:name)` with no actor is a global switch 
  that admins flip at `/admin/feature-toggle/features` without a redeploy.
  New features must be added to `CURRENT_FEATURES` (others are
  removed by `setup!`, and the spec `feature:` tag raises "Unkown feature"); to enable
  everywhere, add to `ACTIVE_BY_DEFAULT` plus a migration calling `Flipper.enable`. Cached partials
  must include toggle state in the cache key.
  Plain `ENV.fetch` is for infrastructure switches (Sidekiq schedule, Bullet). 
  In system specs enable one with `RSpec.describe ..., feature: :name`.
- Reuse existing constants/helpers; put logic in the right layer; prefer CSS over JS.
- i18n: lazy lookups (`t(".title")`) under a key named after the view/component
  (e.g. `components.add_to_cart.*`). `_html` suffix for markup. Change English wording
  rather than using CSS `text-transform`. Only edit `en.yml`.
- Accessibility: give controls `aria-label`s that name the item (e.g. "Add %{name} to
  cart"); specs then read naturally.
- Never edit an existing migration: add a new one
- Don't edit `vendor/`. 
- Read environment-specific config from ENV instead of hardcoding it.
- Don't define constants at the top level of spec files: they leak across the suite. Use
  local variables or `let`.

## Git

- Upstream is `openfoodfoundation/openfoodnetwork` (branch `master`). Contributors
  work on forks and open PRs against upstream `master`.
- One logical change per commit. Imperative subject (~50 chars, no prefix), body
  explains *why* (with numbers when relevant).
- Unrelated fixes go on separate branches / PRs.
- **Rebase, don't merge.** To fold a fix into an earlier commit:
  `git commit --fixup <sha>` then `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <base>`.
  Before rewriting, tag a backup (`git tag -f pre-rebase-backup`) and check
  `git diff pre-rebase-backup HEAD` / `git range-diff` afterwards. Push with
  `git push --force-with-lease=<branch>:<sha>`, only on your own branches.
- If the maintainer pushes to your branch, re-fetch before pushing; drop duplicate fixes.

### Pull requests

- Fill in `.github/PULL_REQUEST_TEMPLATE.md` (What? Why?, What should we test?,
  Release notes / changelog category, AI-written-code checkbox).
- "What should we test?" = numbered manual steps grouped by area, with exact URLs
  (e.g. `/admin/products`, `/admin/orders/bulk_management`) and what failure looks
  like (raw `{{ }}` / `$injector` errors for Angular, `NoMethodError`, ...).
- Confirm UI fixes in a browser: reproduce the bug, then show it fixed. Screenshots go in
  the PR description, never in the repo. GitHub only accepts image uploads through the
  web UI, so save them locally and ask the human to paste them in.
- CI runs **undercover**: methods touched by a PR need coverage. If a coverage report
  is provided, cover exactly the listed items.
- Use "Closes #N" only when the PR fixes the issue's reproduction, otherwise "Part of #N".
  Replace every template placeholder.
- Stacked work: still target `master`; list the base PR under "Dependencies" and say
  which commits are new.
- When later commits make the description stale, update it: `gh pr view N --json body`
  into a file, edit it, then `gh pr edit N --body-file`.
