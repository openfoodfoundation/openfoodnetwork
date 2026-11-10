# AGENTS.md

Context for AI coding agents (and humans) contributing to Open Food Network.
It is distilled from many earlier agent sessions on this codebase. Read it before
starting; it should save you the first hour of every session.

See also: `GETTING_STARTED.md` (local setup), `CONTRIBUTING.md`,
`.github/PULL_REQUEST_TEMPLATE.md`.

## Repository at a glance

- Rails monolith (Ruby version in `.ruby-version`, Node in `.node-version`, Yarn 1).
  Postgres + Redis. The Gemfile enforces the exact Ruby version.
- Upstream is `openfoodfoundation/openfoodnetwork` (branch `master`). Contributors
  work on forks and open PRs against upstream `master`.
- Gems come from `https://gem.coop` (see `Gemfile`), not rubygems.org.

### Where things live

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
| API v1 schema / docs | `app/json_schemas/`, `swagger/` |
| Translations | `config/locales/en.yml` only (other locales sync via Transifex) |
| Specs | `spec/` (RSpec), `spec/javascripts/stimulus/` (Jest), `spec/javascripts/unit` (Karma, AngularJS) |

### Architecture notes and gotchas

- **Two frontends coexist.** The shopfront (`layouts/darkswarm`) and admin still use
  AngularJS in many places, with `data-turbo="false"` on `<body>`. New work uses
  ViewComponents + Stimulus + Turbo (+ CableReady/StimulusReflex). Prefer the new
  stack; don't add AngularJS.
- In component templates call view helpers via `helpers.foo`, not `foo`.
- Feature toggles: `feature?(:name, user_or_enterprise)`. In system specs enable one
  with `RSpec.describe ..., feature: :name`. Cached partials must include toggle state
  in the cache key. Notable toggles: `inventory` vs `variant_tag` (legacy Inventory /
  VariantOverride being replaced), `product_grid_view` (new shopfront).
- Turbo requests via the CableReady bridge put `text/vnd.cable-ready.json` first in
  `Accept`: check `request.formats`, not `request.format`.
- `ViewData::*` objects are `Data` classes with required members; adding a member
  breaks every constructor (specs, `Admin::ProductPreviewController`).
- Shop CSS styles every bare `button` and has global rules in `css/darkswarm/`. A
  top-level selector in shop SCSS can leak into unrelated pages; scope it. Importing
  shop SCSS into `admin/all.scss` clashes variables — use `meta.load-css` scoped.
- Rich text fields (e.g. `product.description`) are sanitised on write; don't make
  model readers `html_safe`.
- `lib/` is required, not autoloaded: restart the dev server after editing it.
- DFC stock semantics: empty `stockLimitation` = unlimited (on demand); FDC uses `-1`.
- Many queries (`.or`, `SELECT DISTINCT`) have no `ORDER BY`. Specs comparing them
  with `eq([a, b])` or `.first` are flaky — use `match_array` / explicit records.
- Engines: `catalog`, `order_management` and `web` hold their domains; each engine
  is isolated with `isolate_namespace` in `engines/<name>/lib/<name>/engine.rb`. New
  engines are added as path gems in the `Gemfile`. See the wiki page "How OFN is
  organized in Domains using Rails Engines" (linked from each engine's README).
- DFC API auth (`AuthorizationControl`) resolves the user in this order: OIDC bearer
  JWT (verified against per-issuer public keys), OFN API token (`X-Api-Token`), then
  the Warden/Devise session. API docs are served at `/api-docs`.
- ActiveJob runs on Sidekiq; Redis is required in every environment.
- Reporting (`lib/reporting`) has its own Zeitwerk loader (the `ofn.reports`
  initializer in `config/application.rb`), separate from the main autoloader.
- Payment/shipping calculators (`Calculator::*`) are registered explicitly in
  `config/application.rb`, not auto-discovered: register new ones there.

## Conventions

### Code

- Run RuboCop on changed files. Metrics cops are enforced: split classes/specs rather
  than adding to `.rubocop_todo.yml`.
- Prefer **request specs** over controller specs. Don't test private methods via `send`.
  If no request can reach a branch, remove the dead code instead of testing it.
- Refactors must not change behaviour; prove equivalence (e.g. diff route dumps).
- Reuse existing constants/helpers; put logic in the right layer; prefer CSS over JS.
- i18n: lazy lookups (`t(".title")`) under a key named after the view/component
  (e.g. `components.add_to_cart.*`). `_html` suffix for markup. Change English wording
  rather than using CSS `text-transform`. Only edit `en.yml`.
- Accessibility: give controls `aria-label`s that name the item (e.g. "Add %{name} to
  cart"); specs then read naturally.

### Git

- One logical change per commit. Imperative subject (~50 chars, no prefix), body
  explains *why* (with numbers when relevant).
- Unrelated fixes go on separate branches / PRs.
- **Rebase, don't merge.** To fold a fix into an earlier commit:
  `git commit --fixup <sha>` then `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <base>`.
  Before rewriting, tag a backup (`git tag -f pre-rebase-backup`) and check
  `git diff pre-rebase-backup HEAD` / `git range-diff` afterwards. Push with
  `git push --force-with-lease=<branch>:<sha>`, only on your own branches.
- If the maintainer pushes to your branch, re-fetch before pushing; drop duplicate fixes.
- Never commit `dump.rdb` (Redis drops it in the repo root), `Gemfile.local*`,
  temporary specs, or `.claude/worktrees/`.

### Pull requests

- Fill in `.github/PULL_REQUEST_TEMPLATE.md` (What? Why?, What should we test?,
  Release notes / changelog category, AI-written-code checkbox).
- "What should we test?" = numbered manual steps grouped by area, with exact URLs
  (e.g. `/admin/products`, `/admin/orders/bulk_management`) and what failure looks
  like (raw `{{ }}` / `$injector` errors for Angular, `NoMethodError`, ...).
- CI runs **undercover**: methods touched by a PR need coverage. If a coverage report
  is provided, cover exactly the listed items.

## Running things locally

Ruby, gems, Postgres, Redis, Node and Chrome are all needed for specs. Setup steps for
a typical machine are in `GETTING_STARTED.md`; `bin/setup` checks for missing tools.

```bash
bin/rails db:create db:schema:load          # dev + test DBs (user ofn / password f00d)
RAILS_ENV=test NODE_ENV=test bin/shakapacker # test packs; needed by system AND many request/controller specs
bundle exec rspec spec/path/to_spec.rb
```

- Set `DISABLE_SPRING=1` for reliable runs.
- Sample data for the dev server: `bin/rake ofn:sample_data` (password `ofn123`, e.g.
  `ofn@example.com`; shops like `/fredo-s-farm-hub/shop`).
- Lint changed files only:
  ```bash
  bundle exec rubocop --force-exclusion $(git diff --name-only --diff-filter=AM origin/master -- '*.rb')
  ```
  ```bash
  bundle exec haml-lint $(git diff --name-only --diff-filter=AM origin/master -- '*.haml')
  ```
  Always pass `--force-exclusion` when giving explicit files (especially with `-a`),
  or RuboCop rewrites excluded files like `config/routes.rb`.
  Shortcuts: `./script/rubocop-diff.sh` (RuboCop on files changed vs `HEAD`; `-a` to
  autocorrect) and `./script/reviewdog.sh` (RuboCop, haml-lint and Prettier, as CI's
  Linters workflow runs them).
- `npx prettier --check <files>`, `npx jest`, Karma via `script/karma`.
- After changing locale files, run `bin/rake tmp:cache:clear` to reload i18n-js
  translations.
- `spec/spec_helper.rb` wires up FactoryBot, DatabaseCleaner, Shoulda Matchers and
  transactional fixtures. WebMock blocks external network calls (localhost and the
  chromedriver host are allowed). Files in `spec/support/**/*.rb` are auto-required:
  look there before adding a new shared helper or matcher.
- The time zone used in specs must match `TIMEZONE` in the relevant `.env[.*]` file.
- i18n: `bundle exec i18n-tasks missing -l en`, `i18n-tasks unused` (~50 pre-existing
  issues: compare before/after rather than expecting zero).
- Ignore the "StimulusReflex requires caching" banner printed on every boot.
- Timings for reference: one system spec file ~45 s; non-browser suite ~25–30 min in one
  process. CI splits everything with Knapsack Pro (`.github/workflows/build.yml`).
- When a failure looks environmental, re-run it on a clean base worktree
  (`git worktree add --detach ../base origin/master`, symlink `node_modules`, copy
  `public/packs-test`) before blaming your change — and before dismissing it.

### Removing dead code

Grep `app lib engines config db/seeds` (not only `spec`) and hand-check for dynamic
dispatch, which is common here:

```bash
git grep -nE '(__send__|\bsend|public_send|try)\(?\s*[":]+[^)]*#\{' -- app lib engines
```

Known dynamic patterns: `"#{scope}_scope"`, `"#{state}?"` (Subscription, ProxyOrder),
`"#{field}_values"`, `"#{action_name}_columns"`, `validate_#{step}`, `"#{type}_member"`
partials, `constantize`d serializers, RSpec predicate matchers (`have_variant`).
When deleting an AngularJS module, also remove it from module dependency lists
(e.g. `darkswarm/darkswarm.js.coffee`), `all.js` requires and the Karma config —
otherwise the whole Angular app fails to boot. Also check camelCase, kebab-case and
snake_case forms of names, templates loaded by name and auto-wired `*Popup` directives.

## Claude Code cloud sessions (maikels-agent fork)

Specific to agent sessions in the Claude Code cloud container.

### Setup recipe (~10 min; skip what the task doesn't need)

Don't add SessionStart hooks or always-on setup automation: not every session needs
a full environment.

```bash
# Ruby: image default is 3.3.6; rbenv at /opt/rbenv. Run in background (~3-5 min).
export RBENV_ROOT=/opt/rbenv PATH=/opt/rbenv/bin:$PATH
MAKE_OPTS=-j4 RUBY_CONFIGURE_OPTS=--disable-install-doc rbenv install -s "$(cat .ruby-version)"
```
```bash
# Use it (RBENV_VERSION alone did not switch Ruby). Node 24 lives in /opt/node24.
export PATH=/opt/rbenv/versions/$(cat .ruby-version)/bin:/opt/node24/bin:$PATH DISABLE_SPRING=1
gem install bundler -v "$(tail -1 Gemfile.lock | tr -d ' ')" && bundle install -j4
```
```bash
yarn install --frozen-lockfile   # if /opt/node24 is missing: add --ignore-engines (node 22 trips on select2)
```
```bash
service postgresql start; service redis-server start   # ulimit warning is harmless
su postgres -c "psql -c \"CREATE ROLE ofn LOGIN SUPERUSER PASSWORD 'f00d';\""
bin/rails db:create db:schema:load
RAILS_ENV=test NODE_ENV=test bin/shakapacker
```

- Chrome for system specs and PDF invoices: `ln -sf /opt/pw-browsers/chromium /usr/local/bin/chromium`
  (or `BROWSER_PATH=/opt/pw-browsers/chromium`).
- If image specs fail with "not identified as a valid media file", install
  `imagemagick` (`apt-get install -y imagemagick`).
- Don't `bundle config set without development`: `bin/rails` needs Spring.
- Containers restart between turns: Postgres/Redis die. Check `pg_isready` before
  trusting a mass of failures (hundreds of failures were twice just a dead DB).
- Bash foreground timeout is 600 s: run long spec runs with `run_in_background`,
  strip ANSI colours before grepping, and compare runs by example id
  (`--format json --out x.json`), not by count.
- Parallel agents in worktrees each need their own `DATABASE_URL`
  (`postgres://ofn:f00d@localhost/ofn_test_<tag>`) and Redis DB
  (`OFN_REDIS_TEST_URL=redis://localhost:6379/<n>`); a shared Redis leaks cached
  preferences between runs. Don't `git checkout` in a shared checkout from subagents.
- Screenshots: a Playwright script against `localhost:3000` (`executablePath:
  '/opt/pw-browsers/chromium'`), or a throwaway system spec calling
  `page.save_screenshot` (delete it afterwards). Dev server: `bin/shakapacker-dev-server`
  + `bin/rails s -p 3000`; first page load is slow (~45 s).

### GitHub access

- `origin` = `maikels-agent/openfoodnetwork` (fork). Clones are shallow; deepen
  with a bounded `git fetch --depth=N`.
- **Branch names:** ignore the auto-generated session branch name (e.g.
  `claude/practical-newton-r9g0ao`). Before pushing code, create a meaningful
  branch named after the change (e.g. `fix-flaky-permissions-spec`,
  `remove-dead-angular-services`, `issue-14865-tax-category-export`) and push that.
  If an existing branch already holds the work (e.g. one the user named or an open
  PR's branch), keep using it.
- Upstream is **git-read-only** from the session: GitHub MCP tools, `gh api` and
  curl to `api.github.com` for `openfoodfoundation/*` return 403 / "not configured",
  and it can't be attached next to the same-named fork. Say so up front instead of
  retrying. Workarounds:
  ```bash
  git fetch https://github.com/openfoodfoundation/openfoodnetwork.git master:upstream-master pull/14901/head:pr-14901
  ```
  then `git diff upstream-master...pr-14901`, `git show pr-14901:path`. WebFetch of
  `github.com/.../pull/N` pages often works (`/checks` loads only partly — say so).
- Fork CI logs: `mcp__github__actions_list` / `mcp__github__get_job_logs` with
  `return_content: true` and a large `tail_lines` (2000+); the result lands in a file —
  parse it and grep `Failures:` / `rspec ./`. Plain `gh api` log downloads fail.
- Creating PRs has failed with "Resource not accessible by integration". If so, give
  the compare URL `https://github.com/maikels-agent/openfoodnetwork/compare/master...<branch>`
  (or the upstream compare) plus a ready PR body. Ask which base (fork or upstream)
  before opening a PR.
- Push 403 "Claude doesn't have GitHub access" means the GitHub connection needs
  reconnecting by the user — report it, don't loop.
- The stop hook nags about unpushed commits on `origin` only; add `.claude/worktrees/`
  to `.git/info/exclude` to keep it quiet.

### Working with the maintainer

- Requests are short and imperative. Commit and push to the session branch without
  asking; open PRs, force-push or post on GitHub only when asked.
- Lead with the outcome. Say exactly what was and wasn't verified (specs run? browser?
  CI?), and which commits/branches were pushed. Admit and correct wrong earlier claims.
- For design questions ("Other solutions?", "Can you find out why?") give options, a
  recommendation and evidence before implementing.
- Use data the user pastes (coverage reports, CI logs) instead of re-fetching it.
- When local specs fail but CI is green, find the environment gap; don't just call it
  "environmental".
- PR reviews: one-line verdict, then what was checked (and not), numbered blockers
  with file, failure scenario and fix, then smaller issues and "checked and fine".
  For several PRs also cover reviewer state, CI, conflicts and dependencies. Never
  post on the PR unless asked.
- Issue triage: skip assigned issues, feature/design work and anything needing a
  maintainer decision; one branch per fix (`issue-<num>-<slug>`); flag behaviour changes.
- Before re-fixing a flaky spec, check whether a branch already fixes it.
