require 'fileutils'
require 'rubygems'
require 'Bluecloth'

# For each file in the given directory, create a markdown image of the file in <dir>/temp
# Consider adding an index page in future.
#
# Usage - ruby convert.rb <path to directory to convert>
source_dir = '.'# ARGV[0]
target_dir = File.join(source_dir, "build")

raise "Directory does not exist [#{source_dir}]" unless Dir.exist?(source_dir)

FileUtils.mkdir_p target_dir
FileUtils.cp_r File.join(source_dir, "stylesheets"), target_dir

source_files = Dir.entries(source_dir).grep(/.+\.(html)$/)

header = IO.read(File.join(source_dir, 'header.tmpl'))
footer = IO.read(File.join(source_dir, 'footer.tmpl'))

source_files.each do |f|
  puts "building  #{File.join(source_dir, f)}"
  f =~ /(.+)\.html$/
  filename = $1
  header_source = header.dup
  header_source.gsub!(/_-_selected_#{filename}/, 'style="background-color:#FF9933;"')
  header_source.gsub!(/_-_selected_[^>]+>/, '>')
  source = IO.read(File.join(source_dir, f))

  # if there is a file called 'filename.md' in ../doc, get it,
  # markdown it and add it into the output
  File.open(File.join(target_dir, f), 'w') do |f|
    f.write header_source
    f.write source
    if File.exists? "../doc/#{filename}.md"
      puts "    including document file"
      doc = IO.read(File.join(source_dir, '..', 'doc', "#{filename}.md"))
      f.write BlueCloth.new(doc).to_html
    end
    f.write footer
  end
end

exit(0);
