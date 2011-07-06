package com.gamebook.dig
{
    //ElectroServer imports

    //Flash imports
    import com.electrotank.electroserver5.ElectroServer;
    import com.electrotank.electroserver5.api.ConnectionClosedEvent;
    import com.electrotank.electroserver5.api.ConnectionResponse;
    import com.electrotank.electroserver5.api.LoginRequest;
    import com.electrotank.electroserver5.api.LoginResponse;
    import com.electrotank.electroserver5.api.MessageType;
    import com.electrotank.electroserver5.events.ConnectionEvent;

    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.net.URLLoader;
    import flash.net.URLRequest;

    /**
     * ...
     * @author Jobe Makar - jobe@electrotank.com
     */
    public class GameFlow extends MovieClip
    {

        private var _es:ElectroServer;
        private var _digGame:DigGame;

        public function GameFlow() {
            initialize();
        }

        private function initialize():void {
            //create a new ElectroServer instance
            _es = new ElectroServer();
            _es.loadAndConnect("settings.xml");

            //add event listeners
            _es.engine.addEventListener(MessageType.ConnectionResponse.name, onConnectionEvent);
            _es.engine.addEventListener(MessageType.LoginResponse.name, onLoginResponse);
            _es.engine.addEventListener(MessageType.ConnectionClosedEvent.name, onConnectionClosedEvent);
        }

        /**
         * Called when a connection has been established or fails
         */
        public function onConnectionEvent(e:ConnectionResponse):void {
            if (e.successful) {
                //build the request
                var lr:LoginRequest = new LoginRequest();
                lr.userName = "player" + Math.round(1000 * Math.random());

                //send it
                _es.engine.send(lr);
				trace("Logging In");
            }
            else {
                trace("Error connecting to the server");
            }
        }

        /**
         * Called when the server responds to a login request.
         */
        public function onLoginResponse(e:LoginResponse):void {
            if (e.successful) {
				trace("logged in");
                //create the DigGame and add it to the screen
                _digGame = new DigGame();
                _digGame.es = _es;
                _digGame.initialize();
                addChild(_digGame);

            }
            else {
                trace("Error logging in");
            }
        }

        /**
         * This is called when the connection closes
         */
        public function onConnectionClosedEvent(e:ConnectionClosedEvent):void {
            trace("Connection closed.");
        }

    }

}
