require_relative 'db_connection'
require_relative '01_mass_object'
require 'active_support/inflector'
# require_relative '00_attr_accessor_object.rb'

class MassObject
  def self.parse_all(results)
    [].tap do |ans|
      results.each do |result|
       ans << self.new(result)
      end
    end
  end
end

class SQLObject < MassObject
  def self.columns
    columns = DBConnection.execute2(<<-SQL)
    SELECT *
    FROM #{self.table_name}
    SQL
    column_names = columns.first

    column_names.each do |column_name|
      define_method(column_name) {attributes[column_name.to_sym] }
      define_method("#{column_name}=") {|val| attributes[column_name.to_sym] = val}
    end
  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name
  end

  def self.table_name
    if @table_name.nil?
      self.table_name = name.to_s.underscore.downcase.pluralize
    else
      @table_name
    end
  end

  def self.all
    #parse_all on all this
    self.parse_all(DBConnection.execute(<<-SQL)
    SELECT *
    FROM #{self.table_name}
    SQL
    )
  end

  def self.find(id)
    self.parse_all(DBConnection.execute(<<-SQL, id)
    SELECT *
    FROM #{self.table_name}
    WHERE id = ?
    LIMIT 1
    SQL
    ).first
  end

  def attributes
    @attributes||= {}
    # if @attributes.nil?
#       @attributes = {}
#     else
#       @attributes
#     end
  end

  def insert
    col_names = self.attributes.keys
    question_marks = ["?"]*col_names.length
    question_marks = "(" + question_marks.join(",")+ ")"
    col_names = "(" + col_names.join(",") + ")"


    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO #{self.class.table_name} #{col_names}
    VALUES #{question_marks}
    SQL

    self.id = DBConnection.instance.last_insert_row_id
  end

  def initialize(params = {})
    @column_names ||= self.class.columns.map(&:to_sym)
    symbol = :a

    params.each do |attr_name,value|
      symbol = attr_name.to_sym
      if @column_names.include?(symbol)
        self.attributes[symbol] = value
      else
        raise "unknown attribute #{attr_name}"
      end
    end
  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end

  def update
    set_line = self.attributes.keys.map {|key| "#{key} = ?"}

   DBConnection.execute(<<-SQL, *attribute_values, self.id)
   UPDATE #{self.class.table_name}
     SET #{set_line.join(",")}
   WHERE id = ?
     SQL
  end

  def attribute_values
    @attributes.values
  end
end
