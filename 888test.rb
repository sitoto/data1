#encoding: UTF-8
require 'mongoid'
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'logger'
require 'pp'

Dir.glob("#{File.dirname(__FILE__)}/app/models/*.rb") do |lib|
  require lib
end


ENV['MONGOID_ENV'] = 'local'

Mongoid.load!("config/mongoid.yml")

class IoFactory
	attr_reader :file
	def self.init file
		@file = file
		if @file.nil?
			puts 'Can Not Init File To Write'
			exit
		end #if
		File.open @file, 'a'
	end     
end #IoFactory
class String 
		#替换<br> 为 文本的 换行 
    def br_to_new_line  
        self.gsub('<br>', "\n")  
    end  
    def p_to_new_line  
        self.gsub('</p>', "\n")  
    end  
		#去掉所有的html标签，但是保留 文字
    def strip_tag  
        self.gsub(%r[<[^>]*>], '')  
    end  
		#去掉所有 html标签，不保留文字 
		def strip_all_tag
			self.gsub(%r[<.*>], '')
		end
		#去掉 某些 后 然后再去掉 。。。
		def strip_51job_tag
			self.gsub(%r[<br.*], '').gsub(%r[<[^>]*>], '')
		end
end #String 

def safe_open(url, retries = 5, sleep_time = 0.42,  headers = {})
  begin  
      html = open(url).read  
	rescue StandardError,Timeout::Error, SystemCallError, Errno::ECONNREFUSED #有些异常不是标准异常  
      puts $!  
      retries -= 1  
      if retries > 0  
        sleep sleep_time and retry  
      else  
        logger.error($!)
        #错误日志
        #TODO Logging..  
      end  
  end
end

class Spider
  def initialize(first_page)
    url = first_page
    @next_page = 0
    @max_page = 1
    fetch_list(url)
    max_list_page_num
  end
  
  def create_file_to_write(name = 'file')
    file_path = File.join('.', "#{name}-#{Time.now.to_formatted_s(:number) }.txt")
    @file_to_write = IoFactory.init(file_path)
  end #create_file_to_write
  
  def do_get_list
    loop do
      break if @next_page >= @max_page
      puts "当前页：#{@next_page} 共计 #{@max_page} 页"
      fetch_list(next_list_page)
      get_details_url_list
    end
  end
  def do_get_detail
    get_details_content
  end
  

  
  def get_all_next_level_auto_motive
    create_file_to_write('autohome_category')
    
    #new_autos = []
    @automotives = AutoMotive.where(:parent_auto_motive => nil, :from_site => '亚马逊')
        
    @automotives.each_with_index do |auto, i|
      #new_autos << auto
      puts auto.name
      @file_to_write.puts "#{'  '*auto.level}#{i+1}、#{auto.name}"
      get_next(auto, 1)

      #break
        #@file_to_write.puts  "#{'  '*auto.level}#{auto.name}"
      
    end
 
  end
  def get_next(auto, i)
    i += 1        
    puts "level #{ i}"
    puts "next level items #{auto.child_auto_motives.length}"
    return if auto.child_auto_motives.length == 0
    
    auto.child_auto_motives.each_with_index do |item, j|
      puts "#{'  '*item.level}#{item.name}"
      @file_to_write.puts "#{'  '*item.level}#{j+1}、#{item.name}"
      get_next(item,  i)
    end
    
 #   auto.child_auto_motives.each do |item|
 #       puts "the next automotive #{item.name}"
 #       get_next(item,  i)
 #   end
  end
  
  def get_details_content
    @article = Article.all.desc(:created_at).where(:status => 'init')
    
    puts @article.count
    
    @article.each do |article|
      puts article.name
      fetch_detail(article.url)
      article.content = @detail_doc.at_xpath('//div[@class="articleContent"]').to_s
      article.content_txt = article.content.strip_tag
      article.tags = @detail_doc.xpath('//div[@class="arelated"]/dl/dt/p')[1].to_s.strip_tag
      article.status = "completed"
      article.save
      #break
    end
  end
  
  def fetch_list(url)
    @url = url
    @doc = nil
    html_stream = safe_open(url , retries = 3, sleep_time = 0.2, headers = {})
    @doc = Nokogiri::HTML(html_stream)
  end
  def fetch_detail(detail_url)
    @detail_doc = nil
    html_stream = safe_open(detail_url , retries = 3, sleep_time = 0.2, headers = {})
    @detail_doc = Nokogiri::HTML(html_stream)
  end
  
  def max_list_page_num
    puts @doc.at_css('title')
    @max_page = 1
  end
  
  def next_list_page
    #html_stream = safe_open(@url , retries = 3, sleep_time = 0.2, headers = {})
    #@doc = Nokogiri::HTML(html_stream)
    @next_page += 1
    
    current_page = "http://www.amazon.cn/gp/bestsellers/automotive/"
  end

end

firstpage = 'http://www.amazon.cn/gp/bestsellers/automotive/'

#Spider.new(firstpage).do_get_list
Spider.new(firstpage).get_all_next_level_auto_motive
