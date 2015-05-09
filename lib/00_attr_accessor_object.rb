class AttrAccessorObject
  def self.my_attr_accessor(*names)
    # macro creates new methods
    #need to interpolate the name so use define_method AND set/get methods
    names.each do |name|
      define_method("#{name}") { instance_variable_get("@#{name}") }
      define_method("#{name}=") {|val| instance_variable_set("@#{name}", val)}
    end
  end
end
