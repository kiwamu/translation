#! /usr/bin/ruby

require 'net/https'
require 'fileutils'

LINE_SPACE = 2
DICT_FILE_JP = "ibm_j.txt"
DICT_FILE_EN = "ibm_e.txt"

$dict_map = { }

def https
  https = Net::HTTP.new('www-06.ibm.com', 443)
  https.use_ssl = true
  https.ca_file = './base64.cer'
  https.verify_mode = OpenSSL::SSL::VERIFY_PEER
  https.verify_depth = 5
  https
end

def search(word)
  https.start do |w|
#  response = w.post("/jp/manuals/nlsdic/nlsdic.jsp","Eng=hoge&Jpn=&Cmt=&Cat=ALL&ibm-search=%E6%A4%9C%E7%B4%A2%E3%81%99%E3%82%8B&DBDATE=2008%E5%B9%B49%E6%9C%88%E7%89%88&LASTMOD=Tuesday%2C13-May-2008")
    response = w.post("/jp/manuals/nlsdic/nlsdic.jsp","Eng=#{word}")
    response.body
  end
end

def do_search(word)
  puts word
  page = search(word)
  page.each_line do |line|
    if line =~ /\s*<b>検索件数: ([0-9]*) 件<\/b><br \/><br \/>/
      if $1.to_i > 200
        new_word = extend_search_word(word)
        do_search(new_word)
      else
        extract_data(page) unless $1.to_i == 0
        return nil if word.split(//)[0] == "z"
        new_word = next_search_word(word)
        do_search(new_word)
      end
    end
  end
end

def extend_search_word(word)
  word + "a"
end

def next_search_word(word)
  last = word.split(//)[-1]
  if last == "z"
    word[-2] = word[-2].next
    word[-1] = ""
  else
    word[-1] = word[-1].next
  end
  word
end

def extract_data(page)

  eng = ""
  hit_eng = false
  step_from_hit = 0

  page.each_line do |line|
    if line =~ /<th class="ibm-table-row" scope="row">(.*)<\/th>/
      eng = $1
      hit_eng = true
      step_from_hit = 0
    else
      step_from_hit += 1 if hit_eng
    end
    if hit_eng && step_from_hit == 2
      if line =~ /<td>(.*)<\/td>/
        jpn = $1
      end
      hit_eng = false
      step_from_hit = 0
      $dict_map[eng] = jpn
    end
  end
end

def write(dict)
  dict.each do |en, jp|
    File.open(DICT_FILE_EN, "a") do |f|
      f.puts "#{en}"
      LINE_SPACE.times{ f.puts }
    end

    File.open(DICT_FILE_JP, "a") do |f|
      f.puts "#{jp}"
      LINE_SPACE.times{ f.puts }
    end
  end
end

FileUtils.rm_f(DICT_FILE_JP)
FileUtils.rm_f(DICT_FILE_EN)

do_search("a")
write($dict_map)
