package com.gamebook.syncexample
{

    import com.electrotank.electroserver5.ElectroServer;
    import com.electrotank.electroserver5.api.CreateRoomRequest;
    import com.electrotank.electroserver5.api.EsObject;
    import com.electrotank.electroserver5.api.JoinRoomEvent;
    import com.electrotank.electroserver5.api.MessageType;
    import com.electrotank.electroserver5.api.PublicMessageEvent;
    import com.electrotank.electroserver5.api.PublicMessageRequest;
    import com.electrotank.electroserver5.api.UserListEntry;
    import com.electrotank.electroserver5.api.UserUpdateAction;
    import com.electrotank.electroserver5.api.UserUpdateEvent;
    import com.electrotank.electroserver5.zone.Room;
    import com.gamebook.syncexample.guy.Guy;
    import com.gamebook.utils.keymanager.Key;
    import com.gamebook.utils.keymanager.KeyCombo;
    import com.gamebook.utils.keymanager.KeyManager;

    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;

    /**
     * ...
     * @author Jobe Makar - jobe@electrotank.com
     */
    public class HereIAmExample extends MovieClip
    {

        private var _es:ElectroServer;
        private var _room:Room;

        private var _keyManager:KeyManager;
        private var _left:KeyCombo;
        private var _right:KeyCombo;
        private var _up:KeyCombo;
        private var _down:KeyCombo;

        private var _guys:Array;
        private var _guysByName:Dictionary;
        private var _myGuy:Guy;

        private var _lastTimeSent:int;

        public function HereIAmExample() {
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }

        private function onAddedToStage(e:Event):void {
            _keyManager = new KeyManager();
            stage.addChild(_keyManager);

            _left = _keyManager.createKeyCombo(Key.LEFT);
            _right = _keyManager.createKeyCombo(Key.RIGHT);
            _up = _keyManager.createKeyCombo(Key.UP);
            _down = _keyManager.createKeyCombo(Key.DOWN);
        }

        public function initialize():void {

            //initialize an array and dictionary for convenient Guy look ups
            _guys = [];
            _guysByName = new Dictionary();

            //initialize this time variable
            _lastTimeSent = 0;

            //add frame event listener for updating character positions
            addEventListener(Event.ENTER_FRAME, enterFrame);

            //add ElectroServer listeners
            _es.engine.addEventListener(MessageType.JoinRoomEvent.name, onJoinRoomEvent);
            _es.engine.addEventListener(MessageType.PublicMessageEvent.name, onPublicMessageEvent);
            _es.engine.addEventListener(MessageType.UserUpdateEvent.name, onUserListUpdateEvent);

            //join a room
            var crr:CreateRoomRequest = new CreateRoomRequest();
            crr.roomName = "HereIAm";
            crr.zoneName"HereIAm";
            _es.engine.send(crr);

        }

        /**
         * Handle walk events. In a real game this would end up being handled through a plugin message rather than a public message
         */
        public function onPublicMessageEvent(e:PublicMessageEvent):void {
            var esob:EsObject = e.esObject;
            var action:String = esob.getString(PluginConstants.ACTION);

            switch (action) {
                case PluginConstants.UPDATE_POSITION:
                    handleUpdatePosition(esob);
                    break;
            }
        }

        /**
         * Handles the update position action. Updates the target position of another Guy
         */
        private function handleUpdatePosition(esob:EsObject):void {
            var name:String = esob.getString(PluginConstants.NAME);
            var x:int = esob.getInteger(PluginConstants.X);
            var y:int = esob.getInteger(PluginConstants.Y);

            //if the message is from you, lets reset the name to 'my_mirror' so we can see how other people see you
            if (name == _myGuy.playerName) {
                name = "my_mirror";
            }

            var guy:Guy = _guysByName[name];

            if (guy == null) {
                guy = new Guy();
                guy.playerName = name;
                guy.x = x;
                guy.y = y;
                addGuy(guy);

                //if it is your mirror, then fade it out 50% so you can tell which one it is
                if (name == "my_mirror") {
                    guy.alpha = .5;
                }
            }

            if (!guy.isMe) {
                guy.walkTo(x, y);
            }
        }

        /**
         * In this particular example, only use the user list event to remove Guys
         */
        public function onUserListUpdateEvent(e:UserUpdateEvent):void {

            if (e.action == UserUpdateAction.DeleteUser) {
                var guy:Guy = _guysByName[e.userName];
                removeChild(guy);

                _guysByName[guy.playerName] = null;

                for (var i:int = 0; i < _guys.length; ++i) {
                    if (_guys[i] == guy) {
                        _guys.splice(i, 1);
                        break;
                    }
                }
            }
        }

        private function enterFrame(e:Event):void {
            if (_myGuy != null) {
                checkKeys();
                moveGuys();

                //send a position update every 500ms
                if (getTimer() - _lastTimeSent > 500) {
                    sendUpdate();
                }
            }
        }

        /**
         * Update guy positions
         */
        private function moveGuys():void {
            for (var i:int = 0; i < _guys.length; ++i) {
                var guy:Guy = _guys[i];
                guy.run();
            }
        }

        private function sendUpdate():void {
            //format the EsObject to send
            var esob:EsObject = new EsObject();
            esob.setString(PluginConstants.ACTION, PluginConstants.UPDATE_POSITION);
            esob.setInteger(PluginConstants.X, _myGuy.x);
            esob.setInteger(PluginConstants.Y, _myGuy.y);
            esob.setString(PluginConstants.NAME, _myGuy.playerName);

            //send the EsObject via the PublicMessageRequest
            var pmr:PublicMessageRequest = new PublicMessageRequest();
            pmr.roomId = _room.id;
            pmr.zoneId = _room.zoneId;
            pmr.message = "";
            pmr.esObject = esob;

            _es.engine.send(pmr);
        }

        private function checkKeys():void {
            var sp:Number = 3;
            var xs:Number = _left.getComboActivated() ? -sp : (_right.getComboActivated() ? sp : 0);
            var ys:Number = _up.getComboActivated() ? -sp : (_down.getComboActivated() ? sp : 0);

            var ang:Number = Math.atan2(ys, xs) * 180 / Math.PI;

            if (ys != 0 || xs != 0) {
                _myGuy.angleWalking = ang;
                _myGuy.x += sp * Math.cos(ang * Math.PI / 180);
                _myGuy.y += sp * Math.sin(ang * Math.PI / 180);

            }

        }

        public function onJoinRoomEvent(e:JoinRoomEvent):void {
            _room = _es.managerHelper.zoneManager.zoneById(e.zoneId).roomById(e.roomId);

            var guy:Guy = new Guy();
            guy.x = 200;
            guy.y = 200;
            guy.playerName = _es.managerHelper.userManager.me.userName;
            _myGuy = guy;
            addGuy(guy);
        }

        private function addGuy(guy:Guy):void {
            _guys.push(guy);
            _guysByName[guy.playerName] = guy;
            guy.isMe = _es.managerHelper.userManager.me.userName == guy.playerName;
            addChild(guy);
        }

        public function set es(value:ElectroServer):void {
            _es = value;
        }

    }

}
