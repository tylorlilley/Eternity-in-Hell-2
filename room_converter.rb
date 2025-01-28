require 'json'

class RoomConverter
    @total_rooms = %{}
    @object_rooms = %{}
    @complexity_rooms = %{}

    attr_reader :object_rooms, :total_rooms

    EXIT_TYPES = %w(
        no_exits
        three_exits
        four_exits
        one_exit
        two_opposite_exits
        two_perpendicular_exits
    )

    REQUIRED_OBJECT_TYPES = %w(
        obj_wall
        obj_stairs_spot
        obj_chest_spot
        obj_collectable_spot
        obj_exit_spot_up
        obj_exit_spot_down
        obj_exit_spot_left
        obj_exit_spot_right
    )

    THREAT_TYPES = %w(
        obj_lantern
        obj_lava
        obj_bones
        obj_blood
        obj_bush
        obj_column
        obj_mirror
        obj_door
        obj_fountain
        obj_statue
        obj_giant_worm_body
        obj_giant_worm_head
        obj_skeleton_spot
        obj_snake
        obj_mouth
        obj_spider_spot
        obj_bumper
        obj_ears
        obj_eyes
        obj_block_spot
        obj_player_corpse
        obj_gudetama
        obj_inverted_cross
        obj_red_chest
        obj_hall_of_mirrors
        obj_giant_eye
    )

    OBJECT_TYPES = REQUIRED_OBJECT_TYPES + THREAT_TYPES

    def default_mapping()
        {
            "no_exits" => [],
            "one_exit" => [],
            "two_perpendicular_exits" => [],
            "two_opposite_exits" => [],
            "three_exits" => [],
            "four_exits" => []
        }
    end

    def default_count_mapping()
        {
            "no_exits" => 0,
            "one_exit" => 0,
            "two_perpendicular_exits" => 0,
            "two_opposite_exits" => 0,
            "three_exits" => 0,
            "four_exits" => 0
        }
    end

    def exit_probability(exit_type)
        {
            "no_exits" => 1,
            "one_exit" => 6,
            "two_perpendicular_exits" => 8,
            "two_opposite_exits" => 4,
            "three_exits" => 6,
            "four_exits" => 3
        }[exit_type]
    end

    def target_probability(object_type)
        {
            # Tiles
            "obj_lantern" => 0.35,
            "obj_lava" => 0.15,
            "obj_bones" => 0.35,
            "obj_blood" => 0.01,
            "obj_bush" => 0.25,
            "obj_column" => 0.50,
            "obj_mirror" => 0.01,
            "obj_door" => 0.15,
            "obj_fountain" => 0.05,
            "obj_statue" => 0.05,
            # Enemies
            "obj_giant_worm_body" => 0.08,
            "obj_giant_worm_head" => 0.08,
            "obj_skeleton_spot" => 0.15,
            "obj_snake" => 0.08,
            "obj_mouth" => 0.08,
            "obj_spider_spot" => 0.12,
            "obj_bumper" => 0.05,
            "obj_eyes" => 0.01,
            "obj_ears" => 0.05,
            "obj_block_spot" => 0.25,
            "obj_player_corpse" => 0.03,
            "obj_gudetama" => 0.003,
            "obj_inverted_cross" => 0.003,
            "obj_red_chest" => 0.003,
            "obj_hall_of_mirrors" => 0.003,
            "obj_giant_eye" => 0.003,
            # Required Objects
            "obj_wall" => 1.00,
            "obj_stairs_spot" => 1.00,
            "obj_chest_spot" => 1.00,
            "obj_collectable_spot" => 1.00,
            "obj_exit_spot_up" => 1.00,
            "obj_exit_spot_left" => 1.00,
            "obj_exit_spot_right" => 1.00,
            "obj_exit_spot_down" => 1.00,
        }[object_type]
    end

    def target_complexity_probability(difficulty, complexity)
        if (difficulty == 1)
            {
            0 => 0.10,
            1 => 0.20,
            2 => 0.45,
            3 => 0.20,
            4 => 0.05,
            5 => 0.00,
            6 => 0.00,
            }[complexity]
        elsif (difficulty == 2)
            {
            0 => 0.05,
            1 => 0.15,
            2 => 0.40,
            3 => 0.25,
            4 => 0.14,
            5 => 0.01,
            6 => 0.00,
            }[complexity]
        elsif (difficulty == 3)
            {
            0 => 0.05,
            1 => 0.15,
            2 => 0.30,
            3 => 0.25,
            4 => 0.20,
            5 => 0.03,
            6 => 0.02,
            }[complexity]
        end
    end

    def room_threat_level(unflitered_objects)
        room_objects = unflitered_objects.filter { |obj| THREAT_TYPES.include? obj }
        threat_level = 0

        # blood, mirror are no threat

        # Boolean Threat Levels
        threat_level += 1 if room_objects.include? "obj_lantern"
        threat_level += 1.5 if room_objects.include? "obj_bumper"
        threat_level += 4 if room_objects.include? "obj_eyes"
        threat_level += 4 if room_objects.include? "obj_ears"
        threat_level += 4 if room_objects.include? "obj_gudetama"
        threat_level += 5 if room_objects.include? "obj_giant_eye"
        threat_level += 5 if room_objects.include? "obj_inverted_cross"
        threat_level += 5 if room_objects.include? "obj_hall_of_mirrors"
        threat_level += 5 if room_objects.include? "obj_red_chest"

        # Threats Per Instance 
        threat_level += room_objects.count("obj_mouth")
        threat_level += (0.08 * room_objects.count("obj_block_spot")).floor
        threat_level += (0.01 * room_objects.count("obj_lava")).ceil
        threat_level += (room_objects.count("obj_spider_spot") * 1.2).ceil
        threat_level += (room_objects.count("obj_bones") * 0.05).ceil
        threat_level += (room_objects.count("obj_player_corpse") * 0.05).ceil
        threat_level += (room_objects.count("obj_statue") * 0.25).ceil
        threat_level += (room_objects.count("obj_column") * 0.10).ceil
        threat_level += (room_objects.count("obj_fountain") * 0.5).ceil
        threat_level += (room_objects.count("obj_skeleton_spot") * 0.33).ceil
        threat_level += (room_objects.count("obj_snake") * 0.66).ceil
        threat_level += (0.25 * room_objects.count("obj_giant_worm_head") + 0.10 * room_objects.count("obj_giant_worm_body")).ceil

        return threat_level.round()
    end

    def room_complexity(room_name, unflitered_objects)
        complexity_level = 0

        unflitered_objects.uniq.each { |obj| complexity_level += 1 if THREAT_TYPES.include? obj }

        return complexity_level
    end

    def room_difficulty(room_name, room_objects)
        threat_level = room_threat_level(room_objects)

        difficulty = 0
        difficulty = 1 if threat_level >= 1
        difficulty = 2 if threat_level > 2
        difficulty = 3 if threat_level > 4

        return difficulty
        #return room_difficulty_override(room_name) || difficulty
    end

=begin
    def room_difficulty_override(room_name)
        {
            "rm_four_exits_11" => 2,
            "rm_four_exits_12" => 3,
            "rm_four_exits_7" => 2,
            "rm_one_exit_16" => 2,
            "rm_one_exit_17" => 1,
            "rm_one_exit_18" => 2,
            "rm_three_exits_5" => 1,
        }[room_name]
    end
 =end

=begin
    def room_difficulty_old(room_name)
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
=end

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

        @complexity_rooms = {
            1 => {
                0 => default_mapping(),
                1 => default_mapping(),
                2 => default_mapping(),
                3 => default_mapping(),
                4 => default_mapping(),
                5 => default_mapping(),
                6 => default_mapping()
            },
            2 => {
                0 => default_mapping(),
                1 => default_mapping(),
                2 => default_mapping(),
                3 => default_mapping(),
                4 => default_mapping(),
                5 => default_mapping(),
                6 => default_mapping()
            },
            3 => {
                0 => default_mapping(),
                1 => default_mapping(),
                2 => default_mapping(),
                3 => default_mapping(),
                4 => default_mapping(),
                5 => default_mapping(),
                6 => default_mapping()
            },
        }
    end

    def translate_file(file_name)
        room_name = file_name[0..-4]
        file_path = "./rooms/#{room_name}/#{room_name}.yy"
        return unless File.exist?(file_path)

        exit_type = room_name.gsub(/ *\d+$/, '')[3..-2]
        return unless EXIT_TYPES.include? exit_type

        # Read in data from file
        file_data = File.read(file_path)
        instance_data = file_data.split('"instances":')[1].split('],"layers"').first.gsub(",}", "}").chop!.chop!.chop!.chop!.chop!.chop!.chop!.chop! + ']'
        #puts instance_data
        parsed_data = JSON.parse(instance_data)

        # Create array of instance information
        room_objects = []
        string = "["
        parsed_data.each do |instance_data|
            object_name = instance_data["objectId"]["name"]
            instance_string = "{\"x\": #{instance_data['x'].to_f().round()}, \"y\": #{instance_data['y'].to_f().round()}, \"name\": \"#{object_name}\"},"
            string << instance_string

            # Determine object key
            object_key = (OBJECT_TYPES.include?(object_name)) ? object_name : "other"
            if (object_key == "other")
                raise "UNEXPECTED OBJECT #{object_name} FOUND IN #{room_name}"
            end
            room_objects << object_key
        end
        string.chop! << "]"
        threat_level = room_threat_level(room_objects)
        complexity = room_complexity(room_name, room_objects)

        # Validate Room
        # Chest spot not on top of any collectables or exit spots, etc.
        # Doors blank on two opposite sides
        # At least on set of blank space to leave room for doors spawned on exit edges
        raise "ROOM MISSING STAIRS SPOT: #{room_name}" unless room_objects.include? "obj_stairs_spot"
        raise "ROOM MISSING CHEST SPOT: #{room_name}" unless room_objects.include? "obj_chest_spot"
        raise "ROOM COLLECTABLE SPOT COUNT (#{room_objects.count("obj_collectable_spot")}) TOO LOW: #{room_name}" unless room_objects.count("obj_collectable_spot") >= 2
        raise "ROOM UP EXIT SPOT COUNT (#{room_objects.count("obj_exit_spot_up")}) TOO LOW: #{room_name}" unless room_objects.count("obj_exit_spot_up") >= 2
        raise "ROOM RIGHT EXIT SPOT COUNT (#{room_objects.count("obj_exit_spot_right")}) TOO LOW: #{room_name}" unless room_objects.count("obj_exit_spot_right") >= 2
        raise "ROOM DOWN EXIT SPOT COUNT (#{room_objects.count("obj_exit_spot_down")}) TOO LOW: #{room_name}" unless room_objects.count("obj_exit_spot_down") >= 2
        raise "ROOM LEFT EXIT SPOT COUNT (#{room_objects.count("obj_exit_spot_left")}) TOO LOW: #{room_name}" unless room_objects.count("obj_exit_spot_left") >= 2
        raise "ROOM CONTAINS WORM HEAD BUT NOT BODY: #{room_name}" unless room_objects.include?("obj_giant_worm_head") == room_objects.include?("obj_giant_worm_body")
        raise "ROOM THREAT LEVEL (#{threat_level}) TOO HIGH: #{room_name}" unless threat_level <= 10 #6
        raise "ROOM COMPLEXITY LEVEL (#{complexity}) TOO HIGH: #{room_name}" unless complexity <= 6
        
        # Determine difficulty level
        difficulty = room_difficulty(room_name, room_objects)
        room_objects.each do |object_key| 
            # Add object name to counts
            (1..3).each do |possible_difficulty|
                next if possible_difficulty < difficulty

                if (!@total_rooms[possible_difficulty][exit_type].include?(room_name))
                    @total_rooms[possible_difficulty][exit_type] << room_name 
                end

                if (!@object_rooms[possible_difficulty][object_key][exit_type].include?(room_name))
                    @object_rooms[possible_difficulty][object_key][exit_type] << room_name
                end

                if (!@complexity_rooms[possible_difficulty][complexity][exit_type].include?(room_name))
                    @complexity_rooms[possible_difficulty][complexity][exit_type] << room_name 
                end
            end
        end

        puts "#{room_name} - threat: #{room_threat_level(room_objects)}; difficulty - #{difficulty}; complexity - #{complexity}"
        #old_difficulty = room_difficulty_old(room_name)
        #if (difficulty != old_difficulty)
        #    puts "#{room_name} - threat: #{room_threat_level(room_objects)}; difficulty - old #{old_difficulty}; new - #{difficulty}"
        #end

        # Write to room file
        difficulty_string = "difficulty: #{difficulty},\n"
        File.write("./datafiles/#{room_name}.json", difficulty_string)
        File.write("./datafiles/#{room_name}.json", string, mode: "a")
    end

    def pretty_string(number)
        number.to_s.rjust(3)
    end

    def pretty_decimal(number)
        number.round(2).to_s.rjust(3)
    end

    def pretty_percentage(number)
        (number * 100).round(2).to_s.rjust(5)
    end

    def count_objects(object_type, difficulty)
        object_count_total = 0;
        weighted_object_count_total = 0;
        total_count_total = 0;
        weighted_total_count_total = 0;
        
        EXIT_TYPES.each do |exit_type|
            # Generate Data Points
            total_count = @total_rooms[difficulty][exit_type].length()
            object_count = @object_rooms[difficulty][object_type][exit_type].length()
            weighted_object_count = (object_count * exit_probability(exit_type))
            weighted_total_count = (total_count * exit_probability(exit_type))

            # Update Total Tallies
            object_count_total += object_count
            weighted_object_count_total += weighted_object_count
            total_count_total += total_count
            weighted_total_count_total += weighted_total_count

            # Generate Data Points for Exit Type
            percentage_of_total = object_count.to_f / total_count.to_f
            weighted_percentage_of_total = weighted_object_count.to_f / weighted_total_count.to_f

            # Print Output
            puts "\t#{exit_type.ljust(24)} \tcount: #{pretty_string(object_count)} / #{pretty_string(total_count)} = #{pretty_percentage(percentage_of_total)} %; Weighted: #{pretty_percentage(weighted_percentage_of_total)} %"
        end

        # Generate Data Points for Total
        percentage_of_total = object_count_total.to_f / total_count_total.to_f
        weighted_percentage_of_total = weighted_object_count_total.to_f / weighted_total_count_total.to_f         

        puts "\t#{'total'.ljust(24)} \tcount: #{pretty_string(object_count_total)} / #{pretty_string(total_count_total)} = #{pretty_percentage(percentage_of_total)} %; Weighted: #{pretty_percentage(weighted_percentage_of_total)} %"
        puts "\t\t\t\t\t\t\t\t#{' Target Diff:'} #{pretty_percentage(weighted_percentage_of_total - target_probability(object_type))} %"
    end

    def count_complexity(difficulty)
        complexity_rooms_count_total = 0
        weighted_complexity_rooms_count_total = 0
        complexity_value_total = 0
        weighted_complexity_value_total = 0
        complexity_level_rooms_count = {
            0 => 0,
            1 => 0,
            2 => 0,
            3 => 0,
            4 => 0,
            5 => 0,
            6 => 0,
        }
        complexity_level_rooms_count_total = {
            0 => 0,
            1 => 0,
            2 => 0,
            3 => 0,
            4 => 0,
            5 => 0,
            6 => 0,
        };
        weighted_complexity_level_rooms_count_total = {
            0 => 0,
            1 => 0,
            2 => 0,
            3 => 0,
            4 => 0,
            5 => 0,
            6 => 0,
        };

        EXIT_TYPES.each do |exit_type|
            exit_type_complexity_rooms_count_total = 0
            weighted_exit_type_complexity_rooms_count_total = 0
            exit_type_complexity_value_total = 0
            weighted_exit_type_complexity_value_total = 0
   
            (0..6).each do |complexity|
                # Generate Data Points
                exit_type_rooms_count_total = @complexity_rooms[difficulty][complexity][exit_type].length()
                weighted_exit_type_rooms_count_total = (exit_type_rooms_count_total * exit_probability(exit_type))
                complexity_level_rooms_count[complexity] += exit_type_rooms_count_total

                # Update Total Tallies
                exit_type_complexity_rooms_count_total += exit_type_rooms_count_total
                weighted_exit_type_complexity_rooms_count_total += weighted_exit_type_rooms_count_total
                exit_type_complexity_value_total += exit_type_rooms_count_total * complexity
                weighted_exit_type_complexity_value_total += weighted_exit_type_rooms_count_total * complexity
                complexity_level_rooms_count_total[complexity] += exit_type_rooms_count_total
                weighted_complexity_level_rooms_count_total[complexity] += weighted_exit_type_rooms_count_total
            end

            # Generate Data Points for Total
            complexity_rooms_count_total += exit_type_complexity_rooms_count_total
            weighted_complexity_rooms_count_total += weighted_exit_type_complexity_rooms_count_total
            complexity_value_total += exit_type_complexity_value_total
            weighted_complexity_value_total += weighted_exit_type_complexity_value_total
            exit_type_average_complexity = exit_type_complexity_value_total.to_f / exit_type_complexity_rooms_count_total.to_f
            exit_type_weighted_average_complexity = exit_type_complexity_value_total.to_f / weighted_exit_type_complexity_rooms_count_total.to_f

            # Print Output
            puts "\t\t#{exit_type.ljust(24)} \tcount: #{pretty_string(exit_type_complexity_rooms_count_total)}; Avg Complexity: #{pretty_decimal(exit_type_average_complexity)}; Weighted Avg Complexity: #{pretty_decimal(exit_type_weighted_average_complexity)}"
        end

        # Generate Data Points for Total
        average_complexity = complexity_value_total.to_f / complexity_rooms_count_total.to_f
        weighted_average_complexity = weighted_complexity_value_total.to_f / weighted_complexity_rooms_count_total.to_f 

        # Print Output
        puts "\t\t#{'total'.ljust(24)} \tcount: #{pretty_string(complexity_rooms_count_total)}; Avg Complexity: #{pretty_decimal(average_complexity)}; Weighted Avg Complexity: #{pretty_decimal(weighted_average_complexity)}"
        puts "\n\t\t=== By Complexity ==="
        (0..6).each do |complexity|
            percentage_of_total = complexity_level_rooms_count[complexity].to_f / complexity_rooms_count_total.to_f
            weighted_percentage_of_total = weighted_complexity_level_rooms_count_total[complexity].to_f / weighted_complexity_rooms_count_total.to_f
            puts "\t\t#{complexity.to_s.ljust(24)} \tcount: #{pretty_string(complexity_level_rooms_count[complexity])} = #{pretty_percentage(percentage_of_total)} %; Weighted: #{pretty_percentage(weighted_percentage_of_total)} %"
            puts "\t\t\t\t\t\t\t\t#{'   Target Diff:'} #{pretty_percentage((weighted_percentage_of_total - target_complexity_probability(difficulty, complexity)))} %"
        end
    end

    def count_all_object_types
        OBJECT_TYPES.each do |object_type|
            puts "\n\n\n=== #{object_type} ==="
            (1..3).each do |difficulty|
                puts "\n\tDifficulty: #{difficulty}"
                count_objects(object_type, difficulty)
            end
        end
    end

    def count_all_complexity_rooms
        puts "\n\n\n=== Count Complexity ==="
        (1..3).each do |difficulty|
            puts "\n\tDifficulty: #{difficulty}"
            count_complexity(difficulty)
        end
    end
end

filenames = Dir.entries("./rooms")
sub_file_names = nil
converter = RoomConverter.new

filenames.each do |filename|
    next if (filename == '.' or filename == '..')
    sub_file_names = Dir.entries("./rooms/#{filename}")
    sub_file_names.each { |sub_file_name| converter.translate_file(sub_file_name) } #unless ['.', '..', 'rm_start.yy', 'rm_title.yy', 'rm_finish.yy', 'rm_four_exits_13.yy', 'rm_four_exits_14.yy', 'rm_four_exits_15.yy', 'rm_four_exits_16.yy', 'rm_four_exits_17.yy'].include?(sub_file_name) }
end

converter.count_all_complexity_rooms()
converter.count_all_object_types()
