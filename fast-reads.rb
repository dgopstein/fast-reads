#! /usr/bin/ruby

require 'open-uri'
require 'yaml'

Book = Struct.new(:title, :url, :pages, :rating) do
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
    "[%1.2f] %4d - #{self.title}"%[self.rating, self.pages]
  end
end

CACHE_NAME = "cached_book_list.yaml"

def cache_book_list(book_list)
  puts "Writing #{book_list.size} books to file '#{CACHE_NAME}'"
  File.open(CACHE_NAME,"w") do |f|
    f.write(YAML::dump(book_list))
  end
end

def read_cached_book_list
  book_list = YAML::load(open(CACHE_NAME,"r").read)
  puts "Read #{book_list.size} books from file '#{CACHE_NAME}'"
  book_list
end

def download_book_list
  url = 'http://www.goodreads.com/list/show/264.Books_That_Everyone_Should_Read_At_Least_Once'
  html = open(url).read
  #regex = %r|<span itemprop="name">([^<]*)</span>| # Double-quotes around "name" returns authors, not titles!!!
  url_r = %r|<a href="([^"*]*)" class="bookTitle" itemprop="url">|
  title_r = %r|<span itemprop='name'>([^<]*)</span>|
  book_r = /#{url_r}.*?#{title_r}/m
  matches = html.scan(book_r)

  books = matches.map{|tup| Book.new(*tup.reverse)}
end

def main
  book_list =
    if File.exists?(CACHE_NAME)
      read_cached_book_list
    else
      book_list = download_book_list
      book_list.each(&:update_info)
      cache_book_list(book_list)
      book_list
    end

   puts book_list.sort_by(&:pages).each_with_index.map{|b, i| '%3d %s'%[i, b]}.join("\n")
  
end

main
