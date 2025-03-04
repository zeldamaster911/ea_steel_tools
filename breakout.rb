# This is the tool that takes a steel part and breaks it out

#Bolts Layer needs to be turned off

module EA_Extensions623
  module EASteelTools
    require 'sketchup.rb'
    require 'benchmark'

    class Breakout
      include BreakoutSetup
      include Control

      def activate

        Sketchup.active_model.start_operation("set environment and run checks", true, true)
        @model = Sketchup.active_model
        unless qualify_model(@model)
          result = UI.messagebox("You are trying to breakout a part with an unconventional name: #{@model.title}, do you wish to continue? If you do continue you risk the tool not behaving properly", MB_YESNO)
          if result == 7
            reset
            return
          end
        end
        @@environment_set = false if not defined? @@environment_set
        @pages = @model.pages
        # @users_template = Sketchup.template
        # Sketchup.template= Sketchup.find_support_file('Breakout.skp', "Plugins/#{FNAME}/Models/")
        @entities = @model.entities
        @materials = @model.materials
        @selection = @model.selection
        @d_list = @model.definitions
        @styles = @model.styles
        @plates = []
        @steel_member = @selection.first
        @letters = [*"A".."Z"]
        @unique_plates = []
        @labels = []
        @status_text = "Please Verify that all the plates are accounted for: RIGHT ARROW = 'Proceed' LEFT ARROW = 'Go Back'"
        @state = 0
        components = scrape(@steel_member)
        # p 'evaluating for empty plates'
        if @plates.empty?
          result = UI.messagebox("Did not detect any plates, do you wish to continue?", MB_YESNO)
          if result == 6
            @state = 1
            position_member(@steel_member)
            set_envoronment if @@environment_set == false
            color_steel_member(@steel_member)
            set_layer(@steel_member, BREAKOUT_LAYERS[0])
            # hide_parts(@steel_member, @pages[1], 16)
            @pages[1].set_visibility(@steel_member.layer, false)
            reset
          else
            @plates = []
            reset
          end
        else
          # p 'coloring'
          temp_color(@plates)
          temp_label(@plates, @model.active_view)
        end
        #last method This resets the users template to what they had in the beginning
      end

      def qualify_model(model)
        ents = model.entities
        if model.title.match GROUP_REGEX
        # if model.entities.count == 1
          if ents[0].class == Sketchup::Group && ents[0].name.match(GROUP_REGEX)
            # p 'passed as a group'
            return true
          elsif ents[0].class == Sketchup::ComponentInstance #&& ents[0].definition.name.match(GROUP_REGEX)
            # p 'passed as a Component'
            return true
          else
            # p 'not validated'
            return false
          end
        else
          return false
        end
      end

      def reset
        Sketchup.send_action "selectSelectionTool:"
        @plates = [] if @state == 2
        @model.commit_operation
      end

      def set_envoronment
        BreakoutSetup.set_styles(@model)
        BreakoutSetup.set_scenes(@model)
        BreakoutSetup.set_materials(@model)
        BreakoutSetup.set_layers(@model)
        @@environment_set = true
      end

      def color_steel_member(member)
        if @materials[DONE_COLOR]
          member.material = @materials[DONE_COLOR]
        elsif @materials.add STEEL_COLORS[:grey][:name]
          part_color = @materials[DONE_COLOR].color = STEEL_COLORS[:grey][:rgba]
          member.material = @materials[DONE_COLOR]
        else
          UI.messagebox("Paint the steel part the done color")
          # message = UI::Notification.new(STEEL_EXTENSION, "Paint the steel part the done color")
          # message.show
        end
      end

      def scrape(part) #part is the assumed steel part (beam or column with all respective sub components)
        # p 'scraping'
        begin
          part.definition.entities.each do |e|
            if defined? e.definition
              if not e.definition.attribute_dictionaries == nil
                if not e.definition.attribute_dictionaries[PLATE_DICTIONARY] == nil
                  if e.definition.attribute_dictionaries[PLATE_DICTIONARY].values.include?(SCHEMA_VALUE)
                    # p 'deep inside scraping'
                    a = {object: e, orig_color: e.material, vol: e.volume, xscale: e.definition.local_transformation.xscale, yscale: e.definition.local_transformation.yscale, zscale: e.definition.local_transformation.zscale}
                    @plates.push a
                  end
                end
              end
            end
          end
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          UI.messagebox("There was a problem scraqping the plates")
        end
      end

      def temp_color(plates)
        if plates.nil?
          return
        else
          # p 'inside temp color'
          plates.each do |plate|
            plate[:object].material = PLATE_COLOR
            # p 'gathering plates temp colors'
            # plates[plate].material = PLATE_COLOR
          end
        end
      end

      def temp_label(plates, view)
        # p 'inside labeling'
        @t_labels = []
        v = Geom::Vector3d.new [0,0,1]
        v.length = 20
        plates.each do |pl|
          # p 'labeling each plate'
          t = 'PLATE'
          pt = pl[:object].bounds.center
          txt = @steel_member.definition.entities.add_text t, pt, v
          @t_labels.push txt
        end
        view.refresh
      end

      def restore_material(plates)
        @t_labels.each {|l| l.erase!} if !@t_labels.empty? #Erase all the temp labels
        @t_labels.clear
        @individual_plates = []
        plates.each do |plate|
          plate[:object].material = plate[:orig_color]
          @individual_plates.push plate[:object]
        end
        @state = 1 if @state == 0
      end

      def position_member(member)
        tr = Geom::Transformation.axes ORIGIN, X_AXIS, Y_AXIS, Z_AXIS
        member.move! tr
        d = member.bounds.depth
        h = member.bounds.height
        w = member.bounds.width

        c = member.bounds.center

        tr2 = Geom::Transformation.axes c, X_AXIS, Y_AXIS, Z_AXIS
        member.move! tr2.inverse
      end

      def move_stuff
        Sketchup.status_text = "Breaking out the paltes"
        position_member(@steel_member)
        sort_plates(split_plates)
        @named_plate_definitions = name_plates()
        flat_plates = spread_plates
        set_envoronment if @@environment_set == false
        color_steel_member(@steel_member)
        set_layer(@plate_group, BREAKOUT_LAYERS[1])
        set_layer(@steel_member, BREAKOUT_LAYERS[0])
        @pages[0].set_visibility(@plate_group.layer, false)
        @pages[1].set_visibility(@steel_member.layer, false)
        @pages[2].set_visibility(@steel_member.layer, false)
        @pages[1].update
        Sketchup.active_model.active_view.zoom_extents
        @pages[1].update
      end

      def onKeyDown(key, repeat, flags, view)
        if @state == 0 && key == VK_RIGHT
          restore_material(@plates)
          @model.start_operation("Breakout", true)
          @state = 1
          move_stuff
          Sketchup.send_action "selectSelectionTool:"
        elsif @state == 0 && key == VK_LEFT
          restore_material(@plates)
          Sketchup.status_text = "Classify Plates Then Start Again"
          @plates = []
          @state = 2
          reset
        end
      end

      def show_parts(part, page, code)
        pg = @pages.selected_page
        @pages.selected_page = page
        part.visible = true
        page.update(code)
        @pages.selected_page = pg
      end

      def split_plates()
        @individual_plates.each do |plate|
          @unique_plates.push plate.definition.instances
        end
        @unique_plates.uniq! if @individual_plates.count > 0
        @unique_plates.compact! if @unique_plates.compact != nil

        return @unique_plates
      end

      # def check_for_locked_groups(group)
      #   group.each do |plate|
      #     gents = plate.definition.entities
      #     if gents.count < 4
      #       gents.each do |e|
      #         if e.class == Sketchup::Group || e.class == Sketchup::ComponentInstance
      #           if e.locked?
      #             e.explode
      #             return
      #           end
      #         end
      #       end
      #     end
      #   end
      # end

      def sort_plates(plates)
        plates_hash = {}
        plates.each do |pl|
          if pl.class == Array && pl.count > 1
            pl.each do |part|
              bnds = part.bounds.diagonal.to_f.round(4)
              cl = part.material.name

              plates_hash[part] = bnds
            end

            # if there are multiple instances of the plate and none of the other diagonal bounds match then make unique and reset the scale definition.
            counter = 1
            uniqueholder = []
            plates_hash.each do |k,v|
              phc = plates_hash.clone.each do |k1, v1|
                if k != k1
                  if (k.equals?(k1)) && (v != v1)
                    uniqueholder.push k
                    plates_hash.delete(k)
                  end
                end
              end
              counter += 1
            end

            instance_materials = []
            test_bucket = []
            pl.each_with_index do |plate, i|
              instance_materials.push plate.material
              test_bucket.push item = {color: plate.material.name, object: plate, index: i}
            end
            if instance_materials.uniq.count == 2
              instance_materials.uniq!

              a = []
              b = []
              test_bucket.each do |obj|
                if obj[:color] == instance_materials[0].name
                  a.push obj[:object]
                elsif obj[:color] == instance_materials[1].name
                  b.push obj[:object]
                end
              end

              # a.count > b.count ? found = b[0].make_unique : found = a[0].make_unique
              a.count > b.count ? b  : b = a
              # @individual_plates.push found

              if b.count > 1
                c = b[-1].make_unique
                b.each_with_index do |dfn, i|
                  return if i == b[-1]
                  dfn.definition = c.definition
                end
              else
                c = b[0].make_unique
              end

              @unique_plates.push c #This is a made unique plate

            elsif instance_materials.uniq.count > 2
              UI.messagebox("You have multiple components with the same definition but different thickness material. please check your plates to make different thickness plates are unique")
            else
              next
            end
          end
        end
      end

      def name_plates()
        #Assign each unique component a letter A-Z in it's definition
        plates2 = @unique_plates.flatten!
        plates2.uniq!

        plates = sort_plates_for_naming(plates2.uniq)

        # This code finds the direction labels in the component definition list and renames them so the letters of the alphabet are available for plates
        poss_labs = ["N", "S", "E", "W", "X"]
        poss_labs.each do |lab|
          if @d_list[lab]
            # p "Found a direction in the list"
            @d_list[lab].name = "Direction Label"
          else
            # p "not FOUND"
          end
        end

        test_b = []
        plates.each do |plt|
          add_plate_attributes(plt)
          test_b.push plt.definition
        end
        test_b.uniq!
        test_b.each_with_index do |plt, i|
          if plt.group?
            plt.instances.each {|inst| inst.to_component}
          end
          if @d_list[@letters[i]]
            @d_list[@letters[i]].name = "Temp"
          end
          plt.name = @letters[i]
        end
        return test_b
      end

      def add_plate_attributes(classified_plate)
        if classified_plate.definition.attribute_dictionary(PLATE_DICTIONARY).values.include? SCHEMA_VALUE
          PLATE_DICTIONARIES.each_with_index do |d, i|
            classified_plate.definition.set_attribute(PLATE_DICTIONARY, d, 0)
            # classified_plate.attribute_dictionary(PLATE_DICTIONARY)[d] = i
          end
        else
          UI.messagebox("The item you are attempting this on is not a classified plate.")
          return nil
        end
      end

      def label_plate(plate, group)
        labels = []
        mod_title = @model.title
        plate_dict = plate.definition.attribute_dictionary(PLATE_DICTIONARY)
        container = group.entities.add_group
        container.name = plate.definition.name

        plname = plate.definition.name
        var = "#{mod_title}-#{to_eighths(plate_dict[TH_LABEL])}:#{plate_dict[Q_LABEL]}#{plate.definition.name}"
        plate.definition.attribute_dictionary(PLATE_DICTIONARY)[PN_LABEL] = var
        text = container.entities.add_3d_text(var, TextAlignLeft, STEEL_FONT, false, false, 0.675, 0.0, -0.00, false, 0.0)

        align = Geom::Transformation.axes([plate.bounds.center[0], plate.bounds.center[1], 0], X_AXIS, Y_AXIS, Z_AXIS )
        vr = X_AXIS.reverse
        vr.length = (container.bounds.width/3)
        shift = Geom::Transformation.translation(vr)
        rot = Geom::Transformation.rotation(plate.bounds.center, Z_AXIS, 270.degrees)
        # container.move! align
        @entities.transform_entities align, container
        @entities.transform_entities shift, container
        @entities.transform_entities rot, container
        return container
      end


      def sort_plates_for_naming(plates_array)
        begin
          thck1 = [] #H 1/4" Thickness
          thck2 = [] #G 5/16" Thickness
          thck3 = [] #F 3/8" Thickness
          thck4 = [] #E 1/2" Thickness
          thck5 = [] #D 5/8" Thickness
          thck6 = [] #C 3/4" Thickness
          thck7 = [] #special Thickness
          thck8 = [] #special Thickness

        plates_array.each_with_index do |plate|
          case plate.material.name
          when /¼"/
            # p plate.material.name
            thck1.push plate
          when /5_16"/
            # p plate.material.name
            thck2.push plate
          when /⅜"/
            # p plate.material.name
            thck3.push plate
          when /½"/
            # p plate.material.name
            thck4.push plate
          when /⅝"/
            # p plate.material.name
            thck5.push plate
          when /¾"/
            # p plate.material.name
            thck6.push plate
          when /Special Thick/
            # p plate.material.name
            thck7.push plate
          when /⅞"/
            thck7.push plate
          else
            # p plate.material.name
            thck8.push plate
          end
          # p thickness
          # p plate.attribute_dictionary[PLATE_DICTIONARY]["thick"] = thickness
        end

        if thck8.any?
          UI.messagebox("Found #{thck8.count} plate(s) in this part with the unconventional material name: '#{thck8.first.material.name}' ")
        end

        sorted = [thck1, thck2, thck3, thck4, thck5, thck6, thck7, thck8].flatten
        return sorted
        rescue
          UI.messagebox('There was a problem sorting the plates by thickness, possibly a name change for the color thicknesses. this code uses the letters A(Charcoal) B(special thickness) C(3/4") ect')
        end
        # Sorth the paltes by thickness first (thinnest to thickest) then do a sub sort of the quantity (highest to lowest) then put volume (biggest to smallest)
      end


      def get_largest_face(entity)
        plate_entities = entity.definition.entities


        faces = plate_entities.select {|e| e.typename == 'Face'}
        largest_face = [0, nil]

        sorted_faces = Hash[*faces.collect{|f| [f,f.area.round(3)]}.flatten].sort_by{|k,v|v}

        largest_face = sorted_faces[-1]
        # faces.each do |face|
        #   if face.area >= largest_face[0]
        #     largest_face[0] = face.area
        #     largest_face[1] = face
        #   else
        #     next
        #   end
        # end
        return largest_face[0]
      end

      def sort_plates_for_spreading(plates)
        sorted = []
        alphabet = ("A".."Z").to_a
        plates.each_with_index do |pl, i|
          letter = pl.name
          alphabet.each_with_index do |let, i2|
            if letter == let
              sorted[i2] = pl
              break
            end
          end
        end

        return sorted
      end

      def get_plate_thickness_verified(mock_plate)
        thckchk1 = nil
        thckchk2 = nil
        thckchk3 = nil

        #gets thickness check 1
        thickness = nil
        case mock_plate.material.name
        when /¾/
          thckchk1 = 0.750
        when /⅝/
          thckchk1 = 0.625
        when /½/
          thckchk1 = 0.500
        when /⅜/
          thckchk1 = 0.375
        when /5\/16/
          thckchk1 = 0.312
        when /¼/
          thckchk1 = 0.250
        when /Special/
          thckchk1 = 0
        else
          thckchk1 = nil
        end

        es = []
        fc = []
        edges = extract_entities(mock_plate.definition, es, "Edge")
        faces = extract_entities(mock_plate.definition, fc, "Face")

        thckchk2 = get_most_common_edge(edges)[0][0]

        sorted_faces = Hash[*faces.collect{|f| [f,f.area.round(3)]}.flatten].sort_by{|k,v|v}
        biggies = sorted_faces.last(2)

        plane = biggies[0][0].plane
        point = biggies[1][0].vertices[0].position
        dist = point.distance_to_plane(plane).round(3)
        thckchk3 = dist
        if thckchk1 == thckchk2 && thckchk2 == thckchk3
          p "Black Swan! BOO YA"
        end

        #THIS IS A PATCH FOR WHEN PLATES ARE COLORED A COLOR DIFFEREN THAN THE NORMAL THICKNESS COLORS, JUST ASSIGNS IT A DIFFERENT
        if thckchk1.nil?
          thckchk1 = thckchk3
        end
        # p '-----------------'
        # p thckchk1 #Material Name Thickness Assumption
        # p thckchk2 #Most common Edge Length Assumption (Least Dependable)
        # p thckchk3 #Distance from both largest surfaces
        # p '-----------------'
        # add method to blend and check all 3 thickness checks

        ###################################
        tolerance = 0.00125
        if thckchk1 > 0
          if thckchk1 == thckchk3
            if (thckchk1 == thckchk2) || thckchk3 == (get_most_common_edge(edges)[1][0])
              #black swan
              # p '100%'
              probable_thickness = thckchk1
            elsif thckchk3 == (get_most_common_edge(edges)[1][0])#second most numerous edge length
              #black swan again
              # p '98%'
              probable_thickness = thckchk1
            else
              # p '95%'
              probable_thickness = thckchk1
            end
          elsif (thckchk1 - thckchk3) <= tolerance
            # p '95%'
            probable_thickness = thckchk1
          else
            # p '80%'
            probable_thickness = thckchk1
          end
        else
          # p 'special thick case'
          #round to the nearest 1/8" thickness for thckchk3
          if (thckchk3 % 0.125) > 0.0
            probable_thickness = (thckchk3/0.125).round(0)/8
          else
            probable_thickness = thckchk3
          end
        end

        if probable_thickness == 0.312
          probable_thickness = 0.3125
        end

        return probable_thickness
      end

      def get_most_common_edge(edges)
        lengths = Hash.new(0)
        # p edges
        edges.each do |e|
          lengths[e.length.round(3)] += 1
        end
        a = lengths.sort_by {|k,v| -v}
        return a
      end

      def extract_entities(entity, container, name)
        entity.entities.each do |ent|
          if (ent.is_a? Sketchup::Group) || (ent.is_a? Sketchup::ComponentInstance)
            extract_entities(ent.definition, container, name)
          elsif ent.typename == name
            container.push ent
          end
        end

        return container
      end

      def to_eighths(num)

        case num.to_r.denominator.round(2)
        when 1
          number = (num.to_f * 8).to_i
        when 2
          number = (num.to_f * 8).to_i
        when 4
          number = (num.to_f * 8).to_i
        when 8
          number = (num.to_f * 8).to_i
        when 16
          number = "2+"
        else
          # p "in the else"
          # p num
          # p 5/16.to_f
          # p (5/16.to_f).round(2)
          if num.round(2) == (5/16.to_f).round(2)
            number = "2+"
          else
            number = num
          end
        end
        return number
      end

      def explode_to_plate_standards(entity_list) #Needs to ignore entities with the "/HOLE/" tag
        entity_list.each do |e|
          #check if entity is a group if it is then explode it
          if (e.is_a? Sketchup::Group) || (e.is_a? Sketchup::ComponentInstance)
            e.locked = false if e.locked?
            if e.layer.name.include? "Hole"
              next
            else
              parts = e.explode
              explode_to_plate_standards(parts)
            end
          else
            next
          end
        end
      end

      ###################DELETE ME#################
      # model = Sketchup.active_model
      # ents = model.entities
      # file = Sketchup.find_support_files('skp', 'Plugins/ea_steel_tools/Beam Components')
      # dl = model.definitions
      # insert_point = ORIGIN.clone

      # file.each do |f|
      #   f2 = dl.load f
      #   ent = ents.add_instance f2, insert_point
      #   insert_point[0] += (ent.bounds.width + 3)
      # end
      ###################DELETE ME#################

  
# Define the method "spread_plates" which arranges plate entities by filtering, sorting,
# copying, transforming, and labeling them.
      def spread_plates
        # Begin a block to catch exceptions so that any errors can be handled gracefully.
        begin
          # Initialize an empty array to store the copies of the plates that will be created.
          plate_copies = []  # Changed 'copies' to 'plate_copies'
          
          # Create an array of uppercase letters from "A" to "Z" which is used to filter the plates by name.
          alphabet = ("A".."Z").to_a  # Changed 'alph' to 'alphabet'
          
          # Filter the list of plates (@d_list) to include only those plates whose name is one of the letters in the alphabet.
          # The block returns the plate if its name is included in the alphabet array.
          # Then, compact! is called to remove any nil values from the result.
          filtered_plates = @d_list.map { |plate| plate if alphabet.include? plate.name }.compact!
          
          # Sort the filtered plates by calling a helper method that prepares them for the spreading process.
          sorted_plates = sort_plates_for_spreading(filtered_plates)
          
          # Initialize a variable for the next distance value; however, note that this variable is not used further.
          next_distance = 0  # Unused variable, not renamed
          
          # Initialize a variable to keep track of the cumulative width of plates placed horizontally.
          last_plate_width = 0  # Unused variable, not renamed
          
          # Define a starting distance value (set to 1) which is later used in calculating the insertion point.
          dist = 1  # Unused variable, not renamed
          
          # Create an empty array to hold positions of labels for each plate.
          label_positions = []  # Changed 'label_locs' to 'label_positions'
          
          # Create a new group within the current entities; this group will contain all plate copies.
          @plate_group = @entities.add_group
          
          # The following line (commented out) would set the group's name to 'Plates' if enabled.
          # @plate_group.instance.name = 'Plates'  # Commented out, not renamed
          
          # Remove any nil entries from the sorted_plates array (in case any were introduced during sorting).
          sorted_plates.compact!
          
          # Start a new operation in the model with the name "spread a plate". This is used for undo/redo management.
          @model.start_operation("spread a plate", true)
          
          # Iterate over each plate in the sorted list of plates.
          sorted_plates.each do |plate|
            # Calculate the diagonal length of the plate's bounding box. This value is used to determine placement.
            diagonal_length = plate.bounds.diagonal  # Changed 'diag_length' to 'diagonal_length'
            
            # Define the insertion point for this plate copy. The x-coordinate is 'dist', the y-coordinate
            # is set to the negative of the diagonal length (to offset the plate vertically), and the z-coordinate is 0.
            insertion_point = [dist, -diagonal_length, 0]  # Changed 'insertion_pt' to 'insertion_point'
            
            # Create an instance (copy) of the current plate and add it to the plate group at the specified insertion point.
            plate_copy = @plate_group.entities.add_instance plate, insertion_point  # Changed 'pl_cpy' to 'plate_copy'
            
            # Add the newly created plate copy to the array of plate copies for later reference.
            plate_copies.push plate_copy
            
            # Set the material of the plate copy to be the same as the material of the first instance of the original plate.
            plate_copy.material = plate.instances.first.material
            
            # The following section compares the plate copy with pre-scraped plate definitions to ensure proper scaling.
            # Retrieve the definition (i.e. component definition) of the plate copy.
            copy_definition = plate_copy.definition  # Changed 'copy_def' to 'copy_definition'
            
            # From a list of named plate definitions, select those that match the copy's definition.
            property_definition = @named_plate_definitions.select { |pd| pd if pd == copy_definition }
            
            # Extract the x-scale factor from the transformation of the first instance of the matched property definition.
            x_scale = property_definition[0].instances.first.transformation.xscale  # Changed 'x' to 'x_scale'
            
            # Extract the y-scale factor from the transformation.
            y_scale = property_definition[0].instances.first.transformation.yscale  # Changed 'y' to 'y_scale'
            
            # Extract the z-scale factor from the transformation.
            z_scale = property_definition[0].instances.first.transformation.zscale  # Changed 'z' to 'z_scale'
            
            # Create a scaling transformation using the extracted x, y, and z scale factors.
            transformation = Geom::Transformation.scaling(x_scale, y_scale, z_scale)  # Changed 'trans' to 'transformation'
            
            # Apply the scaling transformation to the plate copy in place.
            plate_copy_transformed = plate_copy.transform! transformation  # Changed 'pl_cpy_trans' to 'plate_copy_transformed'
            
            # Calculate the number of instances for the current plate definition (subtracting one to exclude the original).
            plate_count = (plate_copy.definition.count_instances - 1)  # Changed 'plate_count' to 'plate_count'
            
            # Create a temporary group for further processing such as exploding the plate and verifying its thickness.
            temp_group = @entities.add_group()
            
            # Within the temporary group, add an instance of the original plate at the origin (ORIGIN constant assumed defined).
            temp_plate = temp_group.entities.add_instance plate, ORIGIN  # Changed 'temp_plate' to 'temp_plate'
            
            # Set the material of the temporary group to match that of the original plate for visual consistency.
            temp_group.material = plate.instances[0].material
            
            # Apply the scaling transformation to the temporary plate to standardize its dimensions.
            temp_plate.transform! transformation
            
            # Make the temporary plate unique by breaking its link with the original component definition.
            temp_plate.make_unique
            
            # Explode the temporary plate into its individual entities; this may help in further processing,
            # especially if special handling for column plates is required.
            temp_plate.explode # May need to do special exploding for column plates
            
            # Convert the temporary group (now containing the exploded plate) into a component,
            # which will be used to verify the plate's thickness.
            temp_component = temp_group.to_component
            
            # Retrieve the verified thickness of the plate by calling a helper method on the temporary component.
            verified_thickness = get_plate_thickness_verified(temp_component)
            
            # Store the verified thickness as a floating-point number in the plate copy's attribute dictionary.
            plate_copy.definition.attribute_dictionary(PLATE_DICTIONARY)[TH_LABEL] = verified_thickness.to_f
            
            # Also store the verified thickness as a rational number (converted to a string) in the attribute dictionary.
            plate_copy.definition.attribute_dictionary(PLATE_DICTIONARY)[M_LABEL] = verified_thickness.to_r.to_s
            
            # Set the quantity attribute in the plate copy's definition to the calculated plate_count.
            plate_copy.definition.attribute_dictionary(PLATE_DICTIONARY)[Q_LABEL] = plate_count
            
            # Rename the plate copy to include the plate count, using a prefix "x" for easier identification.
            plate_copy.name = "x" + plate_count.to_s  # Changed 'name' to more readable format
            
            # Explode the plate copy's entities to standardize its structure for the labeling process.
            explode_to_plate_standards(plate_copy.definition.entities)
            
            # Determine the largest face of the plate copy, which will be used to establish its orientation.
            if face = get_largest_face(plate_copy)
              # If a largest face is found, extract its normal vector to understand the plate's orientation.
              plate_normal = face.normal  # Changed 'pl_norm' to 'plate_normal'
            else
              # If no valid face is found, print a message to the console for debugging purposes.
              p 'found nil'
              # Skip processing this plate and move to the next one in the iteration.
              next
            end
            
            # Begin the rotation process to orient the plate based on its normal vector.
            # Check if the plate's normal is not parallel to the Z-axis (vertical); if it is not, further adjustments are required.
            if not plate_normal.parallel? Z_AXIS
              # If the plate normal is parallel to the X-axis, perform a set of rotations relative to Y and Z axes.
              if plate_normal.parallel? X_AXIS
                # Calculate the angle between the plate normal and the Y-axis for the first rotation.
                rotation_1 = plate_normal.angle_between Y_AXIS  # Changed 'rotation1' to 'rotation_1'
                # Calculate the angle between the plate normal and the Z-axis for the second rotation.
                rotation_2 = plate_normal.angle_between Z_AXIS  # Changed 'rotation2' to 'rotation_2'
                # Rotate the plate copy about the Z-axis at the insertion point using the first calculated rotation angle.
                plate_copy.transform! (Geom::Transformation.rotation insertion_point, [0, 0, 1], rotation_1)
                # Rotate the plate copy about the X-axis at the insertion point using the second calculated rotation angle.
                plate_copy.transform! (Geom::Transformation.rotation insertion_point, [1, 0, 0], rotation_2)
              end
              # If the plate normal is parallel to the Y-axis, perform an alternative rotation.
              if plate_normal.parallel? Y_AXIS
                # Calculate the angle between the plate normal and the Z-axis.
                rotation_2 = plate_normal.angle_between Z_AXIS  # Changed 'rotation2' to 'rotation_2'
                # Rotate the plate copy about the X-axis at the insertion point using the calculated angle.
                plate_copy.transform! (Geom::Transformation.rotation insertion_point, [1, 0, 0], rotation_2)
              end
            end
            
            # Apply an additional rotation of 180 degrees about the Z-axis at the insertion point.
            # This may be used to invert or further adjust the plate's orientation.
            plate_copy.transform! Geom::Transformation.rotation(insertion_point, [0, 0, 1], 180.degrees)
            
            # Check if the plate's bounding box width is greater than its height to decide if further rotation is needed.
            # This aligns the plate's longer edge with the Y-axis.
            if plate_copy.bounds.width > plate_copy.bounds.height
              # Rotate the plate copy 270 degrees about the Z-axis at the insertion point to align its long edge with the Y-axis.
              plate_copy.transform! Geom::Transformation.rotation(insertion_point, [0, 0, 1], 270.degrees)
            end
            
            # Retrieve the current bounding box of the plate copy.
            plate_bounds = plate_copy.bounds
            
            # Get the minimum (corner) point of the plate copy's bounding box.
            plate_corner = plate_bounds.min  # Changed 'pl_corner' to 'plate_corner'
            
            # Calculate a position vector by subtracting the bounding box's corner from the plate's origin.
            # This vector is used to align the internal entities with the new origin.
            position_vector = plate_copy.transformation.origin - plate_corner  # Changed 'pos_vec' to 'position_vector'
            
            # Create a translation transformation based on the calculated position vector.
            position_entities = Geom::Transformation.translation(position_vector)  # Changed 'pos_entities' to 'position_entities'
            
            # Apply the translation to all entities within the plate copy's definition, shifting them appropriately.
            plate_copy.definition.entities.transform_entities position_entities, plate_copy
            
            # Retrieve the updated bounding box of the transformed plate copy.
            plate_bounds = plate_copy.bounds
            
            # Extract the width of the plate from its bounding box.
            width = plate_bounds.width  # Changed 'w' to 'width'
            
            # Extract the height of the plate from its bounding box.
            height = plate_bounds.height  # Changed 'h' to 'height'
            
            # Extract the depth of the plate from its bounding box.
            depth = plate_bounds.depth  # Changed 'd' to 'depth'
            
            # Retrieve the maximum (opposite corner) point of the plate copy's bounding box.
            plate_max = plate_bounds.max  # Changed 'plc' to 'plate_max'
            
            # Adjust the plate's position if it has positive Z coordinates, which might indicate it is elevated above the base.
            if plate_max[2] > 0
              # Create a vector that represents the displacement needed in the Z-direction.
              vector = Geom::Vector3d.new(0, 0, (plate_max[2] * 1))  # Changed 'vec' to 'vector'
              # Apply a translation transformation in the opposite direction (using the reversed vector) to lower the plate.
              plate_copy.transform! (Geom::Transformation.translation(vector.reverse))
            end
            
            # Adjust the plate's position if its maximum X-coordinate is negative, ensuring it is properly positioned.
            if plate_max[0] < 0
              # Create a vector based on the negative X-coordinate.
              vector = Geom::Vector3d.new((plate_max[0] * 1), 0, 0)  # Changed 'vec' to 'vector'
              # Apply a translation transformation using the reversed vector to correct the X-position.
              plate_copy.transform! (Geom::Transformation.translation(vector.reverse))
            end
            
            # Translate the plate copy horizontally based on the cumulative width of the previously placed plates.
            plate_copy.transform! (Geom::Transformation.translation([last_plate_width, 0, 0]))
            
            # *** New code to ensure alignment using the top-left most corner of the bounding box ***
            # Compute the top-left most corner in the XY plane. Here, 'left' is defined as the minimum X value and
            # 'top' is the maximum Y value of the bounding box.
            top_left = Geom::Point3d.new(plate_bounds.min.x, plate_bounds.max.y, plate_bounds.min.z)
            # Compute a translation that moves the top_left's y-coordinate to 0.
            y_translation = Geom::Transformation.translation([0, -top_left.y, 0])
            plate_copy.transform! y_translation
            
            # Output the current location (origin) of the plate copy after all transformations,
            # which aids in debugging and verifying placement.
            p "Plate #{plate_copy.name} location: #{plate_copy.transformation.origin}"
            
            # Label the plate by creating a text or marker label associated with the plate copy.
            # The helper function label_plate handles the creation and association of the label.
            plate_label = label_plate(plate_copy, @plate_group)  # Changed 'pl_label' to 'plate_label'
            
            # Assign the created label to a specific layer designated for labels.
            set_layer(plate_label, LABELS_LAYER)
            
            # Save the label's position (specifically the second corner of its bounding box) into the plate copy's attribute dictionary.
            plate_copy.definition.attribute_dictionary(PLATE_DICTIONARY)[INFO_LABEL_POSITION] = plate_label.bounds.corner(1)
            
            # Add the center of the plate copy's bounding box to the label_positions array for potential future use.
            label_positions.push plate_copy.bounds.center  # Changed 'label_locs' to 'label_positions'
            
            # Determine the "pull out" distance based on the height of the plate's bounding box.
            # This value might be used for spacing or further layout adjustments.
            pull_out_distance = plate_copy.bounds.height  # Changed 'pull_out_dist' to 'pull_out_distance'
            
            # Update the cumulative horizontal offset (last_plate_width) by adding the current plate's width and an extra 3-unit spacing.
            last_plate_width += (width + 3)
            
            # Remove the temporary component created for thickness verification to clean up temporary entities.
            temp_component.erase!
          end
          # After processing all plates, return the array containing all the plate copies.
          return plate_copies  # Changed 'copies' to 'plate_copies'
          
        # Rescue any exceptions that occur during the process to prevent the operation from crashing.
        rescue Exception => e
          # Output the exception message to the console for debugging.
          puts e.message
          # Output the backtrace of the exception, which shows the call stack at the time of the error.
          puts e.backtrace.inspect
          # Display a user-friendly message box informing the user that there was a problem during the process.
          UI.messagebox("There was a problem gathering and spreading the plates")
        end
      end


      
      

      def deactivate(view)
        # restore_material(@plates) if @state != 0
      end

      def onMouseMove(flags, x, y, view)
        Sketchup.status_text = @status_text if @state == 0
      end

      def suspend(view)
        view.invalidate
      end

      def resume(view)
        view.invalidate
      end

    end
  end
end