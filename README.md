# Neoscan Umbrella Application

[![Travis](https://img.shields.io/travis/CityOfZion/neo-scan.svg?branch=master&style=flat-square)](https://travis-ci.org/CityOfZion/neo-scan)

Elixir + Phoenix Blockchain explorer for NEO.
# How to contribute

Using docker you can start the project with:
- `docker-compose up -d`
- `docker exec -it neoscan_phoenix_1 sh`
- `cd /data`

# Development
- Please run the tests after any changes 

To run, first install Elixir and Phoenix at:

* https://elixir-lang.org/install.html
* https://github.com/phoenixframework/phoenix

To run the tests:
 * Install dependencies with `mix deps.get --only test`
 * Create and migrate your database with `MIX_ENV=test mix ecto.create && mix ecto.migrate`
 * Run `mix test`

To start your The Application/Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `cd apps`, `cd neoscan_web`, then `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Make sure the username and password for your postgresSQL match the contents of "apps/neoscan/config/dev.exs"

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
