# Introduction
[Code](https://github.com/ranchow/todos_graphql-api)

This is the first of a three-part tutorial where we'll learn the fundamentals of building `GraphQL` APIs. We'll try our best to have as much test coverage as possible too.

The [GraphQL official documentation] describes it as `a query language for APIs and a runtime for fulfilling those queries with your existing data`. Unlike REST, GraphQL allows you just to query for the data you need. Something to clarify at this point, GraphQL is **NOT** a replacement for REST but it definitely offers a number of advantages like:
- we can request for all the data we need in one go.
- it returns only the data we need.
- it reduces the need for API versioning by providing tools for continuous evolution of the GraphQL schema.
- we only require one endpoint for all our requests.

We'll try to demonstrate these advantages and many more in the course of this tutorial series.

### Assumptions

This is not a total beginner tutorial. You should have some experience writing applications using Rails and some basic understanding of web APIs. However, no experience in building GraphQL APIs is required or expected.

# Prerequisites

As of writing this article, the Ruby version was "2.5.1" and Rails "5.2.0". I'll try and keep this article as up-to-date as possible. I recommend using [RVM](https://rvm.io) to manage different Ruby versions in case you have apps that require older versions fo some reason.

In this part we will cover:
- Setting up our app
- Introduction to Queries
- Introduction to Mutations

We will also try to introduce some conventions/best practices that would help keep our GraphQL stuff well organised. But first things first.

# Setting up

Generate a new Rails app.
```bash
rails new todos_graphql_api --api -T -d postgresql
```

The `--api` argument tells Rails that this is an API only application. `-T` excludes Minitest which is Rails' default test framework. We will use [RSpec](https://rubygems.org/gems/rspec-rails) as our testing framework.

Run:
```bash
rails db:create
```
to initialize out test and development databases.

To be able to query our API, we'll need a client. I recommend using Graphiql-app but there are definitely other options out there to discover if you're curious. Go [here](https://github.com/skevy/graphiql-app) to install Graphiql.

### Dependencies

Before we go any further, here's a list of our app's dependencies:
- [GraphQL Rails](https://rubygems.org/gems/graphql) : Forms the backbone of our api
- [RSpec Rails](https://rubygems.org/gems/rspec-rails) : Our test framework
- [Factory Bot Rails](https://rubygems.org/gems/factory_bot_rails) : Generates fixtures for our tests.
- [Shoulda Matchers](https://rubygems.org/gems/shoulda-matchers)
- [Database Cleaner](https://rubygems.org/gems/database_cleaner) : Cleans up the test database so that tests always start on a clean slate.
- [Faker](https://rubygems.org/gems/faker) : Generates fake data for our tests and seed data.
- [Pry Rails](https://rubygems.org/gems/pry-rails) : Helps debug in case we introduce a bug in our code. I'll try to not introduce any though. :wink:

Now let's update the `Gemfile`.

In the top section:
```ruby

# Gemfile
gem 'graphql', '~> 1.7', '>= 1.7.14'
```
In the development and test group:

```ruby
# Gemfile

group :development, :test do
  gem 'pry-rails', '~> 0.3.6'
end
```

In the test group:
```ruby
group :test do
  gem 'database_cleaner', '~> 1.6', '>= 1.6.2'
  gem 'factory_bot_rails', '~> 4.8', '>= 4.8.2'
  gem 'faker', '~> 1.8', '>= 1.8.7'
  gem 'rspec-rails', '~> 3.7', '>= 3.7.2'
  gem 'shoulda-matchers', '~> 3.1', '>= 3.1.2'
end
```
Then run `bundle install` to install the dependencies.

#### Configuration

We'll first set up testing.

To initialize the spec directory, run `rails g rspec:install`. This command creates a `spec/` directory in the app's root and a `.rspec` file. Replace the contents of `.rspec` with these to override global RSpec configurations:

```bash
# .rspec

--color
--format documentation
--require rails_helper
```

 `--require rails_helper` line automatically requires the `rails_helper` in all our specs so that we don't have to add the line in every test file. I just find it more [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)

 Then, `factories` directory in `spec/`. This is where we'll store our fixtures.
 `mkdir spec/factories`

 Next, let's update `spec/rails_helper.rb`

 ```ruby
 # Require database cleaner at the top of the file.
 require 'database_cleaner'

 # [...]
 # configure shoulda matchers
 Shoulda::Matchers.configure do |config|
   config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
 end

 # [...]
 RSpec.configuration do |config|
   # [...]
   # set up factory bot
   config.include FactoryBot::Syntax::Methods

   # set up database cleaner
   #start by truncating all the tables but then use the faster transaction strategy the rest of the time.
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.strategy = :transaction
  end

  # start the transaction strategy as examples are run
  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # [...]
 end
 ```

 That was a mouthful! We should be good to go now.

 # Models

 For now we only need two models: `todolist` and `item`.

 ```bash
 rails g model todo_list title:string
 ```

 The command should generate a migration file, a model file and spec file. In case the spec file is not automatically generated, run:
 ```bash
 rails g rspec:model todo_list
 ```
Next add the `items` model:
```bash
rails g model item name:string done:boolean todo_list:references
rails g rspec:model item # in case the spec is not automatically generated
```

The `todo_list:references` argument creates a `belongs_to` association with the `Todo List`.

That's that. Now we test.

Next open up `spec/models/todo_list.rb` and add:
```ruby
# spec/models/todo_list.rb

RSpec.describe TodoList, type: :model do
  it 'has a valid factory' do
    # Check that the factory we created is valid
    expect(build(:todo_list)).to be_valid
  end

  let(:attributes) do
    {
      title: 'A test title'
    }
  end

  let(:todo_list) { create(:todo_list, **attributes) }

  describe 'model validations' do
    # check that the title field received the right values
    it { expect(todo_list).to allow_value(attributes[:title]).for(:title) }
    # ensure that the title field is never empty
    it { expect(todo_list).to validate_presence_of(:title) }
    # ensure that the title is unique for each todo list
    it { expect(todo_list).to validate_uniqueness_of(:title)}
  end

  describe 'model associations' do
    # ensure a todo list has many items
    it { expect(todo_list).to have_many(:items) }
  end
end
```

```bash
bundle exec rspec
```
Of course the test fails

Create the `todo_list` factory

```bash
touch spec/factories/todo_list.rb
```
Add these lines:

```ruby
# spec/factories/todo_list.rb
FactoryBot.define do
  factory :todo_list do
    sequence(:title) { |n| "#{Faker::Lorem.word}-#{n}"}
  end
end
```

Then open `app/models/todo_list.rb` and update it:

```ruby
# app/models/todo_list.rb

# [...]
validates :title, presence: true, uniqueness: true
has_many :items, dependent: :destroy
```

The `dependent: :destroy` is there so that if we delete a todo list, all items associated with it are deleted as well and that way we'll have no _orphanded_ items.

Our tests should now pass.

Next we add the `item` tests:

```ruby
# spec/models/item_spec.rb

RSpec.describe Item, type: :model do
  # check that we have a factory for items
  it 'has a valid factory' do
    expect(build(:item)).to be_valid
  end

  let(:todo_list) { create(:todo_list) }
  let(:attributes) do
    {
      name: 'A test item',
      done: false,
      todo_list: todo_list
    }
  end

  let(:item) { create(:item, **attributes) }

  describe 'model validations' do
    # check that the fields received the right values
    it { expect(item).to allow_value(attributes[:name]).for(:name) }
    it { expect(item).to allow_value(attributes[:done]).for(:done) }
    # ensure that the title field is never empty
    it { expect(item).to validate_presence_of(:name) }
    # ensure that the title is unique for each todo list
    it { expect(item).to validate_uniqueness_of(:name)}
  end

  describe 'model associations' do
    it { expect(item).to belong_to(:todo_list) }
  end
end
```

Run the the test to see that it fails.

Create the item factory
```bash
touch spec/factories/item.rb
```

```ruby
# spec/factories/item.rb

FactoryBot.define do
  factory :item do
    sequence(:name) { |n| "Item name #{n}"}
    done false

    todo_list
  end
endd
```

Update the item model:

```ruby
# app/models/item.rb

# [...]
validates :name, presence: true, uniqueness: true
belongs_to :todo_list
```

Now all our tests should pass. And that's all we need for our models. Now to some GraphQL.

# The API

First things first, we need to set up GraphQL. During our initial setup we installed the `GraphQL` gem which is all we need for now. Now run:
```bash
rails g graphql:install
```
The command creates a `graphql` folder and in it two folders, `types/` and `mmutations/`. It also adds the `graphql_controller.rb` file in the controllers directory. For this section, we won't be touching the controller. In the spirit of TDD, we need to ensure that all our stuff is tested. Go ahead and add a `graphql` directory in the spec folder and add to directories: `types` and `mutations`.
```bash
mkdir spec/graphql
mkdir spec/graphql/types spec/graphql/mutations
```
To help run tests for our GraphQL stuff we'll need another library to make it easier. Add this line to the test group in Gemfile.
```ruby
group :test do
  # [...]
  gem 'rspec-graphql_matchers'
end
```
And run `bundle install` to install it. We are good to go now.

For the remainder of this part, we'll cover introduction to four concepts/terms: `Schema`, `Types`, `Queries` and `Mutations` respectively. We'll also cover testing for these three and introduce a neat way to organize our API. Let's get to it.

## Schema

The schema defines the server's API. It provides the point of contact between the server and client. When we generated the GraphQL files one of the files we created was `todos_graphql_api_schema.rb` in the root of the `graphql/` directory. If we open the file, it looks something like this:
```ruby
TodosGraphqlApiSchema = GraphQL::Schema.define do
  mutation(Types::MutationType)
  query(Types::QueryType)
end
```
We will get into the nitty-gritties of each of the contents as we go but if you'd like further reading on this [here's](https://blog.graph.cool/graphql-server-basics-the-schema-ac5e2950214e) a nice article. We won't need to touch this file for the remainder of this series.

## Types

GraphQL uses a `Types` system to define the possible set of data you can possibly query in your API. Each type has a set of fields which define, well, fields each object can return and their data types. They can be anything from a simple literal like a string or integer to a column in the database table to the result of a method defined somewhere in our app.

Each field has to have a specified datatype that it should return. Most of the basic data types are available by default, that is `String`, `Integer`, `Boolean` etc. A field can also take another GraphQL Type as it's type but we'll cover that when we get there. Here's an example type:

```ruby
Types::ExampleType = GraphQL::ObjectType.define do
  name "ExampleType"
  description "An example description" # Optional

  field :someField, types.ID # represents a unique identifier, often the id of the object.
  field :anotherField, types.String # A UTF‐8 character sequence.
  field :thirdField, types.Int # A signed 32‐bit integer.
  field :fourthField, types.Float # A signed double-precision floating-point value.
  field :fifthField, types.Boolean # Returns true or false.
end
```
Let's break it down:
- `name` :simply defines the name of our type. The convention is to use `camel-case` and should have no spaces.
- `description` : It helps people reading your code understand what data the type exposes
- `field` : defines the data you can get in the object

For further reading on Types, check out [GraphQL official documentation](http://graphql.org/learn/schema/#type-system) on Types beyond the scope of this article.

We need to define a type for our todo_list and item.
```bash
touch app/graphql/types/todo_list.rb app/graphql/types/item.rb
```

We also need to test them so let's create the test files for each.
```bash
touch spec/graphql/types/todo_list_type_spec.rb spec/graphql/types/item_type_spec.rb
```
Now let's open up `spec/graphql/types/todo_list_spec.rb` and edit it.

```ruby
# spec/graphql/types/todo_list_type_spec.rb

RSpec.describe Types::TodoListType do
  # avail type definer in our tests
  types = GraphQL::Define::TypeDefiner.instance

  it 'has an :id field of ID type' do
    # Ensure that the field id is of type ID
    expect(subject).to have_field(:id).that_returns(!types.ID)
  end

  it 'has a :title field of String type' do
    # Ensure the field is of String type
    expect(subject).to have_field(:title).that_returns(!types.String)
  end
end
```

Run `bundle exec rspec spec/graphql/types/todo_list_spec.rb`. Of course there'll be a lot of `Red` which means the tests are failing. Not to worry, we're about to fix that. Create the TodoList type file and open it up `app/graphql/types/todo_list.rb`.

```ruby
# app/graphql/types/todo_list.rb

module Types
  TodoListType = GraphQL::ObjectType.define do
    name 'TodoListType'
    description 'The Todo List type'

    field :id, !types.ID
    field :title, !types.String
  end
end
```
When we run the tests again, everything should pass.

Now before we move any further, you may have noticed an exclamation sign before  the type definition and are probably wondering what it means. Well, it simply means that that field is required and can therefore not be empty. We'll get to see it in action when dealing with mutations.

Let's move on and add the item type. As usual, we first test.

```ruby
# spec/graphql/types/item_type_spec.rb

RSpec.describe Types::ItemType do
  # avail type definer in our tests
  types = GraphQL::Define::TypeDefiner.instance

  it 'has an :id field of ID type' do
    # Ensure that the field id is of type ID
    expect(subject).to have_field(:id).that_returns(!types.ID)
  end

  it 'has a :name field of String type' do
    # Ensure the field is of String type
    expect(subject).to have_field(:name).that_returns(!types.String)
  end

  it 'has a :done field of Boolean type' do
    # Ensure the field is of Boolean type
    expect(subject).to have_field(:done).that_returns(types.Boolean)
  end
end
```

See that the tests fail. Then create the `Type` file:

```bash
touch app/graphql/types/item_type.rb
```

And edit it:
```ruby
module Types
  ItemType = GraphQL::ObjectType.define do
    name 'ItemType'
    description 'Type definition for items'

    field :id, !types.ID
    field :name, !types.String
    field :done, types.Boolean
  end
end
```

Test again. Everything should be passing now.

You'll notice that we are using `module` instead of just namespacing the type definition. Some articles will have something like:
```ruby
Types::TypeName = GraphQL::ObjectType.define do
  name 'TypeName'
  # [...the rest of your stuff]
end
```
Either option works but we'll be sticking to this.

That's it for `Types`. Fun huh? If nothing's making sense, it's about to...

## Queries

If you're familiar with [REST](https://searchmicroservices.techtarget.com/definition/RESTful-API), a [GET](http://www.restapitutorial.com/lessons/httpmethods.html#get) basically fetches data from the data store. You can think of queries as more or less the same thing but with a few differences:
- In REST, when you hit an endpoint eg. `/users` you'd get all the user records with all the fields for each record(_assuming the method that defines the endpoint does a `User.all`_). In a GraphQL query, you could just return the first names or last name or any field you want.
- In rest, to query for a record you'd have to do a `GET` but in GraphQL, since we only need one endpoint, all our requets are `POST`s and we specify whether it's a mutation or query as part of the request.

Here's what a simple query would look like in the Graphiql client:

```graphql
query {
  users {
    first_name
    last_name
    email
  }
}
```
Assuming we have a users table, we would get all the users but only the first_name, last_name and email fields would be returned redardless of how many fields exist on the actual users table.

Before we write our first real query, I promised that we would be introducing a simple way to keep our code well organized. Conventionally, all the queries in our app would reside in `/types/query_type.rb` as fields. [Here's](https://www.howtographql.com/graphql-ruby/2-queries/) a good example of that.

That's OK for small apps like this one but imagine a large one with hundreds, maybe thousands of queries. The file would become too large and a nightmare to maintain or even read. Luckily, at the company where I work, we have a way to handle this. I'd recommend it, and it's the method we'll be using but if you prefer sticking with convention then [HowToGraphQL](https://www.howtographql.com/graphql-ruby/0-introduction/) is a great place to get started. I still use it it for references together with the official docs. Anyway...back to our topic..

Inside the `/app/graphql/` directory, create another directory and call it `util` and inside it add a file `field_combiner.rb`. In the file, we'll define a class with a method that will iterate through the list of queryTypes and call fields on each one and merge the results into one hash. That way, all TodoList related queries can live in one querytype. [Here's](https://m.alphasights.com/graphql-ruby-clean-up-your-query-type-d7ab05a47084) the article to explain this better.

```ruby
# app/graphql/util/field_combiner.rb

module Util
  class FieldCombiner
    def self.combine(query_types)
      Array(query_types).inject({}) do |acc, query_type|
        acc.merge!(query_type.fields)
      end
    end
  end
end
```

Next, open up `app/graphql/types/query_type.rb` and change it to look something like this:

```ruby
# app/graphql/types/query_type.rb

module Types
  QueryType = GraphQL::ObjectType.new.tap do |root_type|
    root_type.name = 'Query'
    root_type.description = 'The query root'
    root_type.interfaces = []
    root_type.fields = Util::FieldCombiner.combine([])
  end
end
```

Now we are ready to write our first query. When we ran `rails g graphql:install`, we only created a folder for types and mutations. This is because convention assumed that all our queries would reside in the `query_type.rb` file. Since this is not the case, we'll create a new directory in the graphql directory to store our queryTypes and a similarly named one in `spec/graphql` for the tests.

```bash
mkdir app/graphql/query_types spec/graphql/query_types
```

Create a file for the TodoList query and its spec file
```bash
touch app/graphql/query_types/todo_list_query_type.rb spec/graphql/query_types/todo_list_query_type_spec.rb
```

By now we've gotten the gist of `Red, Green, Refactor`, where we write a failing test, make it pass then refactor our code. We'll handle the refactoring in the next article if need be. Let's edit the spec file:

```ruby
# spec/graphql/query_types/todo_list_query_type_spec.rb

RSpec.describe QueryTypes::TodoListQueryType do
  # avail type definer in our tests
  types = GraphQL::Define::TypeDefiner.instance

  describe 'querying all todo lists' do

    it 'has a :todo_lists that returns a ToDoList type' do
      expect(subject).to have_field(:todo_lists).that_returns(types[Types::TodoListType])
    end

    it 'returns all our created todo lists' do
      query_result = subject.fields['todo_lists'].resolve(nil, nil, nil)

      # ensure that each of our todo lists is returned
      todo_lists.each do |list|
        expect(query_result.to_a).to include(list)
      end

      # we can also check that the number of lists returned is the one we created.
      expect(query_result.count).to eq(todo_lists.count)
    end
  end
end
```

It looks like there's a lot going on in this test but it's pretty simple. We first create three todo lists, ensure that the field returns a TodoList type, then finally check that all our todo lists are returned. To get the test to pass, we'll edit `app/graphql/query_types/todo_list_query_type.rb` to look like this:

```ruby
# app/graphql/query_types/todo_list_query_type.rb

module QueryTypes
  TodoListQueryType = GraphQL::ObjectType.define do
    name 'TodoListQueryType'
    description 'The todo list query type'

    field :todo_lists, types[Types::TodoListType], 'returns all todo lists' do
      resolve ->(_obj, _args, _ctx) { TodoList.all }
    end
  end
end
```

Our tests should now pass but does it really work? Only one way to find out. Fire up the rails server `rails s` and open the `Graphiql` app that I hope you installed earlier. In the url, enter `http://localhost:3000/graphql` then in the body section, enter:

```graphql
query {
  todo_lists {
    id
    title
  }
}
```
Click the _`Play`_ icon and see what happens. You'll get an error `Field 'todo_lists' doesn't exist on type 'Query'"`. Guess why...well...the reason for the error is that we have not told our schema where to fild the query. To do this, we'll just add it to the array of Query_types on the querytypes file.

```ruby
# app/graphql/types/query_type.rb

# [...]
root_type.fields = Util::FieldCombiner.combine([
  QueryTypes::TodoListQueryType
])
```
Running the query again should return all the todo lists we created when we seeded our database. Try removing `id` or `title` from the query and see what happens. You can also look at the terminal running your server to see how the sql changes depending on what fields we have in the query. Awesome, right?

Let's also create a query type for items and return all items.

```bash
touch app/graphql/query_types/item_query_type.rb spec/graphql/query_types/item_query_type_spec.rb
```
Challenge: why not try and figure out how you'd test the item query type? Here's a hint; we want to make sure that when we query for a Todo List, we also get the items related to it.

Here's the code that should make the tests pass.

It makes sense to include items when we query for Todo lists since an Item belongs to a ToDoList. To do this, we will introduce another field in the `TodoListType` that will be of type Item and will return the items in an array. Let's update the TodoListType.

```ruby
# app/graphql/types/todo_list_type.rb
# [...]
field :items, types[Types::ItemType] do
  resolve ->(obj, _args, _ctx) { obj.items }
end
```
What's happening here is, we are telling Graphql that the `items` field should return an object with fields provided in the Item type. Enclosing it in `types[]` means that the result should be an array. The `obj` argument simply refers to an instance of the class being returned by the type, in this case `TodoListType`. The resolve method then simply returns `todo_list.items`

Let's update our query in Graphiql to:
```graphql
{
  todo_lists{
    id
    title
    items {
      id
      name
      done
    }
  }
}
```
See the change?

Time for a breather. I hope by now you're starting to see the awesomeness of GraphQL. Next we'll look at querying with arguments

#### Querying with Arguments

Assuming we have a RESTful endpoint to get a Todo List with ID `2`, it would look something like `http://ourdomain/todolists/2`. However, keeping in mind that we just have one endpoint, `/graphql`, we cannot append the ID of the Todo List to the end of our URL. Well then, how do we do it?

This is where `arguments` come in. They help us tell GraphQL to return our query with whatever specifications we need it to. The arguments are defined using the keyword `argument` and available to the resolve method in the second argument, usually typed as `args`. So how do we do it in our API?

Let's open up the `todo_list_query_type_spec` and add the test before doing the actual implementation.

```ruby
# spec/graphql/query_types/todo_list_query_type_spec.rb

# [...]
describe 'querying a specific todo_list using it\'s id' do
  it 'returns the queried todo list' do
    # set the id of list1 as the ID
    id = list1.id
    args = { id: id }
    query_result = subject.fields['todo_list'].resolve(nil, args, nil)

    # we should only get the first todo list from the db.
    expect(query_result).to eq(list1)
  end
end
```
The test fails of course. Now let's write our query to make the test pass. In the todo_list_query_type let's add the field.

```ruby
# app/graphql/query_types/todo_list_query_type.rb

# [...]
field :todo_list, Types::TodoListType, 'returns the queried tod list' do
  argument :id, !types.ID

  resolve ->(_obj, args, _ctx) { TodoList.find_by!(id: args[:id]) }
end
```

Now let's jump over to Graphiql and query for the Todo List with ID: 1.

```graphql
query {
  todo_list (id: 1) {
    id
    title
    items {
      name
      done
    }
  }
}
```
The query returns, you guessed it, the first Todo List with all the Items related to it. Now try and add a query to get an item by id. You can compare the code with the one in the [repo](https://github.com/ranchow/todos_graphql-api/tree/part-1). And don't forget to test. :wink:

Easy right? That's it for queries.

## Mutations

When we want to create, edit or even delete something in our app, we do it in a **mutation**. Mutations do exactly what the name says they do...exert changes to data. We are going to add mutations to create new Todo Lists, items, mark  items as done and delete Todo Lists and Items. A simple create mutation would look like this:

```ruby
field :create_something, Types::SomeType do
  argument :name, !types.String
  argument :description, types.String

  resolve ->(obj, args, ctx) do
    SomeThing.create(
      name: args[:name],
      description: args[:description]
    )
  end
end
```
We pass the data we need via arguments with required ones preceded by a `!`. We then call `.create` on the model and voilà! Now let's head back to our app and add a mutation to create a new Todo List. As usual....

```ruby
# spec/graphql/mutations/todo_list_mutation_spec.rb

RSpec.describe Mutations::TodoListMutation do
  describe 'creating a new record' do
    let(:args) do
      {
        title: 'Some random title'
      }
    end

    it 'increases todo lists by 1' do
      mutation = subject.fields['create_todo_list'].resolve(nil, args, nil)
      # adds one todo_list to the db
      expect(mutation).to change { TodoList.count }.by 1
    end
  end
end
```
Then to make the test pass, ...

```ruby
# app/graphql/mutations/todo_list_mutation.rb

module Mutations
  TodoListMutation = GraphQL::ObjectType.define do
    name 'TodoListMutation'
    description 'Mutation type for todo list'

    field :create_todo_list, Types::TodoListType do
      argument :title, !types.String

      resolve ->(_obj, args, _ctx) do
        TodoList.create(
          title: args[:title]
        )
      end
    end
  end
end
```

We only require the title to create a Todo List and therefore it's the only required argument. The next thing is to tell graphql where to find the `create_todo_list`. To do this we just need to include the `TodoListMutation` mutation in the Mutations array.

```ruby
# app/graphql/types/mutation_type.rb

# [...]
root_type.fields = Util::FieldCombiner.combine([
  Mutations::TodoListMutation
])
```
Now let's fire up `Graphiql` and test out our code.

```graphql
mutation {
  create_todo_list (
    title: "An awesome todo list"
  ) {
    id
    title
  }
}
```
We should get something like:
```json
{
  "data": {
    "create_todo_list": {
      "id": "1",
      "title": "An awesome todo list"
    }
  }
}
```
Awesome, right? Now

```ruby
# spec/graphql//mutations/item_mutation_spec.rb

RSpec.describe Mutations::ItemMutation do
  describe 'creating a new record' do
    # an item belongs to a tod list so we create one
    let!(:todo_list) { create(:todo_list) }

    it 'adds a new item' do
      args = {
        todo_list_id: todo_list.id,
        name: 'An amazing name',
      }

      subject.fields['create_item'].resolve(nil, args, nil)
      # The items count increases by 1
      expect(Item.count).to eq(1)
      # The name of the most recently created item matches the value we passed in args
      expect(Item.last.name).to eq('An amazing name')
    end
  end
end
```
And to make the test pass...

```ruby
# app/graphql/mutations/item_mutation.rb

module Mutations
  ItemMutation = GraphQL::ObjectType.define do
    name 'ItemMutation'
    description 'Mutations for items'

    field :create_item, Types::ItemType do
      argument :todo_list_id, !types.ID
      argument :name, !types.String

      resolve ->(_obj, args, _ctx) do
        todo_list = TodoList.find(args[:todo_list_id])
        # ensure that we actually find a todo list
        return unless todo_list

        todo_list.items.create(
          name: args[:name]
        )
      end
    end
  end
end
```
Also, remember to include the `ItemMutation` in the  `MutationType`.
```ruby
# app/graphql/types/mutation_type.rb

# The mutation type should by now look like this.
# [...]
root_type.fields = Util::FieldCombiner.combine([
  Mutations::TodoListMutation,
  Mutations::ItemMutation
])
```

Quick recap before we move forward. At this point, we have learnt how to:
- Set up a GraphQL API,
- Organize our code so that it's better manageable,
- Create and test GraphQL queries and mutations.
- Use Graphiql to test our code.

Next, we'll look at `updating`/`editing` and `deleting` Todo lists and Items. At this point, we can sort of figure our way around so it should only get easier moving forward.

Now let's add a mutation to edit and delete a todo list. As usual, we first test. A nice challenge would be to try andd write the test without referring just to see if you're getting the hang of it but if you get stuck, here it is..

The test:
```ruby
# spec/graphql/mutations/todo_list_mutation_spec.rb

# [...]
describe 'editing a todo list' do
  let!(:todo_list) { create(:todo_list, title: 'Old title') }

  it 'updates a todo list' do
    args = {
      id: todo_list.id,
      title: 'I am a new todo_list title'
    }

    query_result = Mutations::TodoListMutation.fields['edit_todo_list'].resolve(nil, args, nil)

    expect(query_result.title).to eq(args[:title])
    # test that the number of todo lists doesn't change
    expect(TodoList.count).to eq 1
  end
end

describe 'deleting a todo list' do
  let!(:todo_list1) { create(:todo_list) }
  let!(:todo_list2) { create(:todo_list) }

  it 'deletes a todo list' do
    args = {
      id: todo_list1.id
    }
    query = subject.fields['delete_todo_list'].resolve(nil, args, nil)

    expect(query).not_to include(todo_list1)
  end

  it 'reduces the number of todo lists by one' do
    args = {
      id: todo_list1.id
    }
    subject.fields['delete_todo_list'].resolve(nil, args, nil)

    expect(TodoList.count).to eq 1
  end
end
```

And the implementation...
```ruby
# app/graphql/mutations/todo_list_mutation.rb

# [...]

field :edit_todo_list, Types::TodoListType do
  argument :id, !types.ID, 'the ID of the todolist to edit'
  argument :title, types.String, 'the new title'

  resolve ->(_obj, args, _ctx) do
    todo_list = TodoList.find_by(id: args[:id])

    if args.key?(:title)
      todo_list.update(
        title: args[:title]
      )
    end
    todo_list
  end
end

field :delete_todo_list, types[Types::TodoListType] do
  argument :id, !types.ID, 'the ID of the todolist to delete'

  resolve ->(_obj, args, _ctx) do
    todo_lists = TodoList.all
    todo_list = TodoList.find_by(id: args[:id])

    # Ensure that we find the todo list
    todo_list.destroy
    # return all todo lists
    todo_lists
  end
end

# [...]
```
And finally, the `edit` and `delete` mutations for items. To edit, we probably just need to mark an item as done and that's what we'll do.
First we test...

```ruby
# spec/graphql/mutations/item_mutation_spec.rb

# [...]
describe 'editing an item' do
  let!(:todo_list) { create(:todo_list) }
  let!(:item) { create(:item, todo_list: todo_list) }
  # making an item as done
  it 'marks an item as done' do
    args = {
      id: item.id
    }
    query_result = subject.fields['mark_item_done'].resolve(nil, args, nil)

    expect(query_result.done).to eq true
  end
end

describe 'deleting an item' do
  let!(:todo_list) { create(:todo_list) }
  let!(:item1) { create(:item, todo_list: todo_list) }
  let!(:item2) { create(:item, todo_list: todo_list) }
  let!(:item3) { create(:item, todo_list: todo_list) }

  it 'deletes the wueried item' do
    args = {
      id: item1.id
    }
    subject.fields['delete_item'].resolve(nil, args, nil)

    expect(Item.count).to eq 2
    expect(Item.all).not_to include(item1)
  end
end
```
Then...
```ruby
# app/graphql/mutations/item_mutation.rb

# [...]
field :mark_item_done, Types::ItemType do
  argument :id, !types.ID

  resolve ->(_obj, args, _ctx) do
    item = Item.find_by(id: args[:id])
    return unless item

    item.update(
      done: true
    )

    item
  end
end

field :delete_item, Types::ItemType do
  argument :id, !types.ID

  resolve ->(_obj, args, _ctx) do
    item = Item.find_by(id: args[:id])
    return unless item

    item.destroy
  end
end
```
We can now fire up Graphiql and test out our Mutations.
And voila! We are done with the first part of building out `Todo List GraphQL API`.

# Conclusion

At this point, we should be able to create simple queries and mutations and have an understanding of how GraphQL works in Ruby/Rails.

I'd also like to thank my good friend [Austin](https://github.com/akabiru) for letting me use his article on [building RESTful APIs with Rails 5](https://scotch.io/tutorials/build-a-restful-json-api-with-rails-5-part-one) as inspiration for this series.

In the next part of the tutorial, we will look at authentication.
