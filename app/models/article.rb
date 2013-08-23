class Article
  include Mongoid::Document
  include Mongoid::Timestamps

  
  field :name, :type => String
  field :content, :type => String
  field :content_txt, :type => String
  field :tags, :type => String
  field :category, :type => String
  
  field :status, :type => String
  
  field :url, :type => String  
  field :from_site, :type => String
  

end
