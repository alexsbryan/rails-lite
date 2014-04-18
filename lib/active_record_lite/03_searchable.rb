require_relative 'db_connection'
require_relative '02_sql_object'
require 'active_support/inflector'

module Searchable
  def where(params)
    where_line = params.keys.map {|key| "#{key} = ?"}
    where_line = where_line.join(" AND ")
    table = self.name.downcase + "s"

    p params.values

    self.parse_all(DBConnection.execute(<<-SQL,*params.values)
    SELECT *
    FROM #{table}
    WHERE #{where_line}

    SQL
    )
  end
end

class SQLObject
  extend Searchable


  # def where(params)
  #  self.parse_all(super(params))
  # end
end
