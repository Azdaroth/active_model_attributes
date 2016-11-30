require "spec_helper"
require "active_model"

describe ActiveModelAttributes do
  class ModelForAttributesTest
    include ActiveModel::Model
    include ActiveModelAttributes

    attribute :integer_field, :integer
    attribute :string_field, :string
    attribute :decimal_field, :decimal
    attribute :string_with_default, :string, default: "default string"
    attribute :date_field, :date, default: -> { Date.new(2016, 1, 1) }
    attribute :boolean_field, :boolean
  end

  class ChildModelForAttributesTest < ModelForAttributesTest
  end

  class GrandchildModelForAttributesTest < ChildModelForAttributesTest
    attribute :integer_field, :string
  end

  class SomeCustomMoneyType < ActiveModel::Type::Integer
    def deserialize(value)
      return super if value.kind_of?(Numeric)
      return super if !value.to_s.include?('$')

      price_in_dollars = BigDecimal.new(value.gsub(/\$/, ''))
      super(price_in_dollars * 100)
    end
  end
  ActiveModel::Type.register(:money, SomeCustomMoneyType)

  class ModelForAttributesTestWithCustomType
    include ActiveModel::Model
    include ActiveModelAttributes

    attribute :price, :money
  end

  it "handles attributes assignment with proper type and with proper defaults" do
    data = ModelForAttributesTest.new(
      integer_field: "2.3",
      string_field: "Rails FTW",
      decimal_field: "12.3",
      boolean_field: "0"
    )

    expect(data.integer_field).to eq 2
    expect(data.string_field).to eq "Rails FTW"
    expect(data.decimal_field).to eq BigDecimal.new("12.3")
    expect(data.string_with_default).to eq "default string"
    expect(data.date_field).to eq Date.new(2016, 1, 1)
    expect(data.boolean_field).to eq false

    data.integer_field = 10
    data.string_with_default = nil
    data.boolean_field = "1"

    expect(data.integer_field).to eq 10
    expect(data.string_with_default).to eq nil
    expect(data.boolean_field).to eq true
  end

  it "raises error when assigning nonexistent attribute" do
    expect {
      ModelForAttributesTest.new(nonexistent: "nonexistent")
    }.to raise_error ActiveModel::UnknownAttributeError
  end

  it "handles attributes inheritance" do
    data = ChildModelForAttributesTest.new(integer_field: "4.4")

    expect(data.integer_field).to eq 4
  end

  it "handles overriding of attributes in children from parents" do
    data = GrandchildModelForAttributesTest.new(integer_field: "4.4")

    expect(data.integer_field).to eq "4.4"
  end

  it "has registry of attributes with passed options" do
    expected_attributes_keys = [
      :integer_field,
      :string_field,
      :decimal_field,
      :string_with_default,
      :date_field,
      :boolean_field
    ]
    registry = GrandchildModelForAttributesTest.attributes_registry

    expect(registry.keys).to eq expected_attributes_keys
    expect(registry[:integer_field]).to eq [:string, {}]
    expect(registry[:decimal_field]).to eq [:decimal, {}]
    expect(registry[:string_with_default]).to eq [:string, { default: "default string" }]
    expect(registry[:date_field].last[:default].call).to eq Date.new(2016, 1, 1)
  end

  it "works with custom types" do
    data = ModelForAttributesTestWithCustomType.new

    expect(data.price).to eq nil

    data.price = "$100.12"

    expect(data.price).to eq 10012
  end
end
