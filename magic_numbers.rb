module EA_Extensions623
  module EASteelTools
    ####################
    ## MAIN CONSTANTS ##
    ####################
    ROOT_FILE_PATH = "ea_steel_tools"
    TEMP_FOLDER = "#{ROOT_FILE_PATH}/Temp"
    STEEL_EXTENSION = Sketchup.extensions[UNAME]
    STEEL_EXTENSION.version = '3.9'.freeze

    TEST_ENV = false


    #Setc the north direction as the green axis
    NORTH = Y_AXIS

    #Ghost Colors
    GC_XAXIS      = "Red"
    GC_YAXIS      = "Lime"
    GC_ZAXIS      = "Blue"
    GC_ONPLANE    = "Yellow"
    GC_OUTOFPLANE = "Gray"

    PLATE_DICTIONARY       = "3DS Steel"
    SCHEMA_KEY            = "SchemaType"
    SCHEMA_VALUE          = ":Plate"

    PLATE_ATTRIBUTE_CNC = "CNC_DATA"
    Q_LABEL = "QUANTITY"
    PN_LABEL = "PART_NAME"
    M_LABEL = "MATERIAL"
    TH_LABEL = "THICKNESS"
    INFO_LABEL_POSITION = 0

    DONE_COLOR = '1 Done'
    PLATE_COLOR = 'Black'

    #########################
    ##    Dictionaries     ##
    #########################
    PLATE_DICTIONARIES = [
      Q_LABEL,
      PN_LABEL,
      M_LABEL,
      TH_LABEL,
      INFO_LABEL_POSITION
    ]

    #########################
    ##       LAYERS        ##
    #########################
    STANDARD_LAYERS = [
      " (A) Gridlines",
      " (A) 0 Level (Lower)",
      " (A) 1 Level (Main)",
      " (A) 2 Level (Upper)",
      " (A) 3 Level (Roof)",
      " (A)  ALL Floor Plans",
      " (S)  ALL Steel",
      " (A) Arch. Model",
      " (A) Stairs Control",
      " (A) Compass",
      " (S) 1 Beams",
      " (S) 2 Beams",
      " (S) 3 Beams",
      " (S) 0 Columns",
      " (S) 1 Columns",
      " (S) 2 Columns",
      " (S) Bolts",
      " (S) Bolt Heads",
        #LAYER 0 NEEDS TO BE WHITE
      " (S) Centers", #PINK
      " (S) Scribes", #ORANGE
      " (S) Holes", #PURPLE
      " (S) Labels", #BLUE
      " (S) Info", #BROWN

      # " (S) Holes/Studs",
      " (C) Conc. Per Plan",
      " (C) Conc. As-Built",
      " (C) Foundation",
      " (F) General Framing",
      " (F) Joists",
      " (F) Critical Framing"
    ]

    BREAKOUT_LAYERS = ["Breakout_Part","Breakout_Plates", "DXF"]

    STEEL_LAYER = STANDARD_LAYERS.grep(/Steel/)[0]
    STUD_LAYER = STANDARD_LAYERS.grep(/Stud/)[0]
    HOLES_LAYER = STANDARD_LAYERS.grep(/Holes/)[0]
    CENTERS_LAYER = STANDARD_LAYERS.grep(/Centers/)[0]
    SCRIBES_LAYER = STANDARD_LAYERS.grep(/Scribes/)[0]
    INFO_LAYER = STANDARD_LAYERS.grep(/Info/)[0]
    LABELS_LAYER = STANDARD_LAYERS.grep(/Labels/)[0]


    #########################
    ## COMPONENT CONSTANTS ##
    #########################
    COMPONENT_PATH     = "#{ROOT_FILE_PATH}/Beam Components"
    THREEIGHTS_HOLE    = "Holes_ 3_8_ Hole Set.skp"
    NN_SXTNTHS_HOLE    = "Holes_ 9_16_ Hole Set.skp"
    THRTN_SXTNTHS_HOLE = "Holes_ 13_16_ Hole Set.skp"
    SVNEGHTHS_HOLE     = "Holes_ 7_8_ Hole Set.skp"
    UP_DRCTN           = "Label_  UP.skp"
    UP_DRCTN_MD        = "Label_  _Upm.skp"
    UP_DRCTN_SM        = "Label_  _up.skp"
    HLF_INCH_STD       = "Studs_ 2 x 1_2.skp"
    STEEL_FONT         = "3DSCAM"
    # STEEL_FONT         = "1CamBam_Stick_7"
    NORTH_LABEL        = "Label_ N.skp"
    NORTHWEST_LABEL    = "Label_ NW.skp"
    NORTHEAST_LABEL    = "Label_ NE.skp"
    SOUTH_LABEL        = "Label_ S.skp"
    SOUTHWEST_LABEL    = "Label_ SW.skp"
    SOUTHEAST_LABEL    = "Label_ SE.skp"
    EAST_LABEL         = "Label_ E.skp"
    WEST_LABEL         = "Label_ W.skp"
    MOMENT_CLIP        = 'PL_ MF Assembly Clip.skp'
    PL_COMPASS         = 'PlateCompass.skp'



    #########################
    # MEASUREMENT CONSTANTS #
    #########################
    RADIUS_RULE = 2
    # Standard label height
    LABEL_HEIGHT = 2


    ###########################
    ## WIDE FLANGE CONSTANTS ##
    ###########################
    #Sets the root radus for the beams
    RADIUS = 3
    #This sets the distance from the end of the beam the direction labels go
    LABELX = 10
    #Sets the distance from the ends of the beams that holes cannot be, in inches
    NO_HOLE_ZONE = 6
    #Sets the minimum beam length before the web holes do not stagger(Actual minimum is < 8)
    MINIMUM_BEAM_LENGTH = 16
    # This sets the stiffener location from each end of the beam
    STIFF_LOCATION = 0.5
    #Distance from the end of the beam the 13/14" holes are placed
    BIG_HOLES_LOCATION = 4
    # Minimum distance from the inside of the flanges to the center of 13/16" holes can be
    MIN_BIG_HOLE_DISTANCE_FROM_KZONE = 1.5
    SHEAR_HOLE_SPACING = 3
    WFINGROUPNAME = "Difference"
    UN_NAMED_GROUP = "[UnAssigned]"
    FLANGE_TYPE_COL = "Column"
    FLANGE_TYPE_BM = "Beam"


    ##################################
    ## WIDE FLANGE COLUMN CONSTANTS ##
    ##################################
    #Sets label distance from the bottom of the column
    LABEL_HEIGHT_FROM_FLOOR = 10
    #Sets tyhe distance from the top of the column to the stiffeners
    STIFFENER_DIST = 0

    ###################
    ## HSS CONSTANTS ##
    ###################

    # Most of these constants are not in use as the hss tools pulls the components from a library rather than draws them from scatch using these rules
    STANDARD_BASE_MARGIN = 3
    MINIMUM_WELD_OVERHANG = 0.25
    STANDARD_WELD_OVERHANG = 0.75
    HOLE_OFFSET = 1.5
    BASEPLATE_RADIUS = 0.5
    RADIUS_SEGMENT = 6
    # STANDARD_TOP_PLATE_SIZE = 5 #changed this from 5 12-30-2019 not sure if there are undesired issues or why i had ot on 5
    # STANDARD_TOP_PLATE_SIZE = 5 #changed from 4 to 0, to enable parametric drawing of all plates now that they're improved. 2/27/25
    STANDARD_TOP_PLATE_SIZE = 0
    MINIMUM_STUD_DIST_FROM_HSS_ENDS = 7.25
    HSS_BEAM_CAP_THICK = 0 # needs to be whatever the standard cap plates are
    BOTTOM_PLATE_CORNER_RADIUS = 0.5
    STANDARD_BASE_PLATE_THICKNESS = 0.75
    STANDARD_CAP_PLATE_THICKNESS = 0.5
    ONE_INCH_BASEPLATE = 1.0
    ETCH_LINE = 0.25
    HSSOUTGROUPNAME = UN_NAMED_GROUP
    HSSINGROUPNAME = "Difference"
    HSSBLANKCAP = "PL_ Blank Cap.skp"

    BASETYPES = ["Blank","SQ","OC","IL","IC","EX","DR","DL","DI"]
    BASETYPESSIX = ["Blank","SQ","C","IL"]


    # Normal steel colors for 3DS conventions and procedures
    STEEL_COLORS = {
       charcoal: {name: ' A Charcoal'     , rgba: [102, 102, 102, 255]},
       red:      {name: ' B Special Thick', rgba: [255, 50, 50, 255]},
       orange:   {name: ' C ¾" Thick'    , rgba: [255, 135, 50, 255], thck: 0.750},
       yellow:   {name: ' D ⅝" Thick'    , rgba: [255, 255, 50, 255], thck: 0.625},
       green:    {name: ' E ½" Thick'    , rgba: [50, 255, 50, 255], thck: 0.500},
       blue:     {name: ' F ⅜" Thick'    , rgba: [50, 118, 255, 255], thck: 0.375},
       indigo:   {name: ' G 5/16" Thick' , rgba: [118, 50, 255, 255], thck: 0.3125},
       purple:   {name: ' H ¼" Thick'    , rgba: [186, 50, 255, 255], thck: 0.250},
       grey:     {name: '1 Done'          , rgba: [153, 153, 153, 255]},
       layout:   {name: '2 Layed Out '    , rgba: [255, 127, 127, 255]},
       brokeout: {name: '3 Broken Out'    , rgba: [255, 180, 127, 255]},
       modeled:  {name: '4 Model Review'       , rgba: [255, 255, 127, 255]},
       j_master: {name: '5 Modeled'   , rgba: [127, 255, 127, 255]},
       j_knight: {name: '6 Placement Reviewed'   , rgba: [127, 169, 255, 255]},
       padawan:  {name: '7 Size Reviewed'       , rgba: [150, 127, 255, 255]},
       youngling: {name: '8 Cad Reviewed'     , rgba: [212, 127, 255, 255]},
       black:    {name: 'Black'           , rgba: [0, 0, 0, 255]},
       cener:    {name: 'Center'          , rgba: [122, 255, 188, 255]},
       flag:     {name: 'Flag'            , rgba: [255, 25, 113, 255]}
    }
  end
end