require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'
# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
    #makes a constant. object.model_class returns Human
  end

  def table_name
    model_class.table_name
    #gets class Human method table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    default = {
      class_name: name.to_s.camelcase,
      foreign_key: "#{name}_id".to_sym,
      primary_key: :id
    }
    params = default.merge(options)

    params.each do |key, val|
      instance_variable_set("@#{key}", val)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    default = {
      class_name: name.to_s.singularize.camelcase,
      foreign_key: "#{self_class_name.to_s.singularize.underscore}_id".to_sym,
      primary_key: :id
    }
    params = default.merge(options)

    params.each do |key, val|
      instance_variable_set("@#{key}", val)
    end
  end
end

module Associatable
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      options = self.class.assoc_options[name]
      foreign_key = options.foreign_key #this returns :owner_id but i need the value
      model_class = options.model_class #human
      model_class.find(self.send(foreign_key))
    end
  end

  def has_many(name, options = {})
    self.assoc_options[name] = HasManyOptions.new(name, self, options)

    define_method(name) do
      options = self.class.assoc_options[name]
      foreign_key = options.foreign_key #owner_id
      model_class = options.model_class #Cat
      result = [] #cats
      model_class.all.each do |ref|
        result << ref if ref.send(foreign_key) == self.id
      end
      result
    end
  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  extend Associatable
end
