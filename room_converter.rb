require 'json'

class RoomConverter
    @total_rooms = %{}
    @object_rooms = %{}

    attr_reader :object_rooms, :total_rooms

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
        obj_spider
        obj_skeleton
        obj_statue
        obj_giant_worm_body
        obj_giant_worm_head
        obj_mouth
        obj_blood
        obj_column
        obj_bones
        obj_lava
        obj_eyes
        obj_snake
        obj_wall
        obj_bumper
        obj_block_spot
        obj_stairs_spot
        obj_collectable_spot
        obj_echo_spot
        obj_player_corpse
        other
    )

    def default_mapping()
        {
            "one_exit" => [],
            "two_perpendicular_exits" => [],
            "two_opposite_exits" => [],
            "three_exits" => [],
            "four_exits" => []
        }
    end

    def default_count_mapping()
        {
            "one_exit" => 0,
            "two_perpendicular_exits" => 0,
            "two_opposite_exits" => 0,
            "three_exits" => 0,
            "four_exits" => 0
        }
    end

    def exit_probability(exit_type)
        {
            "one_exit" => 2.00/9.00,
            "two_perpendicular_exits" => 2.66/9.00,
            "two_opposite_exits" => 1.33/9.00,
            "three_exits" => 2.00/9.00,
            "four_exits" => 1.00/9.00
        }[exit_type]
    end

    def target_probability(object_type)
        {
            "obj_lantern" => 40.00,
            "obj_door" => 10.00,
            "obj_ears" => 5.00,
            "obj_bush" => 25.00,
            "obj_spider" => 12.00,
            "obj_skeleton" => 15.00,
            "obj_statue" => 5.00,
            "obj_giant_worm_body" => 5.00,
            "obj_mouth" => 8.00,
            "obj_column" => 45.00,
            "obj_bones" => 45.00,
            "obj_lava" => 15.00,
            "obj_eyes" => 1.00,
            "obj_snake" => 5.00,
            "obj_wall" => 100.00,
            "obj_stairs_spot" => 100.00,
            "obj_collectable_spot" => 100.00,
            "obj_block_spot" => 30.00,
            "obj_echo_spot" => 1.00,
            "obj_bumper" => 5.00,
            "obj_blood" => 1.00,
            "obj_giant_worm_head" => 5.00,
            "obj_player_corpse" => 1.00,
            "other" => 0.00
        }[object_type]
    end

    def room_difficulty(room_name)
        return 1 if %w(
            rm_no_exits_1
            rm_one_exit_2
            rm_one_exit_3
            rm_one_exit_6
            rm_one_exit_7
            rm_one_exit_9
            rm_one_exit_11
            rm_one_exit_14
            rm_one_exit_17
            rm_two_opposite_exits_1
            rm_two_opposite_exits_2
            rm_two_opposite_exits_3
            rm_two_opposite_exits_5
            rm_two_opposite_exits_7
            rm_two_opposite_exits_8
            rm_two_opposite_exits_10
            rm_two_opposite_exits_11
            rm_two_opposite_exits_13
            rm_two_opposite_exits_15
            rm_two_perpendicular_exits_1
            rm_two_perpendicular_exits_2
            rm_two_perpendicular_exits_3
            rm_two_perpendicular_exits_4
            rm_two_perpendicular_exits_5
            rm_two_perpendicular_exits_6
            rm_two_perpendicular_exits_8		
            rm_two_perpendicular_exits_12
            rm_two_perpendicular_exits_14
            rm_two_perpendicular_exits_17
            rm_two_perpendicular_exits_21
            rm_two_perpendicular_exits_23
            rm_two_perpendicular_exits_24
            rm_two_perpendicular_exits_25
            rm_two_perpendicular_exits_31
            rm_three_exits_1
            rm_three_exits_2	
            rm_three_exits_3
            rm_three_exits_4
            rm_three_exits_5
            rm_three_exits_7
            rm_three_exits_8
            rm_three_exits_9
            rm_three_exits_10
            rm_three_exits_11			
            rm_three_exits_12
            rm_four_exits_1
            rm_four_exits_3
            rm_four_exits_5
            rm_four_exits_7
            rm_four_exits_9
        ).include? room_name

        return 3 if %w(
            rm_one_exit_19
            rm_one_exit_20	
            rm_one_exit_21
            rm_one_exit_22
            rm_two_opposite_exits_6
            rm_two_opposite_exits_9
            rm_two_perpendicular_exits_7
            rm_two_opposite_exits_18
            rm_two_perpendicular_exits_15
            rm_two_perpendicular_exits_18			
            rm_two_perpendicular_exits_19
            rm_two_perpendicular_exits_20
            rm_two_perpendicular_exits_27
            rm_two_perpendicular_exits_28
            rm_two_perpendicular_exits_30
            rm_three_exits_15
            rm_three_exits_18
            rm_four_exits_12
        ).include? room_name

        return 2
    end

    def initialize()
        @total_rooms = {
            1 => default_mapping(),
            2 => default_mapping(),
            3 => default_mapping()
        }

        @object_rooms = {}
        (1..3).each do |difficulty|
            @object_rooms[difficulty] = OBJECT_TYPES.to_h { |object_type| [object_type, default_mapping] }
        end
    end

    def translate_file(filename)
        puts filename

        filename.chop!.chop!.chop!
        exit_type = filename.gsub(/ *\d+$/, '')[3..-2]
        return unless EXIT_TYPES.include? exit_type

        difficulty = room_difficulty(filename)

        (1..3).each do |possible_difficulty|
            next if possible_difficulty < difficulty

            if (!@total_rooms[possible_difficulty][exit_type].include?(filename))
                @total_rooms[possible_difficulty][exit_type] << filename 
            end
        end

        # Write room difficulty to file
        difficulty_string = "difficulty: #{difficulty},\n"
        File.write("./datafiles/#{filename}.json", difficulty_string)

        # Read in data from file
        file_data = File.read("./rooms/#{filename}/#{filename}.yy")
        instance_data = file_data.split('"instances":')[1].split('],"visible"').first.gsub(",}", "}").chop!.chop!.chop!.chop!.chop!.chop!.chop!.chop! + ']'
        parsed_data = JSON.parse(instance_data)

        # Create array of instance information
        stairs_spot = false;
        collectable_spot_count = 0;

        string = "["
        parsed_data.each do |instance_data|
            object_name = instance_data["objectId"]["name"]
            instance_string = "{\"x\": #{instance_data['x'].to_f().round()}, \"y\": #{instance_data['y'].to_f().round()}, \"name\": \"#{object_name}\"},"
            string << instance_string

            # Validate Objects
            puts object_name
            stairs_spot = true if (object_name == "obj_stairs_spot") 
            collectable_spot_count += 1 if (object_name == "obj_collectable_spot") 

            # Add object name to counts
            (1..3).each do |possible_difficulty|
                next if possible_difficulty < difficulty

                object_key = (OBJECT_TYPES.include?(object_name)) ? object_name : "other"
                if (object_key == "other")
                    raise "UNEXPECTED OBJECT #{object_name} FOUND IN #{filename}"
                end

                if (!@object_rooms[possible_difficulty][object_key][exit_type].include?(filename))
                    @object_rooms[possible_difficulty][object_key][exit_type] << filename
                end
            end
        end
        string.chop! << "]"

        # Validate Room
        raise "ROOM MISSING STAIRS SPOT: #{filename}" unless stairs_spot
        raise "ROOM COLLECTABLE SPOT COUNT (#{collectable_spot_count}) TOO LOW: #{filename}" unless collectable_spot_count >= 2

        # Write instance information to json data file
        File.write("./datafiles/#{filename}.json", string, mode: "a")
    end

    def count_objects(object_type, difficulty)
        object_count_total = 0;
        weighted_object_count_total = 0;
        total_count_total = 0;
        
        EXIT_TYPES.each do |exit_type|
            # Generate Data Points
            total_count = @total_rooms[difficulty][exit_type].length()
            object_count = @object_rooms[difficulty][object_type][exit_type].length()
            percentage_of_total = (object_count.to_f/total_count.to_f)
            weighted_percentage_of_total = percentage_of_total * exit_probability(exit_type)

            # Update Total Tallies
            object_count_total += object_count
            weighted_object_count_total += weighted_percentage_of_total
            total_count_total += total_count

            # Generate Pretty Strings
            count_string = object_count.to_s.rjust(3)
            total_count_string = total_count.to_s.rjust(3)
            percentage_of_total_string = (percentage_of_total * 100.00).round(2).to_s.rjust(5)
            weighted_percentage_of_total_string = (weighted_percentage_of_total * 100.00).round(2).to_s.rjust(5)

            # Print Output
            puts "\t#{exit_type.ljust(24)} \tcount: #{count_string} / #{total_count_string} = #{percentage_of_total_string} %; Weighted: #{weighted_percentage_of_total_string} %"
        end

        # Generate Data Points
        percentage_of_total = (object_count_total.to_f/total_count_total.to_f)

        # Generate Pretty Strings for Total Tallies
        count_string = object_count_total.to_s.rjust(3)
        total_count_string = total_count_total.to_s.rjust(3)
        percentage_of_total_string = (percentage_of_total * 100.00).round(2).to_s.rjust(5)
        weighted_percentage_of_total_string = (weighted_object_count_total * 100.00).round(2).to_s.rjust(5)
        target_difference_string = (weighted_object_count_total * 100.00 - target_probability(object_type)).round(2).to_s.rjust(5)

        puts "\t#{'total'.ljust(24)} \tcount: #{count_string} / #{total_count_string} = #{percentage_of_total_string} %; Weighted: #{weighted_percentage_of_total_string} %; Target Diff: #{target_difference_string} %"
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


#object_type = "obj_lantern"
RoomConverter::OBJECT_TYPES.each do |object_type|
    puts "\n\n\n=== #{object_type} ==="
    (1..3).each do |difficulty|
        puts "\n\tDifficulty: #{difficulty}"
        converter.count_objects(object_type, difficulty)
    end
end

