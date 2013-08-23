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


ENV['MONGOID_ENV'] = 'localcar'

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
  
  def get_details_url_list
    #create_file_to_write('detail')
    puts category = @doc.at_css("h1").text()
    #@file_to_write.puts  @doc.at_xpath('//div[@id="result_0"]')
    @doc.xpath('//div[@class="productTitle"]').each do |item|
      
      puts  url = detail_url = item.at_xpath('a/@href').to_s
      @product = Product.find_or_create_by(:url => url)
      @product.from_site = '亚马逊'
      
      
      puts  item.at_xpath('a/text()').to_s
      puts  image_url = item.at_xpath('a/img/@src').to_s
      @product.small_image_url =  image_url
      #fetch detail web page content
      fetch_detail(detail_url)

      comment_info = @detail_doc.at_xpath('//div[@class="tiny"]/b/text()').to_s
      
      #break
      name = @detail_doc.at_xpath('//h1/span/text()').to_s
      price = @detail_doc.at_xpath('//span[@id="actualPriceValue"]/b/text()').to_s
      brand = @detail_doc.at_xpath('//form/div[@class="buying"]/a/text()').to_s
      description = @detail_doc.at_xpath('//div[@id="productDescription"]').to_s
      
      @product.description =  description
      puts @product.name =  name
      puts @product.price =  price
      puts @product.brand =  brand
      puts @product.category =  category
      puts @product.comment_info =  comment_info
      
      parameters = []
      j = 0
      @detail_doc.xpath('//div[@id="feature-bullets-btf"]/table/tr/td/div/ul/li/text()').each do |item|
        para = Parameter.new
        para.name = item.to_s.split(':')[0]
        para.value = item.to_s.split(':')[1]
        para.num = j
        para.category = "商品特性"
        
        j += 1
        parameters << para
      end
      
      
      puts max = @detail_doc.xpath('//table[@id="productDetailsTable"]/tr/td/div/ul/li').length
      @detail_doc.xpath('//table[@id="productDetailsTable"]/tr/td/div/ul/li').each_with_index do |base, i|
        next if i > max - 3
        para = Parameter.new
        para.name = base.at_xpath('b/text()').to_s.strip.gsub(':', '')
        para.value = base.at_xpath('text()').to_s.strip
        para.num = i
        para.category = "基本信息"
        
        j += 1
        parameters << para
        
      end
      @product.parameters = parameters
      @product.save
      
      #break

      
    end
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
    @max_page = 8
  end
  
  def next_list_page
    #html_stream = safe_open(@url , retries = 3, sleep_time = 0.2, headers = {})
    #@doc = Nokogiri::HTML(html_stream)
    @next_page += 1
    current_page = "http://www.amazon.cn/s/ref=sr_pg_2?rh=n%3A1947899051%2Cn%3A%211947900051%2Cn%3A2126200051%2Cn%3A255838071%2Cn%3A1948018051%2Cn%3A255839071&page=#{@next_page}&bbn=1948018051&ie=UTF8&qid=1372916120"
  end

end


firstpage = 'http://www.amazon.cn/s/ref=sr_pg_2?rh=n%3A1947899051%2Cn%3A%211947900051%2Cn%3A2126200051%2Cn%3A255838071%2Cn%3A1948018051%2Cn%3A255839071&page=2&bbn=1948018051&ie=UTF8&qid=1372916120'

Spider.new(firstpage).do_get_list



=begin
@url_lists = %w(行车记录仪
机油滤清器
汽油滤清器
空气滤清器
机油
雨刮
雨眉
鲨鱼鳍
LED灯
儿童安全座椅
隔音棉
地盘装甲
轮胎
真皮座椅
真皮方向盘
倒车雷达
燃油添加剂
机油添加剂
防冻液
玻璃水
汽车水
洗车泡沫
)
@url_lists = %w(日间行车灯)
@url_lists = %w(电装火花塞)
@url_lists = %w(NGK火花塞)
@url_lists = %w(刹车片)
@url_lists = %w(刹车盘)
@url_lists = %w(镀膜)
@url_lists = %w(电装喇叭)



#@doc_chery = Nokogiri::HTML(qirui_string)
#@doc_chery.xpath('//dd/a/@href').each_with_index do |item, i|
#	puts "http://car.autohome.com.cn#{item}"
#end
#return

#http://s.taobao.com/search?jc=1&q=%C8%BC%D3%CD%CC%ED%BC%D3%BC%C1&stats_click=search_radio_all%3A1
#http://s.taobao.com/search?spm=a230r.1.8.3.8A95CI&promote=0&sort=sale-desc&tab=all&q=%C8%BC%D3%CD%CC%ED%BC%D3%BC%C1&stats_click=search_radio_all%3A1#J_relative
#http://s.taobao.com/search?jc=1&q=%C8%BC%D3%CD%CC%ED%BC%D3%BC%C1&stats_click=search_radio_all%3A1&promote=0&tab=all&bcoffset=3&s=40#J_relative
#http://s.taobao.com/search?jc=1&q=%C8%BC%D3%CD%CC%ED%BC%D3%BC%C1&stats_click=search_radio_all%3A1&promote=0&tab=all&s=80#J_relative
#http://s.taobao.com/search?jc=1&q=%C8%BC%D3%CD%CC%ED%BC%D3%BC%C1&stats_click=search_radio_all%3A1&promote=0&tab=all&s=120#J_relative
#http://s.taobao.com/search?spm=a230r.1.8.3.PvKvXK&promote=0&sort=sale-desc&initiative_id=staobaoz_20130614&tab=all&q=%F6%E8%D3%E3%F7%A2&stats_click=search_radio_all%3A1#J_relative

@url_lists.each_with_index do |name, i|
  create_file_to_write(name)
  @max_page_num = 2
  0.upto(@max_page_num).each do |num|
    url = "http://s.taobao.com/search?jc=1&promote=0&sort=sale-desc&q=#{name}&stats_click=search_radio_all%3A1&promote=0&tab=all&s=#{num*40}#J_relative"
    url = URI.parse(URI.encode(url))
    puts url
    html_stream = open(url).read.strip
    @doc = Nokogiri::HTML(html_stream)
    
    puts num
    puts max_page_num_str =  @doc.at_css("span.page-info").text.strip
    puts @max_page_num = max_page_num_str.split('/')[1].to_i - 1
    puts things_num_str =  @doc.at_css("li.result-info").text.strip
    next
    puts title =  @doc.at_css("title").text.strip
    

    
    @doc.xpath("//div[@class='item-box']").each_with_index do |item, dd|
    puts dd
     puts title =  item.at_xpath("h3").text.strip
     puts detail_url =  item.at_xpath("h3/a/@href").text.strip
     puts price =  item.at_xpath("div/div[@class='col price']").text
     puts deal =  item.at_xpath("div/div[@class='col dealing']").text.strip
     if item.at_xpath("div/div[@class='col end count']")
      count =  item.at_xpath("div/div[@class='col end count']").text
     else
      count = "0"
     end
      
      seller =  item.at_xpath("div/div[@class='col seller']").text.strip
      loc =  item.at_xpath("div/div[@class='col end loc']").text.strip
      @file_to_write.puts "#{title}\t#{detail_url}\t#{price}\t#{deal}\t#{count}\t#{seller}\t#{loc}"
    end
  end

end

=end