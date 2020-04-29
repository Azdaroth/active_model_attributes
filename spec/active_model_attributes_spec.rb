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
    attribute :boolean_with_type, ActiveModel::Type::Boolean.new
    attribute :mutable_field, ActiveModel::Type::Value.new, default: -> { {some_array: []} }
  end

  class ChildModelForAttributesTest < ModelForAttributesTest
  end

  class GrandchildModelForAttributesTest < ChildModelForAttributesTest
    attribute :integer_field, :string
  end

  class SomeCustomMoneyType < ActiveModel::Type::Integer
    def cast(value)
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

  class CustomStructWithOptionableType
    include ActiveModel::Model
    include ActiveModelAttributes

    attribute :setting, :integer
    attribute :something_else, :string
  end

  class CustomStructWithOptionsType < ActiveModel::Type::Value

    attr_reader :setting

    def initialize(options={})
      @setting = options.delete(:setting)
      super(options)
    end

    def cast(value)
      case value
      when Hash
        CustomStructWithOptionableType.new(value.merge(setting: @setting))
      else
        CustomStructWithOptionableType.new(setting: @setting)
      end
    end
  end

  ActiveModel::Type.register(:custom_struct, CustomStructWithOptionsType)

  class ModelForAttributesTestWithCustomTypeWithOptions
    include ActiveModel::Model
    include ActiveModelAttributes

    attribute :custom_struct1, :custom_struct, setting: 42
    attribute :custom_struct2, :custom_struct, setting: 43
  end

  class ModelForAttributesTestWithOverridenReader
    include ActiveModel::Model
    include ActiveModelAttributes

    attribute :value, :string

    def value
      super.to_s  + " overridden"
    end
  end

  class ModelForAttributesTestWithOverridenWriter
    include ActiveModel::Model
    include ActiveModelAttributes

    attribute :value, :string

    def value=(val)
      super(val.to_s.upcase)
    end
  end

  class ModelForAttributesTestWithDefaultType
    include ActiveModel::Model
    include ActiveModelAttributes

    attribute :value
    attribute :other_value, default: 'foo'
  end

  it "handles attributes assignment with default type and with a default value" do
    data = ModelForAttributesTestWithDefaultType.new(value: { foo: 'bar' })

    expect(data.value).to eq(foo: 'bar')
    expect(data.other_value).to eq 'foo'
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

  it "handles attributes' inheritance" do
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
      :boolean_field,
      :boolean_with_type,
      :mutable_field
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

  it "works with custom types and given specific options" do
    data = ModelForAttributesTestWithCustomTypeWithOptions.new(
      custom_struct1: {something_else: '12'},
      custom_struct2: {something_else: '23'}
    )
    expect(data.custom_struct1.setting).to eq 42
    expect(data.custom_struct2.setting).to eq 43
    expect(data.custom_struct1.something_else).to eq '12'
    expect(data.custom_struct2.something_else).to eq '23'
  end

  it "is possible to use `super` inside attribute reader" do
    data =  ModelForAttributesTestWithOverridenReader.new(value: "value")

    expect(data.value).to eq "value overridden"
  end

  it "is possible to use `super` inside attribute writer" do
    data =  ModelForAttributesTestWithOverridenWriter.new(value: "value")

    expect(data.value).to eq "VALUE"
  end

  it "checks available attributes" do
    data = ModelForAttributesTest.new

    # works with both symbol and string
    expect(data.has_attribute?("integer_field")).to eq true
    expect(data.has_attribute?(:integer_field)).to eq true
    expect(data.has_attribute?("nonexisting_field")).to eq false
    expect(data.has_attribute?(:nonexisting_field)).to eq false
  end

  describe ".attribute_types" do
    it "returns a hash of attribute names with their type information" do
      expect(ModelForAttributesTest.attribute_types['integer_field']).to be_an_instance_of ActiveModel::Type::Integer
      expect(ModelForAttributesTest.attribute_types['string_field']).to be_an_instance_of ActiveModel::Type::String
      expect(ModelForAttributesTest.attribute_types['decimal_field']).to be_an_instance_of ActiveModel::Type::Decimal
      expect(ModelForAttributesTest.attribute_types['boolean_with_type']).to be_an_instance_of ActiveModel::Type::Boolean
    end
  end

  it "returns type information for available attributes" do
    data = ModelForAttributesTest.new

    expect(data.type_for_attribute(:integer_field)).to be_an_instance_of ActiveModel::Type::Integer
    expect(data.type_for_attribute(:string_field)).to be_an_instance_of ActiveModel::Type::String
    expect(data.type_for_attribute(:decimal_field)).to be_an_instance_of ActiveModel::Type::Decimal
    expect(data.type_for_attribute(:boolean_with_type)).to be_an_instance_of ActiveModel::Type::Boolean
  end

  it "returns type information with options for available attributes" do
    data = ModelForAttributesTestWithCustomTypeWithOptions.new

    expect(data.type_for_attribute(:custom_struct1).setting).to be 42
    expect(data.type_for_attribute(:custom_struct2).setting).to be 43
  end

  it "returns type information for nonexistent attributes" do
    data = ModelForAttributesTest.new

    expect(data.type_for_attribute(:nonexistent_field)).to be_an_instance_of ActiveModel::Type::Value
  end

  it "initilizes default values and stores them in instance variables" do
    data = ModelForAttributesTest.new
    expect(data.mutable_field).to eq(some_array: [])
    expect(data.mutable_field.object_id).to eq data.mutable_field.object_id
    object_id = data.mutable_field.object_id
    data.mutable_field[:some_array] << 12
    expect(data.mutable_field.object_id).to eq object_id
    expect(data.mutable_field[:some_array]).to eq [12]
  end
end
