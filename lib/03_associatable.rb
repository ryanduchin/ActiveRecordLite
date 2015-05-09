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
    class_name = name.to_s.singularize.capitalize
    foreign_key = (name.to_s.singularize + "Id").underscore.to_sym
    primary_key = :id

    default = {class_name: class_name, foreign_key: foreign_key, primary_key: primary_key}
    params = default.merge(options) #options takes priority

    params.each do |key, val|
      instance_variable_set("@#{key}", val)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    class_name = name.to_s.singularize.capitalize
    foreign_key = (self_class_name.to_s.singularize + "Id").underscore.to_sym
    primary_key = :id

    default = {class_name: class_name, foreign_key: foreign_key, primary_key: primary_key}
    params = default.merge(options) #options takes priority

    params.each do |key, val|
      instance_variable_set("@#{key}", val)
    end
  end
end

module Associatable
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    define_method(name) do
      foreign_key = options.send(:foreign_key) #this returns :owner_id but i need the value
      # p "foreign_key #{foreign_key}"
      referenced_class = self.class
      # p "referenced_class #{referenced_class}"
      model_class = options.send(:model_class) #human
      # p "model_class #{model_class}"
      tableA = referenced_class.table_name #cats
      # p "tableA #{tableA}"
      tableB = model_class.table_name #humans...
      # p "tableB #{tableB}"
      # p "self #{self}"
      target_id = self.send(foreign_key) #cat.owner_id
      # p "cat_id #{cat_id}"

      results = DBConnection.execute(<<-SQL, target_id)
        SELECT
          #{tableB}.*
        FROM
          #{tableB}
        JOIN
          #{tableA} on #{tableA}.#{foreign_key} = #{tableB}.id
        WHERE
          #{tableB}.id = ?
      SQL
      model_class.parse_all(results).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self, options)
    define_method(name) do
      foreign_key = options.send(:foreign_key) #this returns :owner_id but i need the value
      p "foreign_key #{foreign_key}"
      referenced_class = self.class
      p "referenced_class #{referenced_class}"
      model_class = options.send(:model_class) #human
      p "model_class #{model_class}"
      tableA = referenced_class.table_name #cats
      p "tableA #{tableA}"
      tableB = model_class.table_name #humans...
      p "tableB #{tableB}"
      p "self #{self}"
      target_id = self.send(foreign_key) #cat.owner_id

      results = DBConnection.execute(<<-SQL, target_id)
        SELECT
          #{tableB}.*
        FROM
          #{tableB}
        JOIN
          #{tableA} on #{tableA}.#{foreign_key} = #{tableB}.id
        WHERE
          #{tableB}.id = ?
      SQL
      model_class.parse_all(results).first
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end
