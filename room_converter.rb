require 'json'

class RoomConverter
    @total_rooms = %{}
    @object_rooms = %{}

    EXIT_TYPES = %w(
        one_exit
        two_perpendicular_exits
        two_opposite_exits
        three_exits
        four_exits
    )

    OBJECT_TYPES = %w(
        obj_lantern
        obj_door
        obj_ears
        obj_bush
        obj_block_spot
        obj_spider
        obj_skeleton
        obj_statue
        obj_giant_worm
        obj_echo
        obj_mouth
        obj_column
        obj_bones
        obj_lava
        obj_eyes
        obj_worm
        obj_wall
    )

    def initialize()
        default_map = {
            "one_exit" => [],
            "two_perpendicular_exits" => [],
            "two_opposite_exits" => [],
            "three_exits" => [],
            "four_exits" => []
        }

        @total_rooms = default_map.dup
        @object_counts = OBJECT_TYPES.to_h { |object_type| [object_type, default_map.dup] }
    end

    def translate_file(filename)
        puts filename
        filename.chop!.chop!.chop!
        exit_type = filename.gsub(/ *\d+$/, '')[3..-2]
        puts exit_type
        @total_rooms[exit_type] << filename if @total_rooms.keys.include? exit_type
        file_data = File.read("./rooms/#{filename}/#{filename}.yy")
        instance_data = file_data.split('"instances":')[1].split('],"visible"').first.gsub(",}", "}").chop!.chop!.chop!.chop!.chop!.chop!.chop!.chop! + ']'
        #puts instance_data
        parsed_data = JSON.parse(instance_data)
        #puts parsed_data
        string = "["
    
        parsed_data.each do |instance_data|
            object_name = instance_data["objectId"]["name"]
            instance_string = "{\"x\": #{instance_data['x'].to_f().round()}, \"y\": #{instance_data['y'].to_f().round()}, \"name\": \"#{object_name}\"},"
            #puts instance_string
            string << instance_string

            # Add object name to counts
            if ((@total_rooms.keys.include? exit_type) && 
                (@object_counts.keys.include? object_name) &&
                (!@object_counts[object_name][exit_type].include? filename))
                @object_counts[object_name][exit_type] << filename
            end
        end
        string.chop! << "]"
        #puts string
        #f = File.open("./datafiles/all_rooms.json", "a");
        #f.write("#{filename}: #{string}")
        #f.close()
        File.write("./datafiles/#{filename}.json", string)
    end

    def count_objects(object_type)
        object_count_total = 0
        total_count_total = 0
        puts object_type 

        EXIT_TYPES.each do |exit_type|
            total_count = @total_rooms[exit_type].length()
            object_count = @object_counts[object_type][exit_type].length()
            object_count_total += object_count
            total_count_total += total_count
            puts @object_counts[object_type][exit_type]
            puts "\t\t #{exit_type} count: #{object_count} / #{total_count} = #{(object_count/total_count)*100} %"
        end

        puts "\t total count: #{object_count_total} / #{total_count_total} = #{(object_count_total/total_count_total)*100} %"
    end
end

filenames = Dir.entries("./rooms")
sub_file_names = nil
converter = RoomConverter.new

filenames.each do |filename|
    next if (filename == '.' or filename == '..')
    sub_file_names = Dir.entries("./rooms/#{filename}")
    sub_file_names.each { |sub_file_name| converter.translate_file(sub_file_name) unless ['.', '..', 'rm_start.yy', 'rm_title.yy', 'rm_finish.yy', 'rm_four_exits_13.yy', 'rm_four_exits_14.yy', 'rm_four_exits_15.yy', 'rm_four_exits_16.yy', 'rm_four_exits_17.yy'].include?(sub_file_name) }
end

RoomConverter::OBJECT_TYPES.each do |object_type| 
    converter.count_objects(object_type)
end

