class AutoMotive
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, type: String
  field :link, type: String  
  field :status, type: String
  field :level

  field :url, type: String
  field :from_site, type: String    
  
  field :batch 
  
  
  has_many :child_auto_motives, :class_name => 'AutoMotive', :inverse_of => :parent_auto_motive
  belongs_to :parent_auto_motive, :class_name => 'AutoMotive', :inverse_of => :child_auto_motives
  
  has_many :products
end
