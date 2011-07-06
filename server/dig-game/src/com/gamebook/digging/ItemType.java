package com.gamebook.digging;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;

public enum ItemType {

    //          id, points, probabilityCutoff
    NOTHING     (-1, 0, 0),
    CHEAP       (0, 100, .7),
    GOOD        (1, 500, .5),
    GREAT       (2, 2500, .25),
    RARE        (3, 30000, .1),;
    
    private final int itemTypeId;
    private final int points;
    private final double probabilityCutoff;
    private final static Random rnd = new Random();    
    
    // Contains a reference to call enums by id
    private static Map<Integer, ItemType> typeMap;

    private ItemType(int itemTypeId, int points, double probabilityCutoff) {
        this.itemTypeId = itemTypeId;
        this.points = points;
        this.probabilityCutoff = probabilityCutoff;
        registerEnum(this);
    }

    private static void registerEnum(ItemType type) {
        if (typeMap == null) {
            typeMap = new HashMap<Integer, ItemType>();
        }
        typeMap.put(type.itemTypeId, type);
    }

    public static ItemType findEnumById(Integer id) {
        return typeMap.get(id);
    }

    public static boolean isValidId(Integer id) {
        return typeMap.containsKey(id);
    }

    public int getPoints() {
        return points;
    }

    public int getItemTypeId() {
        return itemTypeId;
    }
    
    public static ItemType getRandomItemType() {
        double chance = rnd.nextDouble();
        if (chance < RARE.probabilityCutoff) {
            return RARE;
        } else if (chance < GREAT.probabilityCutoff) {
            return GREAT;
        } else if (chance < GOOD.probabilityCutoff) {
            return GOOD;
        } else if (chance < CHEAP.probabilityCutoff) {
            return CHEAP;
        } else {
            return NOTHING;
        }
    }
}
