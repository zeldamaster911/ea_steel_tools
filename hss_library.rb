module EA_Extensions623
  module HSSLibrary

    #this is the generic data for a beam, copy it to where you need it and input the values
    # "(size)" => { h: , b: , t: , c: ().mm, width_class: },

    def find_tube( height_class, width_class )
      input = HSSLibrary::HSS["#{height_class}"]["#{width_class}"]
      return input
    end

    def all_height_classes
      hss = []
      HSSLibrary::HSS.each do |k, v|
        hss << k
      end
      return hss
    end
    def all_plate_thicknesses
      pt = []
      HSSLibrary::PlateThicknesses.each do |k, v|
        pt << k
      end
      return pt
    end

    #returns an array of all the beams within a height class
    def all_tubes_in(height_class)
      hss = []
      HSSLibrary::HSS["#{height_class}"].each do |k, v|
        hss << k
      end
      return hss
    end

    def all_guage_options_in(height_class, width_class)
      wall_thickness_list = HSSLibrary::HSS["#{height_class}"]["#{width_class}"][:tw]
      return wall_thickness_list
    end
    PlateThicknesses = {
      '1/4"' => {t:0.25},
      '3/8"' => {t:0.375},
      '1/2"' => {t:0.5},
      '5/8"' => {t:0.625},
      '3/4"' => {t:0.75},
      '7/8"' => {t:0.875},
      '1"' => {t:1},
      '1 1/8"' => [t:1.125],
      '1 1/4"' => {t:1.25},
      '1 1/2"' => {t:1.5},
    }
    HSS = {

      "2" => {
        "2"  => { h:2 , b:2  , tw:['1/8"','3/16"','1/4"']},
        "1-1/2" => { h:2 , b:1.5, tw:['1/8"','3/16"']},
        "1"  => { h:2 , b:1  , tw:['1/8"','3/16"']}
      },

      "2-1/4" => {
        "2-1/4" => { h:2.25 , b:2.25, tw:['1/8"','3/16"','1/4"']},
        "2"  => { h:2.25 , b:2   , tw:['1/8"','3/16"']}
      },

      "2-1/2" => {
        "2-1/2" => { h:2.5 , b:2.5 , tw:['1/8"','3/16"','1/4"','5/16"']},
        "2"  => { h:2.5 , b:2   , tw:['1/8"','3/16"','1/4"']},
        "1-1/2" => { h:2.5 , b:1.5 , tw:['1/8"','3/16"','1/4"']},
        "1"  => { h:2.5 , b:1   , tw:['1/8"','3/16"']}
      },

      "3" => {
        "3"  => { h:3 , b:3   , tw:['1/8"','3/16"','1/4"','5/16"','3/8"']},
        "2-1/2" => { h:3 , b:2.5 , tw:['1/8"','3/16"','1/4"','5/16"']},
        "2"  => { h:3 , b:2   , tw:['1/8"','3/16"','1/4"','5/16"']},
        "1-1/2" => { h:3 , b:1.5 , tw:['1/8"','3/16"','1/4"']},
        "1"  => { h:3 , b:1   , tw:['1/8"','3/16"']}
      },

      "3-1/2" => {
        "3-1/2" => { h:3.5 , b:3.5 , tw:['3/16"','1/4"','5/16"','3/8"']},
        # "3"  => { h:3.5 , b:3   , tw:[]},
        "2-1/2" => { h:3.5 , b:2.5 , tw:['1/8"','3/16"','1/4"','5/16"','3/8"']},
        "2"  => { h:3.5 , b:2   , tw:['1/8"','3/16"','1/4"']},
        "1-1/2" => { h:3.5 , b:1.5 , tw:['1/8"','3/16"','1/4"']}
      },

      "4" => {
        "4"  => { h:4 , b:4   , tw:['3/16"','1/4"','5/16"','3/8"','1/2"']},
        "3"  => { h:4 , b:3   , tw:['1/8"','3/16"','1/4"','5/16"','3/8"']},
        "2-1/2" => { h:4 , b:2.5 , tw:['1/8"','3/16"','1/4"','5/16"','3/8"']},
        "2"  => { h:4 , b:2   , tw:['1/8"','3/16"','1/4"','5/16"','3/8"']}
      },

      "4-1/2" => {
        "4-1/2" => { h:4.5 , b:4.5, tw:['1/8"','3/16"','1/4"','5/16"','3/8"','1/2"']},
      },

      "5" => {
        "5"  => { h:5 , b:5   , tw:['3/16"','1/4"','5/16"','3/8"','1/2"']},
        "4"  => { h:5 , b:4   , tw:['1/8"','3/16"','1/4"','5/16"','3/8"','1/2"']},
        "3"  => { h:5 , b:3   , tw:['1/8"','3/16"','1/4"','5/16"','3/8"','1/2"']},
        "2-1/2" => { h:5 , b:2.5 , tw:['1/8"','3/16"','1/4"']},
        "2"  => { h:5 , b:2   , tw:['1/8"','3/16"','1/4"','5/16"','3/8"']}
      },

      # "5-1/2" => {
      #   "5-1/2" => { h:5.5 , b:5.5, tw:['3/16"','1/4"','5/16"','3/8"']}
      # },

      "6" => {
        "6"  => { h:6 , b:6   , tw:['3/16"','1/4"','5/16"','3/8"','1/2"', '5/8"']},
        "5"  => { h:6 , b:5   , tw:['1/8"','3/16"','1/4"','5/16"','3/8"','1/2"']},
        "4"  => { h:6 , b:4   , tw:['1/8"','3/16"','1/4"','5/16"','3/8"','1/2"']},
        "3"  => { h:6 , b:3   , tw:['1/8"','3/16"','1/4"','5/16"','3/8"', '1/2"']},
        "2"  => { h:6 , b:2   , tw:['1/8"','3/16"','1/4"','5/16"','3/8"']}
      },

      "7" => {
        "7"  => { h:7 , b:7   , tw:['3/16"','1/4"','5/16"','3/8"','1/2"', '5/8"']},
        "5"  => { h:7 , b:5   , tw:['3/16"','1/4"','5/16"','3/8"','1/2"']},
        "4"  => { h:7 , b:4   , tw:['3/16"','1/4"','5/16"','3/8"','1/2"']},
        "3"  => { h:7 , b:3   , tw:['3/16"','1/4"','5/16"','3/8"','1/2"']},
        "2"  => { h:7 , b:2   , tw:['3/16"','1/4"']}
      },

      "8" => {
        "8"  => { h:8 , b:8   , tw:['1/8"','3/16"','1/4"','5/16"','3/8"','1/2"','5/8"']},
        "6"  => { h:8 , b:6   , tw:['3/16"','1/4"','5/16"','3/8"','1/2"','5/8"']},
        "4"  => { h:8 , b:4   , tw:['1/4"','5/16"','3/8"','1/2"','5/8"']},
        "3"  => { h:8 , b:3   , tw:['1/8"','3/16"','1/4"','5/16"','3/8"','1/2"']},
        "2"  => { h:8 , b:2   , tw:['3/16"','1/4"','5/16"','3/8"']}
      },

      "9" => {
        "9"  => { h:9 , b:9  , tw:['1/8"','3/16"','1/4"','5/16"','3/8"','1/2"','5/8"']},
        "7"  => { h:9 , b:7  , tw:['3/16"','1/4"','5/16"','3/8"','1/2"','5/8"']},
        "5"  => { h:9 , b:5  , tw:['3/16"','1/4"','5/16"','3/8"','1/2"','5/8"']},
        "3"  => { h:9 , b:3  , tw:['3/16"','1/4"','5/16"','3/8"','1/2"']}
      },

      "10" => {
        "10" => { h:10 , b:10 , tw:['3/16"','1/4"','5/16"','3/8"','1/2"','5/8"']},
        "8"  => { h:10 , b:8  , tw:['3/16"','1/4"','5/16"','3/8"','1/2"','5/8"']},
        "6"  => { h:10 , b:6  , tw:['3/16"','1/4"','5/16"','3/8"','1/2"','5/8"']},
        "5"  => { h:10 , b:5  , tw:['3/16"','1/4"','5/16"','3/8"','1/2"']},
        "4"  => { h:10 , b:4  , tw:['1/8"','3/16"','1/4"','5/16"','3/8"','1/2"','5/8"']},
        "3-1/2" => { h:10 , b:3.5, tw:['1/8"','3/16"','1/4"','5/16"','3/8"','1/2"']},
        "3"  => { h:10 , b:3  , tw:['1/8"','3/16"','1/4"','5/16"','3/8"']},
        "2"  => { h:10 , b:2  , tw:['1/8"','3/16"','1/4"','5/16"','3/8"']}
      },

      "12" => {
        "12" => { h:12 , b:12 , tw:['3/16"','1/4"','5/16"','3/8"','1/2"','5/8"']},
        "10" => { h:12 , b:10 , tw:['1/4"','5/16"','3/8"','1/2"']},
        "8"  => { h:12 , b:8  , tw:['3/16"','1/4"','5/16"','3/8"','1/2"','5/8"']},
        "6"  => { h:12 , b:6  , tw:['3/16"','1/4"','5/16"','3/8"','1/2"','5/8"']},
        "4"  => { h:12 , b:4  , tw:['3/16"','1/4"','5/16"','3/8"','1/2"','5/8"']},
        "3-1/2" => { h:12 , b:3.5, tw:['5/16"','3/8"']},
        "3"  => { h:12 , b:3  , tw:['3/16"','1/4"','5/16"']},
        "2"  => { h:12 , b:2  , tw:['3/16"','1/4"','5/16"']}
      },

      "14" => {
        "14" => { h:14 , b:14 , tw:['5/16"','3/8"','1/2"','5/8"']},
        "10" => { h:14 , b:10 , tw:['1/4"','5/16"','3/8"','1/2"','5/8"']},
        "6"  => { h:14 , b:6  , tw:['3/16"','1/4"','5/16"','3/8"','1/2"','5/8"']},
        "4"  => { h:14 , b:4  , tw:['3/16"','1/4"','5/16"','3/8"','1/2"','5/8"']}
      },

      "16" => {
        "16" => { h:16 , b:16 , tw:['5/16"','3/8"','1/2"','5/8"','3/4"']},
        "12" => { h:16 , b:12 , tw:['5/16"','3/8"','1/2"','5/8"','3/4"']},
        "8"  => { h:16 , b:8  , tw:['1/4"','5/16"','3/8"','1/2"','5/8"']},
        "4"  => { h:16 , b:4  , tw:['3/16"','1/4"','5/16"','3/8"','1/2"','5/8"']}
      },

      "18" => {
        "6"  => { h:18 , b:6  , tw:['1/4"','5/16"','3/8"','1/2"','5/8"']}
      },

      "20" => {
        "12" => { h:20 , b:12 , tw:['5/16"','3/8"','1/2"','5/8"']},
        "8"  => { h:20 , b:8  , tw:['5/16"','3/8"','1/2"','5/8"']},
        "4"  => { h:20 , b:4  , tw:['1/4"','5/16"','3/8"','1/2"']}
      },
      "22" => {
        "22" => { h:22 , b:22 , tw:['3/4"', '7/8"']}
      }
    }

  end
end