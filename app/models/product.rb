class Product
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, type: String
  field :price, type: String
  field :small_image_url, type: String
  field :from_site, type: String  
  field :url, type: String
  field :comment_info, type: String  

  
  field :brand, type: String
  field :description, type: String
  field :category, type: String 
  field :category_1, type: String
  field :category_2, type: String
  field :status, type: String
  field :middle_image_url, type: String
  field :big_image_url, type: String

  
  
  embeds_many :parameters
  belongs_to :auto_motive
end
