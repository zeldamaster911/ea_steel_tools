module EA_Extensions623
  module EASteelTools
    extension_path = File.dirname( __FILE__ )
    skui_path = File.join( extension_path, 'SKUI' )
    load File.join( skui_path, 'embed_skui.rb' )
    ::SKUI.embed_in( self )
    # SKUI module is now available under EA_Steel_Tools::SKUI

    class FlangeDialog
      include BeamLibrary

      @@state = 0

      def initialize
        if @@state == 0
          @@beam_data         = {}             #Hash   {:d=>4.16, :bf=>4.06, :tf=>0.345, :tw=>0.28, :r=>0.2519685039370079, :width_class=>4}"
          @@beam_name         = ''             #String 'W(height_class)X(weight_per_foot)'
          @@height_class      = ''             #String 'W(number)'
          @@placement         = 'BOTTOM'       #String 'TOP' or 'BOTTOM'
          @@has_holes         = true           #Boolean
          @@hole_spacing      = 16             #Integer 16 or 24
          @@cuts_holes        = false          #Boolean
          @@has_stiffeners    = true           #Boolean
          @@has_shearplates   = true           #Boolean
          @@stiff_thickness   = '1/4'          #String '1/4' or '3/8' or '1/2'
          @@shearpl_thickness = '3/8'          #String '3/8' or '1/2' or '3/4'
          @@force_studs       = false          #Boolean
          @@state             = 1
          @@flange_type       = '' #Beam or Column Options
          @@start_tolerance   = 1.5 #height that the wide flange column is offset from the ground
        end

        options = {
          :title           => "Wide Flange Steel #{STEEL_EXTENSION.version}",
          :preferences_key => 'WFS',
          :width           => 416,
          :height          => 475,
          :resizable       => false
        }

        window = SKUI::Window.new( options )

        @window1 = window

        # These events doesn't trigger correctly when Firebug Lite
        # is active because it introduces frames that interfere with
        # the focus notifications.
        # window.on( :focus )  { puts 'Window Focus' }
        # window.on( :blur )   { puts 'Window Blur' }
        window.on( :resize ) { |window, width, height|
          # puts "Window Resize(#{width}, #{height})"
        }

        #Creates the top group box that holds the dropdown lists of the
        group = SKUI::Groupbox.new( 'Select Beam' )
        group.position( 5, 5 )
        group.right = 5
        group.height = 100
        window.add_control( group )

        hc_list_label = SKUI::Label.new('Height Class')
        hc_list_label.position(10,27)

        beam_size_label = SKUI::Label.new('Beam Size')
        beam_size_label.position(10,57)
        group.add_control( hc_list_label )
        group.add_control( beam_size_label )

        list = all_height_classes
        height_class_dropdown = SKUI::Listbox.new( list )
        @@height_class.empty? ? @@height_class = (height_class_dropdown.value = height_class_dropdown.items.sample) : height_class_dropdown.value = height_class_dropdown.items.grep(@@height_class).first.to_s
        height_class_dropdown.position( 105, 25 )
        height_class_dropdown.width = 140

        list = all_beams_in(@@height_class)
        beam_size_dropdown = SKUI::Listbox.new( list )
        @@beam_name.empty? ? @@beam_name = (beam_size_dropdown.value = beam_size_dropdown.items.first) : @@beam_name = (beam_size_dropdown.value = beam_size_dropdown.items.grep(@@beam_name).first.to_s)
        beam_size_dropdown.position( 105, 55 )
        beam_size_dropdown.width = 140

        group.add_control( beam_size_dropdown )

        height_class_dropdown.on( :change ) { |control, value|
          @@height_class = control.value
          list = all_beams_in(control.value)
          beam_size_dropdown = SKUI::Listbox.new( list )
          @@beam_name = beam_size_dropdown.value = beam_size_dropdown.items.first
          beam_size_dropdown.position( 105, 55 )
          beam_size_dropdown.width = 140
          group.add_control( beam_size_dropdown )
          beam_size_dropdown.on( :change ) { |control, value|
            @@beam_name = control.value
            p @@beam_name
          }
        }
        group.add_control( height_class_dropdown )

        beam_size_dropdown.on( :change ) { |control, value|
          @@beam_name = control.value
          p @@beam_name
        }

        chk_force_studs = SKUI::Checkbox.new( 'Force Studs' )
        chk_force_studs.position( 300, 20 )
        chk_force_studs.checked = @@force_studs
        chk_force_studs.on( :change ) { |control|
          @@force_studs = control.checked?
        }
        group.add_control( chk_force_studs )

        flange_type_label = SKUI::Label.new('Type')
        flange_type_label.position(270,59)
        group.add_control( flange_type_label )

        @flange_types = [FLANGE_TYPE_BM, FLANGE_TYPE_COL]
        flange_type_select = SKUI::Listbox.new(@flange_types)
        flange_type_select.position(310, 55)
        flange_type_select.width = 68
        @@flange_type.empty? ? @@flange_type = (flange_type_select.value = @flange_types.first) : (flange_type_select.value = @@flange_type)

        group.add_control(flange_type_select)

        ##################################################################################
        ##################################################################################

        group2 = SKUI::Groupbox.new( 'Path Selection' )
        group2.position( 58, 103 )
        group2.right = 20
        group2.width = 300
        group2.height = 200
        window.add_control( group2 )

        path = File.join( SKUI::PATH, '..', 'icons' )
        file = File.join( path, 'profile2.png' )

        label_font = SKUI::Font.new( 'Comic Sans MS', 8, true )

        img_profile = SKUI::Image.new( file )
        img_profile.position( 28, 32 )
        img_profile.width = 200
        img_profile.height = 130
        group2.add_control( img_profile )

        top_select = SKUI::RadioButton.new ('Draw From Top')
        top_select.position(122, 18)
        top_select.checked = true if @@placement == 'TOP'
        top_select.on (:change ) { |control|
          @@placement = 'TOP' if control.checked?
        }
        group2.add_control( top_select )

        mid_select = SKUI::RadioButton.new ('Draw From Middle')
        mid_select.position(122, 90)
        mid_select.checked = true if @@placement == 'MID'
        mid_select.on (:change ) { |control|
          @@placement = 'MID' if control.checked?
        }
        group2.add_control( mid_select )

        bottom_select = SKUI::RadioButton.new ('Draw From Bottom')
        bottom_select.position(122, 159)
        bottom_select.checked = true if @@placement == 'BOTTOM'
        bottom_select.on ( :change ) { |control|
          @@placement = 'BOTTOM' if control.checked?
        }
        group2.add_control ( bottom_select )


        flange_type_select.on(:change) {|control|
          # p control.value
          @@flange_type = control.value
          mid_select.visible = control.value == FLANGE_TYPE_BM
          top_select.visible = control.value == FLANGE_TYPE_BM
          bottom_select.checked = true if control.value == FLANGE_TYPE_COL
          mid_select.checked = !bottom_select.checked?
          top_select.checked = !bottom_select.checked?
          if control.value == FLANGE_TYPE_COL
            @@placement = 'BOTTOM'
          end
          # p @@placement
        }
        # start_tol = SKUI::Textbox.new (@@start_tolerance.to_f)
        # start_tol.name = :start_tolerance
        # start_tol.position(80,100)
        # start_tol.width = 50
        # start_tol.height = 20
        # start_tol.on( :textchange ) { |control|
        #   @@start_tolerance = control.value.to_s.to_r.to_f
        # }
        # group2.add_control start_tol

        # end_tol_label = SKUI::Label.new('B - Tolerance', start_tol)
        # # end_tol_label.position(5, 100)
        # group2.add_control(end_tol_label)
        # end_tol_label.visible = @@flange_type == FLANGE_TYPE_COL
        #################################################################################
        #################################################################################

        group3 = SKUI::Groupbox.new( 'Options' )
        group3.position( 5, 305 )
        group3.right = 5
        group3.height = 100
        window.add_control( group3 )

        color = Sketchup::Color.new "White"

        container_stiff = SKUI::Container.new
        container_stiff.foreground_color = color
        container_stiff.stretch( 0, 0, 0, 0 )
        group3.add_control( container_stiff )

        container_shear = SKUI::Container.new
        container_shear.foreground_color = color
        container_shear.stretch( 0, 0, 0, 0 )
        container_stiff.add_control( container_shear )

        options_list_label = SKUI::Label.new('Spacing :')
        options_list_label.position(88,18)
        options_list_label.visible = @@has_holes
        group3.add_control( options_list_label )

        #########
        sel_manual = SKUI::Textbox.new(@@hole_spacing)
        sel_manual.position(250,15)
        sel_manual.width = 35
        sel_manual.height = 25
        sel_manual.on(:textchange) {|control|
          @@hole_spacing = control.value.to_s.to_r.to_f
        }
        sel_manual.visible = @@has_holes
        group3.add_control(sel_manual)
        #############

        # create 2 radio buttins for 16" and 24"
        sel_16 = SKUI::RadioButton.new("16\"")
        sel_16.position(148,20)
        sel_16.checked = true if @@hole_spacing == 16
        sel_16.on(:change) {|control|
          @@hole_spacing = 16 if control.checked?
          sel_manual.value = @@hole_spacing if control.checked?
        }
        sel_16.visible = @@has_holes
        group3.add_control(sel_16)

        sel_24 = SKUI::RadioButton.new("24\"")
        sel_24.position(195,20)
        sel_24.checked = true if @@hole_spacing == 24
        sel_24.on(:change) {|control|
          @@hole_spacing = 24 if control.checked?
          sel_manual.value = @@hole_spacing if control.checked?
        }
        sel_24.visible = @@has_holes
        group3.add_control(sel_24)

        chk_cut_holes = SKUI::Checkbox.new( 'Cut?' )
        chk_cut_holes.position( 310, 20 )
        group3.add_control( chk_cut_holes )
        chk_cut_holes.checked = @@cuts_holes
        chk_cut_holes.visible = @@has_holes
        chk_cut_holes.on (:change ) { |control|
          @@cuts_holes = control.checked?
        }

        chk_holes = SKUI::Checkbox.new( 'Holes' )
        chk_holes.position( 10, 20 )
        chk_holes.checked = @@has_holes
        chk_holes.on( :change ) { |control|
          @@has_holes                = control.checked?
          chk_cut_holes.visible      = @@has_holes
          sel_16.visible             = @@has_holes
          sel_24.visible             = @@has_holes
          options_list_label.visible = @@has_holes
          # options_list_label.visible = @@has_holes
        }
        group3.add_control( chk_holes )

        # create 3 radio buttons for the stiffener thickness
        sel_stiff_thck_1 = SKUI::RadioButton.new("1/4\"")
        sel_stiff_thck_1.position(120, 45)
        sel_stiff_thck_1.checked = true if @@stiff_thickness == '1/4'
        sel_stiff_thck_1.on(:change) {|control|
          @@stiff_thickness = '1/4' if control.checked?
        }
        sel_stiff_thck_1.visible = @@has_stiffeners
        container_stiff.add_control(sel_stiff_thck_1)

        sel_stiff_thck_4 = SKUI::RadioButton.new("5/16\"")
        sel_stiff_thck_4.position(180, 45)
        sel_stiff_thck_4.checked = true if @@stiff_thickness == '5/16'
        sel_stiff_thck_4.on(:change) {|control|
          @@stiff_thickness = '5/16' if control.checked?
        }
        sel_stiff_thck_4.visible = @@has_stiffeners
        container_stiff.add_control(sel_stiff_thck_4)

        sel_stiff_thck_2 = SKUI::RadioButton.new("3/8\"")
        sel_stiff_thck_2.position(240, 45)
        sel_stiff_thck_2.checked = true if @@stiff_thickness == '3/8'
        sel_stiff_thck_2.on(:change) {|control|
          @@stiff_thickness = '3/8' if control.checked?
        }
        sel_stiff_thck_2.visible = @@has_stiffeners
        container_stiff.add_control(sel_stiff_thck_2)

        sel_stiff_thck_3 = SKUI::RadioButton.new("1/2\"")
        sel_stiff_thck_3.position(300, 45)
        sel_stiff_thck_3.checked = true if @@stiff_thickness == '1/2'
        sel_stiff_thck_3.on(:change) {|control|
          @@stiff_thickness = '1/2' if control.checked?
        }
        sel_stiff_thck_3.visible = @@has_stiffeners
        container_stiff.add_control(sel_stiff_thck_3)

        chk_stiffeners = SKUI::Checkbox.new( 'Stiffeners' )
        chk_stiffeners.position( 10, 45 )
        chk_stiffeners.checked = @@has_stiffeners
        chk_stiffeners.on( :change ) { |control|
          @@has_stiffeners = chk_stiffeners.checked?
          sel_stiff_thck_4.visible = @@has_stiffeners
          sel_stiff_thck_3.visible = @@has_stiffeners
          sel_stiff_thck_2.visible = @@has_stiffeners
          sel_stiff_thck_1.visible = @@has_stiffeners
        }
        container_stiff.add_control( chk_stiffeners )
        ########################################################################
        ########################################################################


        # create 3 radio buttons for the shearplate thickness
        sel_shear_thck_1 = SKUI::RadioButton.new("3/8\"")
        sel_shear_thck_1.position(120, 70)
        sel_shear_thck_1.checked = true if @@shearpl_thickness == '3/8'
        sel_shear_thck_1.on(:change) {|control|
          @@shearpl_thickness = '3/8' if control.checked?
        }
        sel_shear_thck_1.visible = @@has_shearplates
        container_shear.add_control(sel_shear_thck_1)

        sel_shear_thck_2 = SKUI::RadioButton.new("1/2\"")
        sel_shear_thck_2.position(180, 70)
        sel_shear_thck_2.checked = true if @@shearpl_thickness == '1/2'
        sel_shear_thck_2.on(:change) {|control|
          @@shearpl_thickness = '1/2' if control.checked?
        }
        sel_shear_thck_2.visible = @@has_shearplates
        container_shear.add_control(sel_shear_thck_2)

        sel_shear_thck_3 = SKUI::RadioButton.new("5/8\"")
        sel_shear_thck_3.position(240, 70)
        sel_shear_thck_3.checked = true if @@shearpl_thickness == '5/8'
        sel_shear_thck_3.on(:change) {|control|
          @@shearpl_thickness = '5/8' if control.checked?
        }
        sel_shear_thck_3.visible = @@has_shearplates
        container_shear.add_control(sel_shear_thck_3)

        sel_shear_thck_4 = SKUI::RadioButton.new("3/4\"")
        sel_shear_thck_4.position(300, 70)
        sel_shear_thck_4.checked = true if @@shearpl_thickness == '3/4'
        sel_shear_thck_4.on(:change) {|control|
          @@shearpl_thickness = '3/4' if control.checked?
        }
        sel_shear_thck_4.visible = @@has_shearplates
        container_shear.add_control(sel_shear_thck_4)

        chk_shearplates = SKUI::Checkbox.new( 'Shear Plates' )
        chk_shearplates.position( 10, 70 )
        chk_shearplates.checked = @@has_shearplates
        chk_shearplates.on( :change ) { |control|
          @@has_shearplates = chk_shearplates.checked?
          sel_shear_thck_4.visible = @@has_shearplates
          sel_shear_thck_3.visible = @@has_shearplates
          sel_shear_thck_2.visible = @@has_shearplates
          sel_shear_thck_1.visible = @@has_shearplates
        }
        container_shear.add_control( chk_shearplates )


        ########################################################################
        ########################################################################
        btn_ok = SKUI::Button.new( 'OK' ) { |control|
          @@beam_data = find_beam(@@height_class, @@beam_name)
          data = {
            name:              @@beam_name,
            height_class:      @@height_class,
            data:              @@beam_data,
            placement:         @@placement,
            has_holes:         @@has_holes,
            stagger:           @@hole_spacing,
            cuts_holes:        @@cuts_holes,
            stiffeners:        @@has_stiffeners,
            shearplates:       @@has_shearplates,
            stiff_thickness:   @@stiff_thickness,
            shearpl_thickness: @@shearpl_thickness,
            force_studs:       @@force_studs,
            flange_type:       @@flange_type
          }
          control.window.close
          Sketchup.active_model.select_tool EASteelTools::FlangeTool.new(data)
        }

        btn_ok.position( 5, -5 )
        btn_ok.font = SKUI::Font.new( 'Comic Sans MS', 14, true )
        window.add_control( btn_ok )

        ####################
        # The close button #
        ####################
        btn_close = SKUI::Button.new( 'Close' ) { |control|
          control.window.close
          Sketchup.send_action "selectSelectionTool:"
        }
        btn_close.position( -5, -5 )
        window.add_control( btn_close )

        window.default_button = btn_ok
        window.cancel_button = btn_close

        window.show

        window
      end

      def onKeyDown(key, repeat, flags, view)
        if key == 27
          @window1.release
          Sketchup.send_action "selectSelectionTool:"
        end
      end


      def self.close
        @window1.release
      end

      # def deactivate(view)
      #   @window1.close
      #   Sketchup.send_action "selectSelectionTool:"
      #   view.invalidate
      # end

    end #class

  end #module
end #module