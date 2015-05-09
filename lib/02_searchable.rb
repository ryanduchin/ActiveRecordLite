require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.keys.map {|col| "#{col} = ?"}.join(" AND ")
    results = DBConnection::execute(<<-SQL, params.values)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_line}
    SQL
    parse_all(results)
  end
end

class SQLObject
  extend Searchable
  #include makes it to methods are INSTANCE methods
  #extend makes it so methods are CLASS methods
end
