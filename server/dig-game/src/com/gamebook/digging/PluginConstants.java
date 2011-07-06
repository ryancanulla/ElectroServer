package com.gamebook.digging;

public class PluginConstants {

    // actions 
    public static final String ACTION          = "a";
    public static final String ADD_PLAYER      = "au";
    public static final String DIG_HERE        = "d";
    public static final String DONE_DIGGING    = "dd";
    public static final String ERROR           = "err";
    public static final String INIT_ME         = "i";
    public static final String POSITION_UPDATE = "pu";
    public static final String REMOVE_PLAYER   = "ru";
    public static final String PLAYER_LIST     = "ul";
    
    // parameters
    public static final String ITEM_FOUND      = "f";
    public static final String ITEM_ID         = "id";
    public static final String NAME            = "n";
    public static final String SCORE           = "s";
    public static final String X               = "x";
    public static final String Y               = "y";    
    
    // error messages
    public static final String ALREADY_DIGGING  = "AlreadyDigging";
    public static final String SPOT_ALREADY_DUG = "SpotAlreadyDug";
    
    // other constants
    public static final int DURATION_MS        = 2000;   // 2 seconds
    public static final int BOARD_WIDTH        = 640;
    public static final int BOARD_HEIGHT       = 480;
    public static final int NUM_ROWS           = 12;
    public static final int NUM_COLS           = 16;
}
