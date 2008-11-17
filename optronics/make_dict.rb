require 'net/http'
require 'fileutils'
require 'kconv'

LINE_SPACE = 2
DICT_FILE_JP = "optronics_j.txt"
DICT_FILE_EN = "optronics_e.txt"

FileUtils.rm_f(DICT_FILE_JP)
FileUtils.rm_f(DICT_FILE_EN)

(1..9611).each do |i|
  Net::HTTP.start('www.optronics.co.jp', 80) do |http|
    response = http.get("/lex/detail.php?id=#{i}")

    en = ""
    jp = ""
    desc = ""

    response.body.each_line do |line|
      if line =~ /^\s*<span style="font-weight: bold;">(.*)<\/span><br \/>/
        item = $1.strip
        if item =~ /^(.*) \([^:]* : (.*)\)/
          jp = $1.strip
          en = $2.strip
        end
      elsif line =~ /^\s*<div style="margin-left: 1em;">(.*)<br \/><\/div>/
        desc = $1.strip.sub("　".toeuc, "")
      end
    end

    File.open(DICT_FILE_JP, "a") do |f|
      f.puts "#{jp} : #{desc}"
      LINE_SPACE.times{ f.puts }
    end

    File.open(DICT_FILE_EN, "a") do |f|
      f.puts "#{en}"
      LINE_SPACE.times{ f.puts }
    end
  end
end
