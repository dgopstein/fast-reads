#! /usr/bin/ruby

require 'open-uri'

Book = Struct.new(:title, :url, :pages, :rating) do
  def update_info
    sleep 1
    host = 'http://www.goodreads.com'
    html = open(host+url).read
    p url
    rating_r = %r|<span class="average" itemprop="ratingValue">([^<])</span>|
    @rating = html.scan(rating_r).first
  end
end

def book_list
  url = 'http://www.goodreads.com/list/show/264.Books_That_Everyone_Should_Read_At_Least_Once'
  html = open(url).read
  #regex = %r|<span itemprop="name">([^<]*)</span>| # Double-quotes around "name" returns authors, not titles!!!
  url_r = %r|<a href="([^"*]*)" class="bookTitle" itemprop="url">|
  title_r = %r|<span itemprop='name'>([^<]*)</span>|
  book_r = /#{url_r}.*?#{title_r}/m
  matches = html.scan(book_r)

  books = matches.map{|tup| Book.new(*tup.reverse)}
end

book_list.take(5).each(&:update_info)

p book_list

