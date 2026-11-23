<picture>
  <source media="(prefers-color-scheme: light)" srcset="public/images/loqrs-logo-w-beta.png" />
  <img src="public/images/loqrs-logo-white-w-beta.png" alt="LOQRS Beta" width="265" height="116" />
</picture>

# LOQRS

**Get a QR Locker.** No Accounts, No Passwords.

A one-time file-sharing service: you pay us, we encrypt your files, and we hand
you the encryption key as a QR code.

## The Mission

> We like trading files for various reasons, and sometimes the easiest way to do that is with a web page. But, what if you want to limit access to that page? Is there something simpler than usernames and passwords for just a web page? Most sharing services make you create an account, give personal information, plus a credit card and then charge recurring fees. Then they bombard you with unwanted emails.

> This is a one-time service. You pay us, we encrypt your files and give you the encryption key in the form of a QR code. It comes with only one risk. If you lose your key, that's it. Our system is designed so that we can't get to your files, which also means we don't know whose files belong to whom. That is the point. It’s a web locker. Forget the combination or lose the key… whoops.

> But also… you don’t need to know who is getting the files if they have the key. For example, you can give out ten keys to the same locker for a club or a class. Or you can have a store giveaway that takes place only at that store. You can distribute music or book files that you don’t want freely available. Use your imagination.

This repo is the marketing/waitlist site for that product: a single static page
(`src/pages/index.astro`) plus one PHP endpoint that collects beta signup emails.

## Development

### Prerequisites

| Requirement | Notes |
| --- | --- |
| Node `>= 26.13.1` | declared by `package.json` `engines` |
| npm | install scripts are allowlisted via `allowScripts` (`@parcel/watcher`, `fsevents`, `cpu-features`, `ssh2`) |
| A local PHP host | only needed to exercise the signup form — see [The signup endpoint](#the-signup-endpoint) |

### Install and run

```sh
npm install
npm run dev          # astro dev --host 0.0.0.0
```

The dev server is at **http://localhost:1217** — the port comes from
`server.port` in `astro.config.mjs`, not Astro's default 4321. `--host 0.0.0.0`
also prints LAN addresses (`http://10.0.0.27:1217/`), which is how you check the
responsive layout on a real phone on the same network.

```sh
astro dev --background
astro dev status     # is it running, on what port
astro dev logs       # tail the output
astro dev stop
```

### The signup endpoint

`BetaSignUp.astro` posts to `/api/subscribe.php` twice over — a plain
`action`/`method` fallback and an `hx-post` so htmx swaps the feedback message
in place without a page reload. In dev, `astro.config.mjs` proxies `/api` to
`http://loqrs-site.test`:

```js
proxy: { '/api': { target: 'http://loqrs-site.test', changeOrigin: true } }
```

So the form only responds if something on your machine serves that host (MAMP,
nginx, Caddy, `php -S loqrs-site.test:80`). Without it the page still works —
the email input validates, and you'll get an htmx network error in the feedback
region. Everything else on the site is pure static HTML/CSS.

The source of truth for that endpoint is `public/api/subscribe.php`. Astro copies
`public/` verbatim, so it ships to `build/api/subscribe.php` and runs on the
production host as real PHP.

### Build and deploy

```sh
npm run build        # → ./build  (outDir in astro.config.mjs)
npm run preview      # serve the built site locally
```

Note the output directory is **`build/`, not the usual `dist/`**, and it is
committed to git. Deployment is an FTP upload of that folder (`ftp-deploy` is a
dependency; no deploy script is wired up yet), so rebuild and commit before
shipping a change.

### All commands

| Command | Action |
| :------ | :----- |
| `npm install` | Installs dependencies |
| `npm run dev` | Dev server at `localhost:1217`, exposed on the LAN |
| `npm run build` | Builds the static site to `./build` |
| `npm run preview` | Serves the build locally, before deploying |
| `npm run astro ...` | CLI commands like `astro add`, `astro check` |
| `npm run astro -- --help` | Get help using the Astro CLI |

## Project Structure

```text
├── public/
│   ├── api/subscribe.php      # beta signup endpoint (copied verbatim into build/)
│   ├── fonts/                 # Chunk Five + IBM Plex Serif webfonts
│   └── images/                # logo, locker composites, guide steps, stickers
├── scripts/
│   ├── build-lockers.mjs      # sharp-based image compositing
│   └── check-layout.sh        # agent-browser viewport measurements
├── src/
│   ├── components/
│   │   ├── SiteHeader.astro     # logo, nav actions, slogan
│   │   ├── LockersRow.astro     # responsive locker imagery
│   │   ├── UserGuide.astro      # how-it-works steps
│   │   ├── LoqrFeatures.astro   # the loqr types
│   │   ├── BetaSignUp.astro     # email form (htmx + honeypot), reusable
│   │   └── WaitlistDialog.astro # fullscreen popover wrapping BetaSignUp
│   ├── pages/index.astro      # the whole site — one page
│   └── styles/
│       ├── house.scss         # page layout
│       ├── _variables.scss    # SCSS tokens ($logo-max-width, …)
│       └── _typography.scss   # font faces and type scale
└── astro.config.mjs           # site, outDir: ./build, server.port 1217, /api proxy
```

`BetaSignUp` is rendered twice on the home page: inline in the `#join_us`
section, and again inside the `WaitlistDialog` modal. The `idPrefix` prop keeps
the two instances' `id`s from colliding (`waitlist-email` vs `signup-email`),
which matters because the PHP endpoint resets the form by id via an htmx
out-of-band swap.

## How the Waitlist Dialog Stays Zero-Framework

The modal uses the HTML [Popover API](https://developer.mozilla.org/en-US/docs/Web/API/Popover_API)
for open/close, Escape-to-dismiss, and top-layer stacking — no dialog library.
There are two ways in, and each has a matching way out:

| Entry | State | Dismiss |
| :---- | :---- | :------ |
| Header "Join the Waitlist" button (`popovertarget`) | `:popover-open` | × button, Escape, and (JS on) click outside |
| Footer "SIGN UP" link (`href="#waitlist-dialog"`) | `:target` fallback when JS is off | × link and scrim, both anchors to `#join_us` |

With JS on, the component's script intercepts the footer link so the URL never
carries a fragment. That detail is load-bearing: browsers do not re-evaluate
`:target` after `history.replaceState()` rewrites the URL, so a stale `:target`
outlives the click and repaints a closed popover — the classic "Escape stopped
working" bug. The dialog flags itself with `data-js` and CSS scopes the
`:target` rules to `:not([data-js])`, leaving `:popover-open` as the only source
of truth when scripting is available.

## Learn More

- [Astro docs](https://docs.astro.build) — routing, components, content collections, styling
- [`AGENTS.md`](./AGENTS.md) — dev-server conventions for AI assistants working here
- [`docs/superpowers/specs/`](./docs/superpowers/specs) — design specs behind the responsive layout work
