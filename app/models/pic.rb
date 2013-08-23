class Pic
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, :type => String
  field :url, :type => String

  embedded_in :car
end