package com.gamebook.dig
{
    import com.electrotank.electroserver5.ElectroServer;
    import com.electrotank.electroserver5.api.CreateRoomRequest;
    import com.electrotank.electroserver5.api.EsObject;
    import com.electrotank.electroserver5.api.JoinRoomEvent;
    import com.electrotank.electroserver5.api.MessageType;
    import com.electrotank.electroserver5.api.PluginListEntry;
    import com.electrotank.electroserver5.api.PluginMessageEvent;
    import com.electrotank.electroserver5.api.PluginRequest;
    import com.electrotank.electroserver5.zone.Room;
    import com.gamebook.dig.elements.Background;
    import com.gamebook.dig.elements.Item;
    import com.gamebook.dig.elements.Trowel;
    import com.gamebook.dig.player.Player;
    import com.gamebook.dig.player.PlayerManager;

    import fl.controls.List;
    import fl.data.DataProvider;

    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.media.Sound;
    import flash.ui.Mouse;

    /**
     * ...
     * @author Jobe Makar - jobe@electrotank.com
     */
    public class DigGame extends MovieClip
    {

        private var _es:ElectroServer;
        private var _room:Room;
        private var _playerManager:PlayerManager;
        private var _playerListUI:List;

        private var _itemsHolder:MovieClip;
        private var _trowel:Trowel;

        private var _myUsername:String;

        [Embed(source='../../../assets/dig.swf', symbol='DigSound')]
        private var DIG_SOUND:Class;

        [Embed(source='../../../assets/dig.swf', symbol='FoundSound')]
        private var FOUND_SOUND:Class;

        [Embed(source='../../../assets/dig.swf', symbol='NothingSound')]
        private var NOTHING_SOUND:Class;

        public function DigGame() {
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }

        private function onAddedToStage(e:Event):void {
            stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoved);
        }

        public function initialize():void {

            //add a background
            var bg:Background = new Background();
            addChild(bg);

            //add the player list UI
            _playerListUI = new List();
            _playerListUI.x = 490;
            _playerListUI.y = 10;
            _playerListUI.width = 640 - _playerListUI.x - 10;
            addChild(_playerListUI);

            //create a container for items that are added
            _itemsHolder = new MovieClip();
            addChild(_itemsHolder);

            //add mouse follower
            _trowel = new Trowel();
            addChild(_trowel);

            //hide the mouse
            Mouse.hide();

            //add some listeners
            _es.engine.addEventListener(MessageType.JoinRoomEvent.name, onJoinRoomEvent);
            _es.engine.addEventListener(MessageType.PluginMessageEvent.name, onPluginMessageEvent);

            _myUsername = _es.managerHelper.userManager.me.userName;

            _playerManager = new PlayerManager();

            //join a room to play the game
            joinRoom();
        }

        private function playSound(snd:Sound):void {
            snd.play();
        }

        /**
         * Called when you successfully join a room
         */
        public function onJoinRoomEvent(e:JoinRoomEvent):void {
            //store a reference to your room
            _room = _es.managerHelper.zoneManager.zoneById(e.zoneId).roomById(e.roomId);

            //tell the plugin that you're ready
            var esob:EsObject = new EsObject();
            esob.setString(PluginConstants.ACTION, PluginConstants.INIT_ME);

            //send to the plugin
            sendToPlugin(esob);
        }

        /**
         * Sends formatted EsObjects to the DigGame plugin
         */
        private function sendToPlugin(esob:EsObject):void {
            //build the request
            var pr:PluginRequest = new PluginRequest();
// is this correct?
            pr.parameters = esob;
            pr.roomId = _room.id;
            pr.zoneId = _room.zoneId;
            pr.pluginName = "DiggingPlugin";

            //send it
            _es.engine.send(pr);
            trace(esob);
        }

        /**
         * Called when a message is received from a plugin
         */
        public function onPluginMessageEvent(e:PluginMessageEvent):void {
//	is this correct?
            var esob:EsObject = e.parameters;

            //get the action which determines what we do next
            var action:String = esob.getString(PluginConstants.ACTION);
            trace(esob);

            switch (action) {
                case PluginConstants.DONE_DIGGING:
                    handleDoneDigging(esob);
                    break;
                case PluginConstants.PLAYER_LIST:
                    handlePlayerList(esob);
                    break;
                case PluginConstants.ADD_PLAYER:
                    handleAddPlayer(esob);
                    break;
                case PluginConstants.REMOVE_PLAYER:
                    handleRemovePlayer(esob);
                    break;
                case PluginConstants.ERROR:
                    handleError(esob);
                    break;
                default:
                    trace("Action not handled: " + action);
            }
        }

        private function mouseMoved(e:MouseEvent):void {
            updateTrowelPosition();
        }

        private function updateTrowelPosition():void {
            if (!_trowel.digging) {
                _trowel.x = mouseX;
                _trowel.y = mouseY;
            }
        }

        private function mouseDown(e:MouseEvent):void {
            if (!_trowel.digging && _room != null) {
                //tell the plugin you want to dig here
                var esob:EsObject = new EsObject();
                esob.setString(PluginConstants.ACTION, PluginConstants.DIG_HERE);
                esob.setInteger(PluginConstants.X, mouseX);
                esob.setInteger(PluginConstants.Y, mouseY);

                //send
                sendToPlugin(esob);

                //animate
                _trowel.dig();
                playSound(new DIG_SOUND());
            }
        }

        private function refreshPlayerList():void {
            var dp:DataProvider = new DataProvider();

            for (var i:int = 0; i < _playerManager.players.length; ++i) {
                var p:Player = _playerManager.players[i];
                dp.addItem({ label: p.name + ", score: " + p.score.toString(), data: p });
            }

            _playerListUI.dataProvider = dp;
        }

        /**
         * Parse the player list
         */
        private function handlePlayerList(esob:EsObject):void {
            var players:Array = esob.getEsObjectArray(PluginConstants.PLAYER_LIST);

            for (var i:int = 0; i < players.length; ++i) {
                var player_esob:EsObject = players[i];

                var p:Player = new Player();
                p.name = player_esob.getString(PluginConstants.NAME);
                p.score = player_esob.getInteger(PluginConstants.SCORE);
                p.isMe = p.name == _myUsername;

                _playerManager.addPlayer(p);
            }
            refreshPlayerList();
        }

        /**
         * Remove a player
         */
        private function handleRemovePlayer(esob:EsObject):void {
            var name:String = esob.getString(PluginConstants.NAME);
            _playerManager.removePlayer(name);
            refreshPlayerList();
        }

        /**
         * Add a player
         */
        private function handleAddPlayer(esob:EsObject):void {
            var p:Player = new Player();
            p.name = esob.getString(PluginConstants.NAME);
            p.score = 0;
            p.isMe = p.name == _myUsername;

            _playerManager.addPlayer(p);

            refreshPlayerList();
        }

        /**
         * Called when the server tells the client something went wrong
         */
        private function handleError(esob:EsObject):void {
            var error:String = esob.getString(PluginConstants.ERROR);

            switch (error) {
                case PluginConstants.SPOT_ALREADY_DUG:
                    _trowel.stopDigging();
                    playSound(new NOTHING_SOUND());
                    updateTrowelPosition();
                    break;
                default:
                    trace("Error not handled: " + error);
            }
        }

        /**
         * Called when the server tells the client someone has finished digging
         */
        private function handleDoneDigging(esob:EsObject):void {
            //grab some initial information off of the EsObject
            var name:String = esob.getString(PluginConstants.NAME);
            var score:int = esob.getInteger(PluginConstants.SCORE);

            //find the player and update the score property
            var player:Player = _playerManager.playerByName(name);
            player.score = score;

            //if this player is me, then process the EsObject further
            if (player.isMe) {
                //stop the digging animation
                _trowel.stopDigging();

                //If true an item was found
                var found:Boolean = esob.getBoolean(PluginConstants.ITEM_FOUND);

                if (found) {
                    //get the id that says which of the 4 item types was found
                    var itemId:int = esob.getInteger(PluginConstants.ITEM_ID);

                    //create item, set its type, position it, and add to screen
                    var item:Item = new Item();
                    item.itemType = itemId;
                    item.x = _trowel.x;
                    item.y = _trowel.y;
                    _itemsHolder.addChild(item);

                    //play a positive sound since you found an item
                    playSound(new FOUND_SOUND());
                }
                else {
                    //play a negative sound since you found nothing
                    playSound(new NOTHING_SOUND());
                }

                //move trowel to wherever the mouse now is
                updateTrowelPosition();
            }

            //rebuild the player list to show updated scores
            refreshPlayerList();
        }

        /**
         * Create a room with the DigGamePlugin plugin
         */
        private function joinRoom():void {
            //create the request
            var crr:CreateRoomRequest = new CreateRoomRequest();
            crr.roomName = "Dig Game Room";
            crr.zoneName = "Dig Game Zone";

            //create the plugin
            var pl:PluginListEntry = new PluginListEntry();
            pl.extensionName = "GameBook";
            pl.pluginHandle = "DiggingPlugin";
            pl.pluginName = "DiggingPlugin";

            //add to the list of plugins to create

            crr.plugins = [pl];

            //send it
            _es.engine.send(crr);
			trace("room request sent");
        }

        public function set es(value:ElectroServer):void {
            _es = value;
        }

    }

}
