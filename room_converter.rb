require 'json'

def translate_file(filename)
    puts filename
    filename.chop!.chop!.chop!
    file_data = File.read("./rooms/#{filename}/#{filename}.yy")
    instance_data = file_data.split('"instances":')[1].split('],"visible"').first.gsub(",}", "}").chop!.chop!.chop!.chop!.chop!.chop!.chop!.chop! + ']'
    #puts instance_data
    parsed_data = JSON.parse(instance_data)
    #puts parsed_data
    string = "["
    parsed_data.each do |instance_data|
        instance_string = "{\"x\": #{instance_data['x']}, \"y\": #{instance_data['y']}, \"name\": \"#{instance_data["objectId"]["name"]}\"},"
        #puts instance_string
        string << instance_string
    end
    string.chop! << "]"
    #puts string
    File.write("./datafiles/#{filename}.json", string)
end

filenames = Dir.entries("./rooms")
#puts filenames
sub_file_names = nil
filenames.each do |filename|
    next if (filename == '.' or filename == '..')
    sub_file_names = Dir.entries("./rooms/#{filename}")
    sub_file_names.each { |sub_file_name| translate_file(sub_file_name) unless ['.', '..', 'rm_start.yy', 'rm_title.yy', 'rm_finish.yy', 'rm_four_exits_13.yy', 'rm_four_exits_14.yy', 'rm_four_exits_15.yy', 'rm_four_exits_16.yy', 'rm_four_exits_17.yy'].include?(sub_file_name) }
end

