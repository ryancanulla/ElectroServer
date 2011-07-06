package com.gamebook.digging;

public class Grid {

    boolean[] cellTakenYet;
    int cellWidth;
    int cellHeight;
    
    public Grid() {
        cellTakenYet = new boolean [PluginConstants.NUM_ROWS * PluginConstants.NUM_COLS];
        cellWidth = PluginConstants.BOARD_WIDTH / PluginConstants.NUM_COLS;
        cellHeight = PluginConstants.BOARD_HEIGHT / PluginConstants.NUM_ROWS;
    }
    
    public boolean tryToTakeCell(int x, int y) {
        int row = getRow(x, y);
        int col = getCol(x, y);
        int cell = row * PluginConstants.NUM_COLS + col;
        if (cell < 0 || cell >= cellTakenYet.length) {
            return false;
        } else if (cellTakenYet[cell]) {
            return false;
        } else {
            cellTakenYet[cell] = true;
            return true;
        }
    }
    
    public int getRow(int x, int y) {
        return y / cellHeight;
    }

    public int getCol(int x, int y) {
        return x / cellWidth;
    }
}
