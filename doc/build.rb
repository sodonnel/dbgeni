require 'rubygems'
require 'Bluecloth'

# For each file in the given directory, create a markdown image of the file in <dir>/temp
# Consider adding an index page in future.
#
# Usage - ruby convert.rb <path to directory to convert>
source_dir = ARGV[0]

raise "Directory does not exist [#{source_dir}]" unless Dir.exist?(source_dir)

unless Dir.exist?(File.join(source_dir, 'temp'))
  Dir.mkdir(File.join(source_dir, 'temp'))
end

source_files = Dir.entries(source_dir).grep(/.+\.(txt|md)$/)

source_files.each do |f|
  puts "converting  #{File.join(source_dir, f)}"
  source = IO.read(File.join(source_dir, f))
  markdown = BlueCloth.new(source).to_html
  # replace any reference to /images with ../images
  markdown.gsub!(/\/images/, '../images')
  File.open(File.join(source_dir, 'temp', "#{f}.html"), 'w') do |f|
    f.write markdown
  end
end

exit(0);
