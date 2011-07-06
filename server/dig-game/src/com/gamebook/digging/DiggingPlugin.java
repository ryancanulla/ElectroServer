
package com.gamebook.digging;

import com.electrotank.electroserver5.extensions.BasePlugin;
import com.electrotank.electroserver5.extensions.ChainAction;
import com.electrotank.electroserver5.extensions.api.ScheduledCallback;
import com.electrotank.electroserver5.extensions.api.value.EsObject;
import com.electrotank.electroserver5.extensions.api.value.EsObjectRO;
import com.electrotank.electroserver5.extensions.api.value.UserEnterContext;
import java.util.AbstractMap;
import java.util.AbstractQueue;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;


public class DiggingPlugin extends BasePlugin {
    // variables
    private AbstractMap<String, PlayerInfo> playerInfoMap;
    private AbstractQueue<PlayerInfo> delayQueue;
    private Grid grid;
    
    @Override
    public void init( EsObjectRO ignored ) {
        grid = new Grid();
        playerInfoMap = new ConcurrentHashMap<String, PlayerInfo>();
        delayQueue = new ConcurrentLinkedQueue<PlayerInfo>();
    }

    @Override
    public ChainAction userEnter(UserEnterContext context) {
        String playerName = context.getUserName();
        getApi().getLogger().debug("userEnter: " + playerName);
        return ChainAction.OkAndContinue;
    }

    @Override
    public void request(String playerName, EsObjectRO requestParameters) {
        EsObject messageIn = new EsObject();
        messageIn.addAll(requestParameters);
        getApi().getLogger().debug(playerName + " requests: " + messageIn.toString());
        String action = messageIn.getString(PluginConstants.ACTION);

        if (action.equals(PluginConstants.INIT_ME)) {
            handlePlayerInitRequest(playerName);
        } else if (action.equals(PluginConstants.DIG_HERE)) {
            handleDigHereRequest(playerName, messageIn);
        } else if (action.equals(PluginConstants.POSITION_UPDATE)) {
            relayMessage(playerName, messageIn);
        }
    }

    @Override
    public void userExit(String playerName) {
        if (playerInfoMap.containsKey(playerName)) {
            playerInfoMap.remove(playerName);
        }
        EsObject message = new EsObject();
        message.setString(PluginConstants.ACTION, PluginConstants.REMOVE_PLAYER);
        message.setString(PluginConstants.NAME, playerName);
        sendAndLog("userExit", message);
    }

    @Override
    public void destroy() {
        while (!delayQueue.isEmpty()) {
            PlayerInfo pInfo = delayQueue.poll();
            if (pInfo != null) {
                pInfo.cancelCallback(getApi());
            }
        }
        getApi().getLogger().debug("room destroyed");
    }

    private synchronized EsObject[] getFullPlayerList() {
        EsObject[] list = new EsObject[playerInfoMap.size()];
        int ptr = 0;
        for (PlayerInfo pInfo : playerInfoMap.values()) {
            list[ptr] = pInfo.toEsObject();
            ptr++;
        }
        return list;
    }

    private void handleDigHereRequest(String playerName, EsObject messageIn) {
        PlayerInfo pInfo = playerInfoMap.get(playerName);
        if (pInfo == null) {
            getApi().getLogger().debug("No user info found for " + playerName);
            return;
        } else if (pInfo.isDigging()) {
            sendErrorMessage(playerName, PluginConstants.ALREADY_DIGGING);
            return;
        } else {
            int x = messageIn.getInteger(PluginConstants.X);
            int y = messageIn.getInteger(PluginConstants.Y);
            getApi().getLogger().debug("row, col: " + grid.getRow(x, y) + ", " + 
                    grid.getCol(x, y));
            boolean okayToDigHere = grid.tryToTakeCell(x, y);
            if (okayToDigHere) {
                pInfo.startDigging(x, y);
                queueCallbackToFinishDigging(pInfo);
            } else {
                sendErrorMessage(playerName, PluginConstants.SPOT_ALREADY_DUG);
            }
        }
    }

    private void handleDiggingFinished(PlayerInfo pInfo) {
        String playerName = pInfo.getPlayerName();
        getApi().getLogger().debug("handleDiggingFinished: " + playerName);
        if (!playerInfoMap.containsKey(playerName)) {
            getApi().getLogger().debug(playerName + " already left the room");
            return;
        }

        EsObject obj = new EsObject();
        obj.setString(PluginConstants.ACTION, PluginConstants.DONE_DIGGING);
        obj.setString(PluginConstants.NAME, playerName);

        ItemType itemFound = ItemType.getRandomItemType();

        int score = pInfo.addToScore(itemFound.getPoints());
        boolean itemWasFound = itemFound.getPoints() != 0;

        obj.setInteger(PluginConstants.SCORE, score);
        obj.setBoolean(PluginConstants.ITEM_FOUND, itemWasFound);
        obj.setInteger(PluginConstants.ITEM_ID, itemFound.getItemTypeId());

        pInfo.stopDigging();
        sendAndLog("handleDiggingFinished", obj);
    }

    private synchronized void handlePlayerInitRequest(String playerName) {
        EsObject message2 = new EsObject();
        message2.setString(PluginConstants.ACTION, PluginConstants.ADD_PLAYER);
        message2.setString(PluginConstants.NAME, playerName);
        sendAndLog("addUser", message2);

        // add the new user to the user list
        playerInfoMap.put(playerName, new PlayerInfo(playerName));

        // send the user the full user list
        EsObject message = new EsObject();
        message.setString(PluginConstants.ACTION, PluginConstants.PLAYER_LIST);
        EsObject[] list = getFullPlayerList();
        message.setEsObjectArray(PluginConstants.PLAYER_LIST, list);
        getApi().sendPluginMessageToUser(playerName, message);
        getApi().getLogger().debug("Message sent to " + playerName + ": " + message.toString());
    }

    private void queueCallbackToFinishDigging(PlayerInfo pInfo) {
        String playerName = pInfo.getPlayerName();
        getApi().getLogger().debug("Delayed message for " + playerName + " queued.");
        if (delayQueue.add(pInfo)) {
            int callback = getApi().scheduleExecution(PluginConstants.DURATION_MS,
                    1,
                    new ScheduledCallback() {

                        public void scheduledCallback() {
                            tickQueue();
                        }
                    });
            pInfo.setCallBackId(callback);
        }
    }

    private void sendErrorMessage(String playerName, String error) {
        EsObject message = new EsObject();
        message.setString(PluginConstants.ACTION, PluginConstants.ERROR);
        message.setString(PluginConstants.ERROR, error);
        getApi().sendPluginMessageToUser(playerName, message);
        getApi().getLogger().debug("Message sent to " + playerName + ": " + message.toString());
    }

    private synchronized void tickQueue() {
        if (delayQueue.isEmpty()) {
            return;
        }
        try {
            PlayerInfo pInfo = delayQueue.poll();
            if (pInfo != null) {
                handleDiggingFinished(pInfo);
            }
        } catch (Exception exception) {
            getApi().getLogger().error("Exception while running tickQueue", exception);
        }
    }

    private void relayMessage(String playerName, EsObject messageIn) {
        messageIn.setString(PluginConstants.NAME, playerName);
        sendAndLog("relayMessage", messageIn);
    }

    private void sendAndLog(String fromMethod, EsObject message) {
        List<String> initializedPlayers = new ArrayList<String>();
        for (PlayerInfo pInfo : playerInfoMap.values()) {
            initializedPlayers.add(pInfo.getPlayerName());
        }

        if (initializedPlayers.size() < 1) {
            return;     // nobody to send the message to
        }

        getApi().sendPluginMessageToUsers(initializedPlayers, message);
        getApi().getLogger().debug(fromMethod + ": " + message.toString());
    }
}
