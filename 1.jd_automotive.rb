#encoding: UTF-8
require 'mongoid'
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'pp'
require "cgi"
require_relative "common"

Dir.glob("#{File.dirname(__FILE__)}/app/models/*.rb") do |lib|
  require lib
end
ENV['MONGOID_ENV'] = 'local'
Mongoid.load!("config/mongoid.yml")

class GetCarAndDetail
  include Common
  
  def initialize(sid = "", maker = "", from_site ="")
    @sid = sid
    @maker = maker
    @from_site = from_site
  end
  
  def read_category
    url = "http://channel.jd.com/auto.html"
    @doc = fetch_doc(url)
    status = 'init'
    @max_batch = AutoMotive.where(:from_site => @from_site).desc(:batch).first
    if @max_batch.nil?
      puts batch = 1
    else
      puts batch = @max_batch.batch + 1
    end    
#=begin    
    @doc.xpath('//div[@id="sortlist"]/div[@class="mc"]/div').each do |item|
      
      puts cat = item.at_xpath('h3/a/text()').to_s.strip
      puts link = item.at_xpath('h3/a/@href').to_s.strip
      
   
      @automotive = AutoMotive.find_or_create_by(:link => link)
      @automotive.name = cat
      @automotive.url = url
      @automotive.from_site = @from_site
      @automotive.level = 1
      @automotive.batch = batch
      @automotive.parent_auto_motive = ""
      @automotive.save
     next

      #puts item.at_xpath('h3/a/text()').to_s.strip.split(' ')[0]
    end
#=end
    @automotives = AutoMotive.where(:parent_auto_motive => nil, :from_site => @from_site)
    @automotives.each do |auto|
      puts auto.link
      current_auto = auto
      @doc_detail = fetch_doc(current_auto.link)
      @doc_detail.xpath('//div[@id="sortlist"]/div[@class="mc"]/div/ul/li/a').each do |object|
        
        puts cat = object.at_xpath('text()').to_s.strip
        puts link = object.at_xpath('@href').to_s.strip
        am = AutoMotive.find_or_create_by(:link => link, :from_site => @from_site)
        
        am.name = cat
        am.url = url
        am.level = 2
        am.batch = batch
        am.parent_auto_motive = auto
        am.save        
      end
      
    
    end
    
  end

  def report
    create_file_to_write('jd_category')

    #new_autos = []
    @automotives = AutoMotive.where(:parent_auto_motive => nil, :from_site => @from_site)
        
    @automotives.each_with_index do |auto, i|
      #new_autos << auto
      puts auto.name
      @file_to_write.puts "#{'  '*auto.level}#{i+1}.#{auto.name}"
      auto.child_auto_motives.each_with_index do |object, j|
        @file_to_write.puts  "#{'  '*object.level}#{j+1}.#{object.name}"
      end
    end

  end
  def do_get_list(list_page = "")
    create_file_to_write('doing-jd')
    @auto_motives = AutoMotive.where(:from_site => @from_site, :parent_auto_motive.ne => nil)#.desc(:id)
    puts @auto_motives.length
    @auto_motives.each_with_index do |auto, iii|
      #next if iii < 50
      @file_to_write.puts "#{iii}-#{auto.name}"
      #next
      @next_page = 1
      
      puts auto.link   
      # get this page content
      url = auto.link
      
      doc_brand = fetch_doc(url)
      #pp doc_brand.at_xpath("//dl[@id='select-brand']/dd/div[@class='content']/div")
      puts doc_brand.xpath("//dl[@id='select-brand']/dd/div[@class='content']/div//a").length
      #return
      doc_brand.xpath("//dl[@id='select-brand']/dd/div[@class='content']/div//a").each do |bra|
        url = bra.at_xpath("@href").to_s.strip
        puts url = "http://list.jd.com/#{url}"
        puts brand = bra.at_xpath("text()").to_s.strip
        next if "不限" == brand
        #break
        doc = fetch_doc(url)
        
        loop do
          doc.xpath("//ul[@class='list-h']/li").each do |item|
            ## http://list.jd.com/6728-6740-9962-0-0-0-0-0-0-0-1-1-9-1.html
            ## run....
            ## get the list's product's value .http://item.jd.com/1031236075.html
            #puts item.to_s
            
            puts name = item.at_xpath("div[@class='p-name']/a/text()").to_s.strip
            puts sku = item.at_xpath("@sku").to_s.strip
            puts small_image_url = item.at_xpath("div[@class='p-img']/a/img/@src").to_s.strip
            puts from_site = @from_site
            puts url = item.at_xpath("div[@class='p-name']/a/@href").to_s.strip
            comment_info = item.at_xpath("div[@class='extra']/span/a/text()").to_s.strip
            puts comment_info += item.at_xpath("div[@class='extra']/span/text()").to_s.strip
            
            str = open_http("http://p.3.cn/prices/mgets?skuIds=J_#{sku}")
            str_json = JSON.parse(str)
            puts price = str_json[0]["p"]
            
            doc_p = fetch_doc(url)
            puts doc_p.at_xpath("//title").to_s
            
            ##http://item.jd.com/1025150889.html
            ## get details of the product
            ## running
            ##Done at today!!! keep on working
            
            parameters
            description
            category
            status
            
            break
            #use this link tu get the price  
            #http://p.3.cn/prices/mgets?skuIds=J_1025150889,J_1017687832,J_1015592059,J_928113,J_931077,J_917673,J_850886,J_860482,J_1017687835,J_1015022202,J_1017687834,J_917672,J_1017826031,J_881621,J_1012866707,J_860481,J_1015383764,J_1024764149,J_928112,J_1017687833,J_1025219562,J_905474,J_881632,J_881620,J_1019320502,J_881629,J_905484,J_1030767618,J_934609,J_892612,J_1018309600,J_1016776438,J_881630,J_1014922630,J_864985,J_839040&type=1
            # return [{"id":"J_1025150889","p":"399.00","m":"1198.00"},{"id":"J_1017687832","p":"358.00","m":"1280.00"}]
            #http://p.3.cn/prices/mgets?skuIds=J_1025150889
            # return [{"id":"J_1025150889","p":"399.00","m":"1198.00"}]  
            
          end #end of xpath
          # delete it
          break
          
          # get the next page
          link = doc.at_xpath("//a[@class='next']/@href")
          url = link && link.to_s
          puts url
          break if url.nil?
          url = "http://list.jd.com/#{url}"
          doc = fetch_doc(url)
        end
        break
      end # end of brand
      break
      
      # get the list
      # get the detail
      # loop  the the next page
    end # end of category
  end
  
  
  private  
  def create_file_to_write(name = 'file')
    file_path = File.join('.', "#{name}-#{Time.now.to_formatted_s(:number) }.txt")
    @file_to_write = IoFactory.init(file_path)
  end #create_file_to_write
  
  def fetch_doc(detail_url)
    html_stream = safe_open(detail_url , retries = 3, sleep_time = 0.2, headers = {})
#    begin
    html_stream.encode!('utf-8', 'gbk', :invalid => :replace) #忽略无法识别的字符
#    rescue StandardError,Timeout::Error, SystemCallError, Errno::ECONNREFUSED #有些异常不是标准异常  
#     puts $!  
#    end
    Nokogiri::HTML(html_stream)
  end  
  
  def download_images(pre_folder, filename, url)
    begin
      File.open("./#{pre_folder}/#{filename}", "wb") do |saved_file|
        open(url, 'rb') do |read_file|
        saved_file.write(read_file.read)
        end
      end  
    rescue OpenURI::HTTPError, StandardError,Timeout::Error, SystemCallError, Errno::ECONNREFUSED
      puts $! 
      @file_to_write.puts $! 
    end
    
  end
  
  def fetch_img(detail_url)
    @doc_img = nil
    html_stream = safe_open(detail_url , retries = 3, sleep_time = 0.38, headers = {})
    @doc_img = Nokogiri::HTML(html_stream)
  end
  
  def open_http(detail_url)
    safe_open(detail_url , retries = 3, sleep_time = 0.42, headers = {})
  end
  
  
end


sid = '1073' 
maker = "京东"
folder = "jingdong"
from_site = "京东"

#GetCarAndDetail.new(sid, maker, from_site).read_category
#GetCarAndDetail.new(sid, maker, from_site).report
GetCarAndDetail.new(sid, maker, from_site).do_get_list


