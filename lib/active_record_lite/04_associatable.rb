require_relative '03_searchable'
require 'active_support/inflector'

# Phase IVa
class AssocOptions
  

  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key,
  )

  def model_class
    class_name.constantize
  end

  def table_name
    class_name.underscore.concat("s")
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
      @foreign_key = options[:foreign_key] || (name.to_s.singularize + "_id").to_sym
      @primary_key =  options[:primary_key] || :id
      @class_name = options[:class_name] || (name.to_s.camelcase.singularize)
  
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    
        @foreign_key = options[:foreign_key] || (self_class_name.to_s.underscore + "_id").to_sym
        @primary_key =  options[:primary_key] || :id
        @class_name = options[:class_name] || (name.to_s.camelcase.singularize)
  
  end
end

module Associatable
  # Phase IVb
  def belongs_to(name, options = {})
    belongs_options = BelongsToOptions.new(name, options)
    assoc_options[name] = belongs_options
    define_method(name) do
      query = <<-SQL
      SELECT *
      FROM #{belongs_options.table_name}
      WHERE #{belongs_options.table_name}.#{belongs_options.primary_key} = ?
      SQL

      results = DBConnection.execute(query,send(belongs_options.foreign_key))
      belongs_options.model_class.parse_all(results).first
    end
  end

  def has_many(name, options = {})
    self.assoc_options[name] =
      HasManyOptions.new(name, self.name, options)

    define_method(name) do
      options = self.class.assoc_options[name]

      key_val = self.send(options.primary_key)
      options
        .model_class
        .where(options.foreign_key => key_val)
    end
  end

  def assoc_options
    @assoc_options || @assoc_options = {}
  end
end

class SQLObject
  extend Associatable
end
