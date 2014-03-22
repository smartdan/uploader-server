#!/usr/bin/env ruby

# A Ruby script to delete files older than X days in a given directory. Pretty simple.
# Like this: file_control.rb /User/pelgrim/Documents '*.pdf' 7
# The command above you remove ALL your pdfs inside Documents older than SEVEN DAYS.
# Quickly written by pelgrim < guskald at gmail dot com >

unless ARGV.size == 3
  puts "Usage: file_control <directory> <filename pattern> <max age>"
  exit 1
end

directory, file_pattern, max_age = ARGV[0], ARGV[1], ARGV[2].to_i

unless File.exists?(directory)
  puts "Bad directory #{directory}!"
  exit 2
end

unless max_age > 0
  puts "Max age must be greater than zero! I don't want to remove ALL your files!"
  exit 3
end

def file_age(name)
  (Time.now - File.ctime(name))/(24*3600)
end

Dir.chdir(directory)
Dir.glob(file_pattern).each { |filename| File.delete(filename) if file_age(filename) > max_age }
