#!/usr/bin/env rvm 2.3 do ruby

require 'fileutils'
require 'open-uri'
require 'yaml'
require 'nokogiri'

Book = Struct.new(:title, :url, :author, :pages, :rating) do
  def update_info
    sleep 0.1
    host = 'http://www.goodreads.com'
    html = open(host+url).read
    rating_r = %r|<span class="average" itemprop="ratingValue">([^<]*)</span>|
    pages_r = %r|<span itemprop="numberOfPages">(\d+) pages</span>|
    self.rating = html.scan(rating_r).first.first.to_f
    self.pages = html.scan(pages_r).first.first.to_i
    self
  end

  def to_s
    '[%1.2f] %4d: %s - %s' % [self.rating, self.pages, self.author, self.title]
  end
end

LIST_CACHE_NAME = 'cache/book_list.yaml'
HTML_CACHE_NAME = 'cache/page.html'

FileUtils.mkdir_p('cache')

def cache_book_list(book_list)
  puts "Writing #{book_list.size} books to file '#{LIST_CACHE_NAME}'"
  File.open(LIST_CACHE_NAME,"w") do |f|
    f.write(YAML::dump(book_list))
  end
end

def read_cached_book_list
  book_list = YAML::load(open(LIST_CACHE_NAME,"r").read)
  puts "Read #{book_list.size} books from file '#{LIST_CACHE_NAME}'"
  book_list
end

def cache_html(html)
  puts "Writing #{html.size} bytes of html to file '#{HTML_CACHE_NAME}'"
  File.open(HTML_CACHE_NAME,"w") do |f|
    f.write(html)
  end
  html
end

def read_cached_html
  html = open(HTML_CACHE_NAME,"r").read
  puts "Read #{html.size} bytes of html from file '#{HTML_CACHE_NAME}'"
  html
end

def download_book_list
  url = 'http://www.goodreads.com/list/show/264.Books_That_Everyone_Should_Read_At_Least_Once'
  open(url).read
end

def parse_html(html)
  doc = Nokogiri::HTML(html)

  books = doc.xpath('//a[@class="bookTitle"]')
  
  books.map do |book|
    url = book.attr('href')
    title = book.xpath('./span[@itemprop="name"]').text
    author = book.xpath('../span[@itemprop="author"]//span[@itemprop="name"]').first.text

    Book.new(title, url, author)
  end
end

def main
  html =
    if File.exists?(HTML_CACHE_NAME)
      read_cached_html
    else
      cache_html(download_book_list)
    end

  book_list =
    if File.exists?(LIST_CACHE_NAME)
      read_cached_book_list
    else
      b_list = parse_html(html)
      b_list.each(&:update_info)
      cache_book_list(b_list)
      b_list
    end

  puts book_list.sort_by(&:pages).each_with_index.map{|b, i| '%3d %s'%[i, b]}.join("\n")
end

main if __FILE__ == $0
