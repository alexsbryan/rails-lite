class AttrAccessorObject
  def self.my_attr_accessor(*names)
    #Getter
    names.each do |name|
      define_method("#{name.to_s}") do
        self.instance_variable_get("@#{name.to_s}")
      end
    end
    #Setter
    names.each do |name|
      define_method("#{name.to_s}=") do |value|
        self.instance_variable_set("@#{name.to_s}", value)
      end
    end

  end
end
