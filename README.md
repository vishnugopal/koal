# Koal

Koal makes reading the works of _amateur fiction writers_ easy & friendly on mobiles. Currently, _good_ amateur writing is spread across multiple websites & newsgroups on the Internet, places that are hard to find, and sites that were built in the 90s. Some stories have even disappeared from Internet archives. Koal provides a simple, clean and modern interface to such writing.

You do not need to login to use Koal, and it's also completely free to use. Start here: [koal.io](https://koal.io/).

## Current Status

**Usable**, but needs lots of polish.

## Development

Koal is built using the [Ruby on Rails](https://rubyonrails.org/) & [Stimulus](https://stimulusjs.org/) frameworks. [Tailwind](https://tailwindcss.com) on [PostCSS](https://postcss.org) is extensively used for styling.

Koal also has an opinionated folder-structure that differs from the standard Rails 5 & Webpack folder structure that by default elevates Javascript to a top level `app/javascript` folder. Because Koal uses Stimulus, which is meant to be a "modest JavaScript framework" & not a full-fledged client-side library like React or Vue, Koal places all Javascript assets in `app/assets/javascripts`. The `config/webpacker.yml` file therefore uses `app/assets` as the webpack directory instead of `app/javascript`.

There is also some importer code available at `Story.load_from_folder` that makes importing common file formats easier.

To start development, do:

```
bundle
#download required files to ~/Downloads
bin/rails db:setup
foreman start -f Procfile.dev
```

## Deployment

Koal is currently configured to be best deployed to a Dokku instance on Digital Ocean. There is a `Procfile` available to handle starting the `puma` webserver.
