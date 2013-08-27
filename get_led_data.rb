#encoding: UTF-8
require 'mongoid'
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'pp'
require_relative "common"

Dir.glob("#{File.dirname(__FILE__)}/app/models/*.rb") do |lib|
  require lib
end
ENV['MONGOID_ENV'] = 'local'
Mongoid.load!("config/mongoid.yml")

class Spider
  include Common
  
  def initialize(site ="")
    @from_site = site
    @i = 0
  end
  def run
    get_list
  end
  def get_list
   create_file_to_write("report", "report")
   1.upto(26).each do |n|
      puts url  = "http://www.tonglujia.com/cn/Products.asp?keywords=&Xcol=1&bcol=103&page=#{n}"
      doc = fetch_doc(url)
      doc.xpath('//td[@rowspan="2"]').each do |item|
        puts name = item.at_xpath("table/tr/td/a/strong/text()").to_s
        next if name.blank?
        pic_url = item.at_xpath("table/tr/td/a/img/@src").to_s

        product_url = item.at_xpath("table/tr/td/a/@href").to_s
        puts product_url = "http://www.tonglujia.com/cn/#{product_url}"
        puts pic_url = pic_url.gsub("..", "http://www.tonglujia.com")

        pro_doc = fetch_doc(product_url)
        image_url = pro_doc.at_xpath("//img/@src").to_s
        puts image_url = image_url.gsub("..", "http://www.tonglujia.com")
        desc = pro_doc.css("table")[2].text()
        name = name.gsub('/','-')
        back = image_url.split('.')[-1]
        pic_name = "#{name}.#{back}"
        @file_to_write.puts("#{@i}\t#{name}\t#{}")


#        download_images(@i.to_s, pic_name, image_url)
#        create_file_to_write(@i.to_s, name)
#        @file_to_write.puts(desc)

        @i += 1

      end
    end
  end
 
  
  private  
  def create_file_to_write(folder, name = 'file')
    check_folder(folder)

    file_path = File.join("./#{folder}", "#{name}-#{Time.now.to_formatted_s(:number) }.txt")
    @file_to_write = IoFactory.init(file_path)
  end #create_file_to_write
  
  def fetch_doc(detail_url)
    html_stream = safe_open(detail_url , retries = 3, sleep_time = 0.2, headers = {})
#    begin
#    html_stream.encode!('utf-8', 'gbk', :invalid => :replace) #忽略无法识别的字符
#    rescue StandardError,Timeout::Error, SystemCallError, Errno::ECONNREFUSED #有些异常不是标准异常  
#     puts $!  
#    end
    Nokogiri::HTML(html_stream)
  end  
  
  def download_images(pre_folder, filename, url)
    check_folder(pre_folder)

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
  def check_folder(folder)
    if(File.exist?("./#{folder}"))
      puts "folder structure already exist!"
    else
      Dir.mkdir("./#{folder}") #if folder not exist,then creat it.
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


site = "http://www.tonglujia.com"

Spider.new(site).run


