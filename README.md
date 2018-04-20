# Todo List GraphQL API

[![forthebadge](https://forthebadge.com/images/badges/made-with-ruby.svg)](https://forthebadge.com)
[![forthebadge](https://forthebadge.com/images/badges/powered-by-electricity.svg)](https://forthebadge.com)

This repo is the source companion for the `Building a GraphQL API in Rails` tutorial series.
- [Part 1]

## Setting up

#### Requirements

- Ruby 2.5.1
- Rails 5.2.0
- Postgresql => 10.3
- [Graphiql](https://github.com/skevy/graphiql-app) - The GraphQL client
- Your favorite editor.

#### Installation

**Clone the repo.**
```bash
git clone https://github.com/ranchow/todos_graphql-api.git
```

**cd into the directory and install the reqirements.**
```bash
cd todos_graphql-api && bundle install
```

**set up the database**
```bash
rails db:create; rails db:migrate; rails db:seed
```

**Start the server**
```bash
rails s
```

#### Running tests

Running all tests.
```bash
bundle exec rspec
```

Running a specific test file
```bash
bundle exec rspec ./spec/path/to/file
```

## Contributing

To contribute, fix bugs that I might have missed or just want to play around, just go ahead and fork the repo, add a feature branch and raise a pull request.
