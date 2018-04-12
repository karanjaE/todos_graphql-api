# Intro
some intro

# Prerequisites

As of writing this article, the Ruby version was "2.5.1" and Rails "5.2.0". Ensure that your versions are the same as mine or newer. I'll try and keep this article as up-to-date as possible. I recomment using [RVM](https://rvm.io) to manage different Ruby versions in case you have apps that require older versions fo some reason. Check out the _README_ file in the [repo]() for installation instructions.

Conventionally, a GraphQL API only requires one endpoint to handle all your requests.

In this part we will cover:
- Setting up our app
- Introduction to Queries
- Introduction to Mutations

We will also try to introduce some conventions/best practices that would help keep our queries and mutations well organised. But first things first.

# Setting up

Generate a new Rails app.
```bash
rails new todos_graphql_api --api -T -d postgresql
```
 The `--api` argument tells Rails that this is an API only application. `-T` excludes Minitest. We will use [RSpec]() as our testing framework.

 Run:
 ```bash
 rails db:create
 ```
 to initialize out test and development databases.

 To be able to query our API, we'll need a client. I recomment using Graphiql-app but there are definitely other options out there to discover if you're curious. Go [here](https://github.com/skevy/graphiql-app) to install Graphiql.

 ### Dependencies

Before we go any further, here's a list of our app's dependencies:
- [GraphQL Rails](https://rubygems.org/gems/graphql) : The gem that will form the backbone of our api
- [RSpec Rails](https://rubygems.org/gems/rspec-rails) : Our test framework
- [Factory Bot Rails](https://rubygems.org/gems/factory_bot_rails) : To generate fixtures for our tests.
- [Shoulda Matchers](https://rubygems.org/gems/shoulda-matchers)
- [Database Cleaner](https://rubygems.org/gems/database_cleaner) : To clean up the test database so that tests always start on a clean slate.
- [Faker](https://rubygems.org/gems/faker) : To generate fake data for our tests and seed data.
- [Pry Rails](https://rubygems.org/gems/pry-rails) : To help debug in case we introduce a bug in our code. I'll try to not introduce any though. :wink:

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

 `--require rails_helper` line automatically requires the `rails_helper` in all our specs so that we don't have to add the line in every test file. I just find it more [DRY]()

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
   config.include Factory::Syntax::Methods

   # set up shoulda matchers
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.strategy = :transaction
  end

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

 For now we only need two models: `todo list` and `item`.

 ```bash
 rails g model todo_list title:string
 ```

 The command should generate a migration file, a model file and spec file. I case the spec file is not automatically generated, run:
 ```bash
 rails g rspec:model todo_list
 ```
Next add the `items` model:
```bash
rails g model item name:string done:boolean todo_list:references
rails g rspec:model item
```

The `todo:references` argument creates a `belongs_to` association with the `Todo List`.

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
has_many :items
```

Add the `item` tests:

```ruby
RSpec.describe Item, type: :model do
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

Now all our tests should pass. And that's all we need for our models.
