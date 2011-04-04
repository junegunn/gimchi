#!/usr/bin/env ruby
# encoding: UTF-8
# Junegunn Choi (junegunn.c@gmail.com)
# 2011/04/02-

# A dirty little script to fetch test sets from http://www.korean.go.kr

require 'open-uri'
require 'yaml'

# Crawl romanization test set
rdata = open('http://www.korean.go.kr/09_new/dic/rule/rule_roman_0101.jsp').read.
	scan(%r{th>(.*?)</td}m).flatten.map { |e| e.split %r{<.*>}m }.
	select { |e| e.length == 2 }

File.open(File.dirname(__FILE__) + '/../test/romanization.yml', 'w') do | f |
	f.puts "---"

	rdata.each do | arr |
		f.puts "\"#{arr.first}\": \"#{arr.last}\""
	end
end

exit

# Crawl pronunciation test set
m = {}
%w[
	http://www.korean.go.kr/09_new/dic/rule/rule02_0202.jsp
	http://www.korean.go.kr/09_new/dic/rule/rule02_0204.jsp
	http://www.korean.go.kr/09_new/dic/rule/rule02_0205.jsp
	http://www.korean.go.kr/09_new/dic/rule/rule02_0206.jsp
	http://www.korean.go.kr/09_new/dic/rule/rule02_0207.jsp
].each do | url |
	open(url).read.scan(/>([^0-9<>);?]+?)\[(.*?)\]</).each do | match |
		puts match[0, 2].join(' => ')
		m[match[0]] = match[1]
	end
end

File.open(File.dirname(__FILE__) + '/../test/pronunciation.yml', 'w') do | f |
	f.puts "---"
	m.each do | k, v |
		k = k.sub(/.*→/, '').gsub(/-/, '')
		v = v.sub(/.*→/, '').gsub(/[\(:ː\)]/, '').split(%r{[/∼]})
		f.puts "\"#{k}\": [#{v.join(', ')}]"
	end
end

