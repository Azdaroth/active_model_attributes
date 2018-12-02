require "active_model_attributes/version"
require "active_support/concern"
require "active_model/type"

module ActiveModelAttributes
  extend ActiveSupport::Concern

  delegate :type_for_attribute, :has_attribute?, to: :class

  included do
    class_attribute :attributes_registry, instance_accessor: false
    self.attributes_registry = {}
  end

  module ClassMethods
    NO_DEFAULT_PROVIDED = Object.new
    SERVICE_ATTRIBUTES = %i(default user_provided_default).freeze
    private_constant :NO_DEFAULT_PROVIDED

    def attribute(name, cast_type = ActiveModel::Type::Value.new, **options)
      self.attributes_registry = attributes_registry.merge(name => [cast_type, options])

      define_attribute_reader(name, options)
      define_attribute_writer(name, cast_type, options)
    end

    def define_attribute_reader(name, options)
      wrapper = Module.new do
        provided_default = options.fetch(:default) { NO_DEFAULT_PROVIDED }
        define_method name do
          return instance_variable_get("@#{name}") if instance_variable_defined?("@#{name}")
          return if provided_default == NO_DEFAULT_PROVIDED
          provided_default.respond_to?(:call) && provided_default.call || provided_default
        end
      end
      include wrapper
    end

    def define_attribute_writer(name, cast_type, options)
      wrapper = Module.new do
        define_method "#{name}=" do |val|
          if cast_type.is_a?(Symbol)
            cast_type = ActiveModel::Type.lookup(cast_type, **options.except(*SERVICE_ATTRIBUTES))
          end
          deserialized_value = cast_type.cast(val)
          instance_variable_set("@#{name}", deserialized_value)
        end
      end
      include wrapper
    end

    def type_for_attribute attr
      type_desc = attributes_registry[attr.intern]
      return ActiveModel::Type::Value.new unless type_desc.present?

      if type_desc[0].is_a?(Symbol)
        type, options = type_desc
        ActiveModel::Type.lookup(type, **options.except(*SERVICE_ATTRIBUTES))
      else
        type_desc[0]
      end
    end

    def has_attribute? attr
      attributes_registry.key?(attr.intern)
    end
  end
end
