# Caprese

Caprese is a Rails library for creating RESTful APIs in as few words as possible. It handles all CRUD operations on resources and their associations for you, and you can customize how these operations
are carried out, allowing for infinite possibilities while focusing on work that matters to you, instead of writing repetitive code for each action of each resource in your application.

For now, the only format that is supported by Caprese is the [JSON API schema](http://jsonapi.org/format/). In the future, Caprese will support a more straightforward (but less powerful) JSON format as well, for simpler use cases.

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

Caprese provides a controller framework that can automatically carry out `index`, `show`, `create`, `update`, and `destroy` actions for you with as little configuration as possible. You could write these methods yourself for every resource in your application, but the thing is, these 5 actions essentially do the same three things:

1. Find a resource or set of resources, based on the parameters provided
2. Optionally apply a number of changes to them, based on the data provided and the action selected
3. Serialize and respond with the resource(s), in the format that was requested

Caprese does all of this dirty work for you, so all you have to do is customize its behavior to fine-tune the results. You customize the behavior by creating resource representations using serializers, by overriding intermediate helper methods, and by defining any number of callbacks in and around the actions to fully control each step of the process outlined above.

There are four components to creating an API using Caprese: controllers, routes, serializers, and records.

Before reading any further, we recommend that you read the [JSON API schema](http://jsonapi.org/format/) in full. It covers a lot of important information on all three steps above: modifying resource sets through query parameters, making changes to resources, modifying the response format, and more. Rather than make this doc a deep JSON API tutorial, we are going to assume you have read the schema and know what we're talking about.

## Usage

### Set up your controller structure

You are familiar with using `ApplicationController` and having your controllers inherit from it. In Caprese, your `ApplicationController` is a `Caprese::Controller`, and everything inherits from it:

```
# app/controllers/api/application_controller.rb
module API
  class ApplicationController < Caprese::Controller
    # Global API configuration
  end
end

# app/controllers/api/v1/application_controller.rb
module API
  module V1
    class ApplicationController < API::ApplicationController
      # API V1 configuration
    end
  end
end
```

This structure allows you to define global API configuration, as well as versioned configuration specific to your `API::V1`.

### Defining endpoints for a resource

Let's say you have a model `Product`. You'd create a versioned controller for it, inheriting from your `API::V1::ApplicationController`:

```
# app/controllers/api/v1/products_controller.rb
module API
  module V1
    class ProductsController < ApplicationController
    end
  end
end
```

You should also create a `Serializer` for `Product`, so Caprese will know what attributes to render in the response to requests.

Defining your serializers is simple:

```
# app/serializers/api/v1/application_serializer.rb
module API
  module V1
    class ApplicationSerializer < Caprese::Serializer
      # API::V1 serializer configuration
    end
  end
end

# app/serializers/api/v1/product_serializer.rb
module API
  module V1
    class ProductSerializer < ApplicationSerializer
      attributes :title, :description
    end
  end
end
```

This tells Caprese that when rendering requests for products, it should only include the `product.title` and `product.description` in the response.

`Caprese::Serializer` inherits from `ActiveModel::Serializer`, thus leaving the functionality of serializers to be defined by [ActiveModelSerializers](https://github.com/rails-api/active_model_serializers), a powerful library in Rails API. `Caprese::Serializer` automatically creates `links` for both the resource itself, and *all* of the resource's relationships.

From there, add a route:

```
# config/routes.rb
Rails.application.routes.draw do
  namespace 'api' do
    namespace 'v1' do
      caprese_resources :products
    end
  end
end
```

With just that, you've just created fully functioning endpoints for `index`, `show`, and `destroy`:

```
GET    /api/v1/products
GET    /api/v1/products/:id
DELETE /api/v1/products/:id
```

Make a request to any of these endpoints, and your response will be product(s) with their `title` and `description`.

You can also modify the requests using JSON API query parameters like `filter`, `sort`, `page`, `limit`, `offset`, `fields`, and `includes`.

You might ask: What about `create` and `update`? Well, those require some configuration in order to work:

```
# app/controllers/api/v1/products_controller.rb
module API
  module V1
    class ProductsController < ApplicationController

      def permitted_create_params
        [:title, :description]
      end

      def permitted_update_params
        [:description]
      end

    end
  end
end
```

With that, you've stated that when creating a product, the params that are permitted to be assigned to the new product are `title` and `description`. When updating a product, the params that are permitted to be updated are nothing but `description`. You can't update the `title`.

That's it. You now have five fully functioning endpoints:

```
GET       /api/v1/products
GET       /api/v1/products/:id
POST      /api/v1/products
PATCH/PUT /api/v1/products/:id
DELETE    /api/v1/products/:id
```

### Managing relationships of resources

The above is a little misleading. After doing the steps above, you'll actually end up with EIGHT endpoints:

```
GET       /api/v1/products
GET       /api/v1/products/:id
POST      /api/v1/products
PATCH/PUT /api/v1/products/:id
DELETE    /api/v1/products/:id
GET       /api/v1/products/:id/:relationship
GET       /api/v1/products/:id/relationships/:relationship
PATCH/PUT/DELETE /api/v1/products/:id/relationships/:relationship
```

The three new endpoints are for reading and managing relationships (known as `associations` in Rails) of the resource.

You can also specify which relationships can be assigned to a resource when created or which relationships can be updated:

```
def permitted_create_params
  [:title, :description]
end

def permitted_update_params
  [:description, :orders]
end
```

You could thus update the orders of a product in by making a call to one of two endpoints:
```
PATCH/PUT         /api/v1/products/:id                      # include `orders` in `relationships` member
PATCH/POST/DELETE /api/v1/products/:id/relationships/orders # provide resource identifiers for orders
```

### Scoping resources to customize behavior

Let's say you don't want a user to be able to request all the products in your database, you only want them to be able to request the ones that belong to them. If you determined `current_user` based on the authentication credentials they used, you could scope your products to only `current_user` by overriding the intermediate helper method `record_scope`:

```
# app/controllers/api/v1/products_controller.rb
module API
  module V1
    class ProductsController < ApplicationController
      def record_scope(type)
        case type
        when :products
          Product.where(user: current_user)
        end
      end
    end
  end
end
```

Let's take that one step further and state that when that user updates the orders of an existing product, you only want them to be able to add orders that belong to them, too. Simple:

```
def record_scope(type)
  case type
  when :products
    Product.where(user: current_user)
  when :orders
    Order.where(user: current_user)
  end
end
```

Now, if they were to make a request like `POST /api/v1/products/1/relationships/orders` to append an order to one of their products, and they submit a resource identifier for an order that did not belong to them, the response would be `404 Not Found`.

There is one more consideration to be made here. What if, when this user makes a request to `GET /api/v1/products/1/orders` to get the list of orders for one of their products, you only want to return orders that have been created in the last week. This time, you override another intermediate helper method, `relationship_scope`:

```
def relationship_scope(name, scope)
  case name
  when :orders
    scope.where('created_at < ?', 1.week.ago)
  end
end
```

`name` is the name of the relationship to scope, and `scope` is the existing scope for the relationship, in this case, equal to `Product.find(1).orders`.

### Modifying control flow with callbacks

You may want to customize the behavior of an action, but you don't want to go about the task of overriding it entirely. Caprese defines a number of callbacks to modify the control flow for any action, allowing you to keep controller logic where it belongs.

```
# app/controllers/api/v1/orders_controller.rb
module API
  module V1
    class OrdersController < ApplicationController
      after_initialize :calculate_price_from_line_items, :do_something_else
      after_create :send_confirmation_email

      private

      # If `Order#line_items` is a has_many association, and is created with an order (see: nested association creation),
      # iterate over each line item and sum its price to determine the total order price
      def calculate_price_from_line_items(order)
        if order.line_items.any?
          order.price = order.line_items.inject(0) do |sum, li|
            sum += li.price
          end
        else
          order.errors.add(:line_items, :blank) # an order must have line items
        end
      end

      # After creating an order, send the customer a confirmation email
      def send_confirmation_email(order)
        ConfirmationMailer.send(order)
      end
    end
  end
end
```

The following callbacks are defined by Caprese:

```
before_query        (called before anything)
after_query         (called after the response is rendered)
after_initialize    (called in #create after the resource is instantiated)
before_create       (alias for after_initialize)
after_create        (rest are self explanatory)
before_update
after_update
before_save
after_save
before_destroy
after_destroy
```

Reading this, note that saying `before_action :do_something, only: [:create]` is not the same as saying `before_create :do_something`. But you can use the former if you like, to customize further.

### Creating nested associations

You can also use Caprese to created nested associations when creating their owners. For example, if I have two models:

```
class Order < ActiveRecord::Base
  has_many :line_items, autosave: true
end

class LineItem < ActiveRecord::Base
  belongs_to :order
end
```

I can send a resource document to `POST /api/v1/orders` that looks like this:

```json
{
  "data": {
    "type": "orders",
    "attributes": {
      "some_order_attribute": "..."
    },
    "relationships": {
      "line_items": {
        "data": [
          {
            "type": "line_items",
            "attributes": {
              "price": 5.0
            }
          },
          {
            "type": "line_items",
            "attributes": {
              "price": 6.0
            }
          }
        ]
      }
    }
  }
}
```

and once I configure my controller to indicate that it is permitted to create line items with orders, it will work:

```
# app/controllers/api/v1/orders_controller.rb
module API
  module V1
    class OrdersController < ApplicationController
      def permitted_create_params
        [:some_order_attribute, line_items: [:price]]
      end
    end
  end
end
```

You could apply the same logic to `permitted_update_params` to update line items through `PATCH /api/v1/orders/:id`, just add an `"id"` field to the relationship data of each line item so Caprese knows which one to update.

### Handling errors

Errors in Caprese come in two forms: model errors, and controller errors.

#### Model Errors

Model errors are returned from the server looking like this:

```json
{
  "errors": [
    {
      "source": { "pointer": "/data/attributes/price" },
      "code": "blank",
      "detail": "Price cannot be blank."
    },
    {
      "source": { "pointer": "/data/relationships/line_items" },
      "code": "blank",
      "detail": "Line items cannot be blank."
    },
    {
      "source": { "pointer": "/data/relationships/line_items/data/attributes/price" },
      "code": "blank",
      "detail": "Price cannot be blank."
    }
  ]
}
```

Model errors have the same interface as in ActiveRecord, but with some added functionality on top. ActiveRecord errors only contain a message (for example: `price: 'Price cannot be blank'`). Caprese model errors also have a code (for example: `price: { code: :blank, message: 'Price cannot be blank.' }`), which is a much more programmatic solution. Rails 5 fixes this, but since Caprese supports both Rails 4 and Rails 5, we defined our own functionality for the time being.

To make use of Caprese model errors, add the `Caprese::Record` concern to your models:

```
class Product < ActiveRecord::Base
  include Caprese::Record
end
```

The other thing that `Caprese::Record` brings to the table is that it allows you to create separate translations for error messages depending on the context: API, or application. Application is what you're used to. You can define a translation like `en.active_record.errors.models.product.attributes.title.blank = 'Hey buddy, a product title can't be blank!'` and that user-friendly error message is what will show up in your application. But using the same user-friendly error message to a third party API developer is kinda weird.

You can define your own set of translations specifically for your API: `en.api.v1.errors.models.product.title.blank = 'Custom error message'`. This requires some configuration on your part. You have to tell Caprese where to look by setting `Caprese.config.i18n_scope = 'api.v1.errors'`

Caprese looks for translations in the following order, and if none of them are defined, it will use `code.to_s` as the error message:

```
# for field errors (attribute or relationship)
api.v1.errors.models.[model_name].[field].[code]
api.v1.errors.field.[code]
api.v1.errors.[code]

# for errors on base
api.v1.errors.models.[model_name].[code]
api.v1.errors.[code]
```

#### Controller errors

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

Caprese provides a helper method to easily create controller errors that can have their own translation scope. If at any point in your control flow, say in a callback, you want to immediately halt the request and respond with an error message, you can do the following:

```
fail error(
  field: :filter,
  code: :invalid,
  t: { ... } # translation interpolation variables to use in the error message
)
```

Caprese will search for controller errors in the following order, and if none of them are defined, it will use `code.to_s` as the error message:

```
api.v1.errors.controllers.[controller].[action].[field].[code]
api.v1.errors.controllers.[controller].[action].[code]
api.v1.errors.[code]
```

#### Customizing your error and error message

The raw error object for Caprese is as follows:

```
fail Error.new(
  model: ...,      # model name
  controller: ..., # only model name || controller && action should be provided, not both
  action: ...,
  field: ...,
  code: :invalid,
  t: { ... }       # translation interpolation variables to use in the error message
)
```

Two translation interpolation variables will be provided for you automatically, on top of whatever ones you pass in. Those two are: `%{field}` and `%{field_title}`. If `field == :my_title`, `%{field} == my_title` and `%{field_title} == My Title`

### Configuration

As a guide to configuring Caprese, here is the portion of `lib/caprese.rb` that stores the defaults:

```
# Defines the primary key to use when querying records
config.resource_primary_key ||= :id

# Define URL options for use in UrlHelpers
config.default_url_options ||= {}

# If true, relationship data will not be serialized unless it is in `include`, huge performance boost
config.optimize_relationships ||= true

# Defines the translation scope for model and controller errors
config.i18n_scope ||= '' # 'api.v1.errors'

# The default size of any page queried
config.default_page_size ||= 10

# The maximum size of any page queried
config.max_page_size ||= 100
```

You should also look into the configuration for [ActiveModelSerializers](https://github.com/rails-api/active_model_serializers/blob/master/docs/general/configuration_options.md) to customize the serializer behavior further.

### Overriding an action while still using Caprese helpers

Coming soon... :)

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nicklandgrebe/caprese.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
