# ActiveModelAttributes [![Build Status](https://travis-ci.org/Azdaroth/active_model_attributes.svg?branch=master)](https://travis-ci.org/Azdaroth/active_model_attributes) [![Gem Version](https://badge.fury.io/rb/active_model_attributes.svg)](https://rubygems.org/gems/active_model_attributes) [![Coverage Status](https://coveralls.io/repos/github/Azdaroth/active_model_attributes/badge.svg)](https://coveralls.io/github/Azdaroth/active_model_attributes)

Rails 5.0 comes with a great addition of ActiveRecord Attributes API. However, that's only for ActiveRecord, you can't really use it in your ActiveModel models. Fortunately, with this gem it's possible.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_model_attributes'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_model_attributes

## Usage

Define you ActiveModel model class, include `ActiveModel::Model` and `ActiveModelAttributes` modules and define attributes and their types using `attribute` class method:

``` rb
class MyAwesomeModel
  include ActiveModel::Model
  include ActiveModelAttributes

  attribute :integer_field, :integer
  attribute :string_field, :string
  attribute :decimal_field, :decimal
  attribute :boolean_field, :boolean
end
```

You can also provide a default value for each attribute (either a raw value or a lambda):

``` rb
class MyAwesomeModel
  include ActiveModel::Model
  include ActiveModelAttributes

  attribute :string_with_default, :string, default: "default string"
  attribute :date_field, :date, default: -> { Date.new(2016, 1, 1) }
end
```

You can get the list of defined attributes, their types and provided options by accessing `attributes_registry` class attribute, for instance:

``` rb
class MyAwesomeModel
  include ActiveModel::Model
  include ActiveModelAttributes

  attribute :string_with_default, :string, default: "default string"
end
```

```
MyAwesomeModel.attributes_registry
=> { string_with_default: [:string, { default: "default string" }] }
```

Here's a list of supported types:

* big_integer
* binary
* boolean
* date
* datetime
* decimal
* float
* immutable_string
* integer
* string
* text
* time

You can also add your custom types. Just create a class inheriting from `ActiveModel::Type::Value` or already existing type, e.g. `ActiveModel::Type::Integer`, define `cast` method and register the new type:

``` rb
class SomeCustomMoneyType < ActiveModel::Type::Integer
  def cast(value)
    return super if value.kind_of?(Numeric)
    return super if !value.to_s.include?('$')

    price_in_dollars = BigDecimal.new(value.gsub(/\$/, ''))
    super(price_in_dollars * 100)
  end
end

ActiveModel::Type.register(:money, SomeCustomMoneyType)
```

Now you can use this type inside you ActiveModel models:

```
class ModelForAttributesTestWithCustomType
  include ActiveModel::Model
  include ActiveModelAttributes

  attribute :price, :money
end

data = ModelForAttributesTestWithCustomType.new
data.price = "$100.12"
data.price
=> 10012
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Azdaroth/active_model_attributes.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

