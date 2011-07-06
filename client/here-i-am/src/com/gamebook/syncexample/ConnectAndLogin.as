package com.gamebook.syncexample
{
    //ElectroServer imports
    import com.electrotank.electroserver5.ElectroServer;
    import com.electrotank.electroserver5.api.ConnectionResponse;
    import com.electrotank.electroserver5.api.LoginRequest;
    import com.electrotank.electroserver5.api.LoginResponse;
    import com.electrotank.electroserver5.api.MessageType;

    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.utils.getTimer;

    /**
     * ...
     * @author Jobe Makar - jobe@electrotank.com
     */
    public class ConnectAndLogin extends MovieClip
    {

        private var _es:ElectroServer;

        public function ConnectAndLogin() {
            initialize();
        }

        private function test():void {

            //create the class that contains the fun stuff
            var he:HereIAmExample = new HereIAmExample();
            he.es = _es;
            he.initialize();
            addChild(he);

        }

        private function initialize():void {
            //create a new ElectroServer instance
            _es = new ElectroServer();
            _es.loadAndConnect("settings.xml");

            //add event listeners
            _es.engine.addEventListener(MessageType.ConnectionResponse.name, onConnectionEvent);
            _es.engine.addEventListener(MessageType.LoginResponse.name, onLoginResponse);

        }

        public function onConnectionEvent(e:ConnectionResponse):void {
            if (e.successful) {
                //build the request
                var lr:LoginRequest = new LoginRequest();
                lr.userName = "player" + Math.round(1000 * Math.random());

                //send it
                _es.engine.send(lr);
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

                test();

            }
            else {
                trace("Error logging in");
            }
        }

    }

}
