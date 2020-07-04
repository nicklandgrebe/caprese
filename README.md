# Caprese

Caprese is a Rails library for creating RESTful APIs in as few words as possible. It handles all CRUD operations on resources and their associations for you, and you can customize how these operations
are carried out, allowing for infinite possibilities while focusing on work that matters to you, instead of writing repetitive code for each action of each resource in your application.

For now, the only format that is supported by Caprese is the [JSON API schema.](http://jsonapi.org/format/)

[![Coverage Status](https://coveralls.io/repos/github/nicklandgrebe/caprese/badge.svg)](https://coveralls.io/github/nicklandgrebe/caprese)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'caprese'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install caprese

## Philosophy

Caprese provides a controller framework that can automatically carry out `index`, `show`, `create`, `update`, and `destroy` actions for you with as little configuration as possible. You could write these methods yourself for every resource in your API, but the thing is, these 5 actions essentially do the same three things:

1. Find a resource or set of resources, based on the parameters provided
2. Optionally apply a number of changes to them, based on the data provided and the action selected
3. Serialize and respond with the resource(s), in the format that was requested

Caprese does all of this dirty work for you, so all you have to do is customize its behavior to fine-tune the results. You customize the behavior using serializers, overriding methods, and defining any number of callbacks in and around the actions to fully control each step of the process outlined above.

In the real world, Caprese is a style of dish combining tomatoes, mozzarella, and basil pesto, and is usually put in a salad or on a sandwich. Just like the food, there are four components to creating an API using Caprese: models, serializers, controllers, routes.

Let's create a working API endpoint using Caprese to do something useful: allowing users to create, read, update and delete sandwiches.

## Building an API for sandwiches

### Prep the tomatoes (models)

```ruby
class ApplicationRecord < ActiveRecord::Base
  include Caprese::Record
end

# == Schema Information
#
# Table name: sandwiches
#
#  id             :id               not null, primary key
#  price          :decimal          not null
#  description    :text
#  size           :string(255)      not null
#  restaurant_id  :integer          not null
#
class Sandwich < ApplicationRecord
  belongs_to :restaurant

  has_many :condiments
end

# == Schema Information
#
# Table name: restaurants
#
#  id           :id               not null, primary key
#  name         :string(255)      not null
#
class Restaurant < ApplicationRecord
  has_many :sandwiches
end

# == Schema Information
#
# Table name: condiments
#
#  id            :id               not null, primary key
#  name          :string(255)      not null
#  serving_size  :integer          not null
#  sandwich_id   :integer          not null
#
class Condiment < ApplicationRecord
  belongs_to :sandwich
end
```

Tomatoes: Plain and hearty; an essential part of any true stack. The models of your application are just like them - you need them, but you can't consume them raw - your API has to decide what parts taste good for consumers. We say that models in Caprese are plain, because they're just Rails models...Caprese hasn't done much to them at all. So we create a `Sandwich` model with an association to a `Restaurant` and some `Condiment`s and then work on giving them a better taste with serializers.

### Put on the mozzarella (serializers)

```ruby
class SandwichSerializer < Caprese::Serializer
  attributes :price, :description, :size

  belongs_to :restaurant

  has_many :condiments
end

class RestaurantSerializer < Caprese::Serializer
  attributes :name
end

class CondimentSerializer < Caprese::Serializer
  attributes :name, :serving_size

  belongs_to :sandwich
end
```

Mozzarella is so delicious - you can put it on anything and it's amazing. Mozzarella transforms the bland taste of tomatoes into something edible. Serializers are kinda the same way - you can use them to take a complex data model and turn it into something more consumable for people: JSON. When a user requests a sandwich from our API, Caprese will use the serializers above to define the fields (attributes and relationships) that the user sees, and by default, the response will look something like this:

```json
  {
    "data": {
      "type": "sandwiches",
      "id": "1",
      "attributes": {
        "price": 10.0,
        "description": "Tomato, mozzarella, and basil pesto between two pieces of bread.",
        "size": "large"
      },
      "relationships": {
        "condiments": {
          "data": [
            { "type": "condiments", "id": "5" },
            { "type": "condiments", "id": "6" }
          ]
        },
        "restaurant": {
          "data": {
            "type": "restaurants",
            "id": "2"
          }
        }
      }
    }
  }
```

*NOTE:* Caprese only includes resource identifiers (`type` and `id`) for the `condiments` and `restaurant` of the sandwich, or any other relationship for that matter. It does not include the fields (`attributes` and `relationships`) of these resources unless the user specifically requests them (see [this section of JSON API format](http://jsonapi.org/format/#fetching) for details).

### Bring the tomato and mozzarella together onto a sandwich or salad (controllers)

The bread of a sandwich or the leaves of a salad are what bring the entire Caprese dish together. Controllers are the same way - alongside tomatoes they are the "bite" of our application. When someone asks for a sandwich from our API, a controller fulfills the request, providing a necessary platform for that user to consume our tomatoes and mozzarella (the serialized resources). Let's bring our sandwich endpoint together with a controller, configuring it so it understands what information to use when creating a sandwich requested by a user:

```ruby
class SandwichesController < Caprese::Controller
  def permitted_create_params
    [
      :size, :condiments, :restaurant
    ]
  end
end
```

This means that when a user requests a sandwich, we will use the `size` of the sandwich, any `condiments`, as well as the `restaurant` that the user specified in order to create a new sandwich. Note that we don't include `price` and `description` - we don't want the user to be able to change these. The request that the user makes will look something like this:

```json
{
  "data": {
    "type": "sandwiches",
    "attributes": {
      "size": "small"
    },
    "relationships": {
      "condiments": {
        "data": [
          { "type": "condiments", "id": "5" },
          { "type": "condiments", "id": "6" },
        ]
      },
      "restaurant": {
        "data": {
          "type": "restaurants",
          "id": "1"
        }
      }
    }
  }
}
```

You could also let the user create *new* condiments that aren't on the menu and put them onto their sandwich. Your controller would have to look like this:

```ruby
class SandwichesController < Caprese::Controller
  def permitted_create_params
    [
      :size, :restaurant,
      condiments: [:name, :serving_size]
    ]
  end
end
```

Now, the controller will look at the `name` and `serving_size` attributes of each condiment when creating the sandwich, and add each new condiment to the end result. The request the user would make would look like this:

```json
{
  "data": {
    "type": "sandwiches",
    "attributes": {
      "size": "small"
    },
    "relationships": {
      "condiments": {
        "data": [
          {
            "type": "condiments",
            "attributes": {
              "name": "Dragon Blood",
              "serving_size": "2"
            }
          },
          {
            "type": "condiments",
            "attributes": {
              "name": "Deep Fried Pickles",
              "serving_size": "10"
            }
          }
        ]
      },
      "restaurant": {
        "data": {
          "type": "restaurants",
          "id": "1"
        }
      }
    }
  }
}
```

The response (outlined below) would contain the created sandwich along with any newly created condiments. Note that the attributes of the condiments that the user specified are not returned; remember that Caprese does not respond with `attributes` and `relationships` of related resources unless specifically told to do so.

```json
{
  "data": {
    "type": "sandwiches",
    "id": "1",
    "attributes": {
      "price": 5.0,
      "description": "Tomato, mozzarella, and basil pesto between two pieces of bread.",
      "size": "small"
    },
    "relationships": {
      "condiments": {
        "data": [
          { "type": "condiments", "id": "10" },
          { "type": "condiments", "id": "11" },
        ]
      },
      "restaurant": {
        "data": {
          "type": "restaurants",
          "id": "1"
        }
      }
    }
  }
}
```

If you want users to be able to update sandwiches they've already created, you must also specify what they are allowed to update in the same manner as create:

```ruby
class SandwichesController < Caprese::Controller
  def permitted_create_params
    [
      :size, :restaurant,
      condiments: [:name, :serving_size]
    ]
  end

  # Only allow users to change the condiments of their sandwich
  #   1. Don't let them update the sandwich by creating new condiments, only specifying existing ones
  #   2. Don't let them change the size or the restaurant
  def permitted_update_params
    [
      :condiments
    ]
  end
end
```

### Complete with a dollop of basil pesto (routes)

All that's left to complete our sandwich API is to add routes for `index`, `show`, `create`, `update`, and `destroy`:

```ruby
Rails.application.routes.draw do
  caprese_resources :sandwiches
end
```

With that, you'll now be able to make requests to any of the following URLs, and assuming you provide the necessary data, each one will provide a working response.

```
GET        /sandwiches
GET        /sandwiches/:id
POST       /sandwiches
PATCH/PUT  /sandwiches/:id
DELETE     /sandwiches/:id
```

Additionally, Caprese provides four routes that can be used to manage the relationships of the sandwich directly:

```
GET        /sandwiches/:id/:relationship
GET        /sandwiches/:id/relationships/:relationship
PATCH/PUT  /sandwiches/:id/relationships/:relationship
DELETE     /sandwiches/:id/relationships/:relationship
```

For example, one could make a request to `GET /sandwiches/1/condiments` and the response would be like so:

```json
{
  "data": [
    {
      "type": "condiments",
      "id": "5",
      "attributes": {
        "name": "Ketchup",
        "serving_size": "2"
      },
      "relationships": {
        "sandwich": {
          "data": { "type": "sandwiches", "id": "1" }
        }
      }
    },
    {
      "type": "condiments",
      "id": "6",
      "attributes": {
        "name": "Mustard",
        "serving_size": "1"
      },
      "relationships": {
        "sandwich": {
          "data": { "type": "sandwiches", "id": "1" }
        }
      }
    }
  ]
}
```

For all the details about using relationship endpoints, see [this section](http://jsonapi.org/format/#fetching-relationships) and [this section](http://jsonapi.org/format/#crud-updating-relationships) of the JSON API format.

## Customizing the sandwich further

### Scoping resources

Let's say your sandwich API can create sandwiches for users from 5 different restaurants. Each restaurant has its own condiments, and you want to ensure that a customer cannot request a condiment from a restaurant if the restaurant does not have it.

By default, when `SandwichesController` looks for `condiments`, it uses `Condiment.all` as a starting point. This means that your user making a request could definitely request a condiment that does not exist at the restaurant they're ordering from. To fix this, we use a helper called `record_scope`:

```ruby
class SandwichesController < ApplicationController
  def record_scope(type)
    case type
    when :condiments
      Condiment.where(restaurant_id: data[:relationships][:restaurant][:data][:id])
    else
      super
    end
  end
end
```

### Scoping relationships

Let's say you've created endpoints for `restaurants` as well, using the steps outlined above. This means that a user could make a request like `GET /restaurants/1/sandwiches` and the response would be all the sandwiches that the restaurant has created.

What if, instead, you wanted this endpoint to only return sandwiches that the restaurant had created in the last week alone. Simple, use `relationship_scope`:

```ruby
class RestaurantsController < ApplicationController
  def relationship_scope(name, scope)
    case name
    when :sandwiches
      scope.where('created_at < ?', 1.week.ago)
    else
      super
    end
  end
end
```

### Modifying control flow with callbacks

You may want to customize the behavior of an action like `create`, `update`, or `delete`, but you don't want to go about the task of overriding it entirely. Caprese defines a number of callbacks to modify the control flow for these actions:

```
after_initialize
before_create       (alias for after_initialize)
after_create
before_update
after_update
before_save         (called before `create` and `update`)
after_save          (ditto, but after)
before_destroy
after_destroy
```

To implement one of these callbacks, simply define a callback method and add it to a callback list:

```ruby
class SandwichesController < ApplicationController
  before_create :cut_bread
  before_save :calculate_price_from_special_condiments
  after_update :refund_payment_method_if_moldy

  private

  # Call custom method Sandwich#cut_bread before creating the sandwich
  def cut_bread(sandwich)
    sandwich.cut_bread
  end

  # If any of the condiments is avocado, add extra price when creating and updating sandwiches
  def calculate_price_from_special_condiments(sandwich)
    if(avocado = sandwich.condiments.detect { |c| c.is_a?(Avocado) })
      sandwich.price += avocado.special_price
    end
  end

  # If the customer updates us and says the sandwich is moldy, refund the sandwich
  def refund_payment_method_if_moldy(sandwich)
    sandwich.refund if sandwich.moldy?
  end
end
```

### Handling errors

Errors in Caprese come in two forms: model errors, and controller errors.

#### Model Errors

Model errors are created when a record does not pass validation. [Validators are defined in the model using standard Rails.](http://guides.rubyonrails.org/active_record_validations.html) For example:

```ruby
class Sandwich < ApplicationRecord
  validates_presence_of :size
  validates_length_of :condiments, minimum: 2
end
```

If a user were to make a request like so:

```json
{
  "data": {
    "type": "sandwiches",
    "relationships": {
      "condiments": {
        "data": [
          { "type": "condiments", "id": "1" }
        ]
      }
    }
  }
}
```

The server would respond with `422 Unprocessable Entity`, with a response body like so:

```json
{
  "errors": [
    {
      "source": { "pointer": "/data/attributes/size" },
      "code": "blank",
      "detail": "Size cannot be blank."
    },
    {
      "source": { "pointer": "/data/relationships/condiments" },
      "code": "blank",
      "detail": "Condiments must be of length 2 or more."
    }
  ]
}
```

Model errors have the same interface as in ActiveRecord, but with some added functionality on top. ActiveRecord errors only contain a message (for example: `price: 'Price cannot be blank'`). Caprese model errors also have a code (for example: `price: { code: :blank, message: 'Price cannot be blank.' }`), which is a much more programmatic solution. Rails 5 fixes this, but since Caprese supports both Rails 4 and Rails 5, we defined our own functionality for the time being.

The other thing that `Caprese::Record` brings to the table is that it allows you to create separate translations for error messages depending on the context: API, or application. Application is what you're used to. You can define a translation like `en.active_record.errors.models.product.attributes.title.blank = 'Hey buddy, a product title can't be blank!'` and that user-friendly error message is what will show up in your application form and other user interfaces. But using the same layperson user-friendly error message to a third party API developer is kinda weird, and maybe not so useful.

To use your own errors, set `Caprese.config.i18n_scope = '[YOUR_SCOPE]'`

You can define your own set of translations specifically for your API: `en.[YOUR_SCOPE].models.product.title.blank = 'Custom error message'`. This requires some configuration on your part.

Caprese looks for translations in the following order, and if none of them are defined, it will use `code.to_s` as the error message:

```
# for field errors (attribute or relationship)
[YOUR_SCOPE].models.[model_name].[field].[code]
[YOUR_SCOPE].field.[code]
[YOUR_SCOPE].[code]

# for errors on base
[YOUR_SCOPE].models.[model_name].[code]
[YOUR_SCOPE].[code]
```

#### Controller errors

Caprese provides a method to create controller errors that can have their own translation scope. If at any point in your control flow, say in a callback, you want to immediately halt the request and respond with an error message, you can do the following:

```ruby
fail error(
  field: :filter,
  code: :invalid,
  t: { ... } # translation interpolation variables to use in the error message
)
```

Controller errors are returned from the server looking like this:

```json
{
  "errors": [
    {
      "source": { "parameter": "filter" },
      "code": "invalid",
      "detail": "Filters provided are invalid."
    }
  ]
}
```

Caprese will search for controller errors in the following order:

```
[YOUR_SCOPE].controllers.[controller].[action].[field].[code]
[YOUR_SCOPE].controllers.[controller].[action].[code]
[YOUR_SCOPE].[code]
```

### Configuration

To configure Caprese, create an initializer in your Rails project such as the one below. The values in the example below are default and only need to be included if you intend to change them.

```ruby
# config/initializers/caprese.rb
Caprese.configure do |config|
  # Defines the primary key to use when querying records
  config.resource_primary_key = :id

  # Defines the ActiveModelSerializers adapter to use when serializing
  config.adapter = :json_api

  # Defines the full Content-Type header to respond with
  # config.note Caprese accepts both application/json and application/vnd.api+json
  config.content_type = 'application/vnd.api+json; charset=utf-8'

  # Define URL options for use in UrlHelpers
  config.default_url_options = {}

  # If true, links will be rendered as `only_path: true`
  # TODO: Implement this
  config.only_path_links = true

  # If true, relationship data will not be serialized unless it is in `include`
  config.optimize_relationships = false

  # Defines the translation scope for model and controller errors
  config.i18n_scope = '' # 'api.v1.errors'

  # The default size of any page queried
  config.default_page_size = 10

  # The maximum size of any page queried
  config.max_page_size = 100

  # If true, Caprese will trim the isolated namespace module of the engine off the front of output
  #   from methods contained in Versioning module
  config.isolated_namespace = nil
end
```

You should also look into the configuration for [ActiveModelSerializers](https://github.com/rails-api/active_model_serializers/blob/0-10-stable/docs/general/configuration_options.md) to customize the serializer behavior further.

### Overriding an action while still using Caprese helpers

Coming soon... :)

### Using with Devise or other authentication

If you use a `before_action` filter such as Devise's `authenticate_user!`, be sure to prepend it, like so:

```ruby
class Api::V1::User::ApiController < Caprese::Controller
  prepend_before_action :authenticate_user!
end
```

Otherwise, Caprese's `around_action :enable_caprese_style_errors` will run first, then the action will fail, causing Caprese Style Errors to stay enabled even for your non-Caprese controllers that show errors for Caprese models (such as login pages).

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nicklandgrebe/caprese.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
