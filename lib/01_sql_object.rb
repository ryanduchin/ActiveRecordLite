require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    #get COLUMNS from TABLES (not just instance variables)
    #returns array of symbols
    DBConnection::execute2(<<-SQL).first.map { |val| val.to_sym }
      SELECT
        *
      FROM
        #{table_name}
    SQL
  end

  def self.finalize!
    columns.each do |col|
      # define_method("#{col}") { instance_variable_get("@#{col}") }
      # define_method("#{col}=") { |val| instance_variable_set("@#{col}", val) }
      define_method("#{col}") { attributes[col] }
      define_method("#{col}=") { |val| attributes[col] = val }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name

  end

  def self.table_name
    @table_name ||= self.to_s.tableize  #also sets it if null...
    # @table_name || self.to_s.tableize  #doesn't set, and passes
  end

  def self.all
    results = DBConnection::execute(<<-SQL)
      SELECT
        #{table_name}.*  --interpolate like this
      FROM
        #{table_name}
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    result = DBConnection::execute(<<-SQL, id)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        #{table_name}.id == ?
    SQL
    return nil if result.empty?
    self.new(result.first)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      #why doesn't this call setter method?
      #there is no literal 'attr_name' accessor method, it isn't interpolated!!
      raise "unknown attribute '#{attr_name}'" if !self.class.columns.include?(attr_name)
      self.send("#{attr_name}=", value)
      #need to interpolate this because not actually called "attr_name ="
      #send (method, arg) to self (instance for instance variable setter) s
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map {|attr_name| self.send("#{attr_name}")}
  end

  def insert
    cols = self.class.columns
    col_names = cols.join(", ")
    question_marks = (["?"] * cols.count).join(", ")
    newobj = DBConnection::execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL
    #don't forget scope of SQL query - needs a self.class to access table name!

    self.id = DBConnection::last_insert_row_id #self is the cat object you are inserting
  end

  def update
    set_line = self.class.columns.map {|col| "#{col} = ?"}.join(", ")
    DBConnection::execute(<<-SQL, *attribute_values, self.id)
    UPDATE
      #{self.class.table_name}
    SET
      #{set_line}
    WHERE
      id = ?
    SQL
    #don't forget scope of SQL query - needs a self.class to access table name!
    #also forgot to interpolate set_line!!!
  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end
end
