# GraphQL server

A GraphQL server built with Elixir, Phoenix and Absinthe

## Table of Contents

- [GraphQL server](#graphql-server)
  - [Table of Contents](#table-of-contents)
  - [Roadmap](#roadmap)
  - [Installation](#installation)

## Roadmap

- Queries
- Mutations
- Subscriptions

## Installation

Don't forget to change your database user data inside config files.

Clone this project and run:

```elixir
mix ecto.setup
mix phx.server

```

and then you can access GraphQL playground via `http://localhost:4000/graphiql`
