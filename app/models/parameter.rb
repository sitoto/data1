class Parameter
  include Mongoid::Document
  #include Mongoid::Timestamps
  
  field :name, :type => String
  field :value, :type => String
  field :category, :type => String
  field :num, :type => String
  

  embedded_in :product
end