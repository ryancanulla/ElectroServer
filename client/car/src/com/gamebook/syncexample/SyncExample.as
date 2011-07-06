package com.gamebook.syncexample
{
    //ElectroServer imports

    import com.electrotank.electroserver5.ElectroServer;
    import com.electrotank.electroserver5.api.ConnectionResponse;
    import com.electrotank.electroserver5.api.LoginRequest;
    import com.electrotank.electroserver5.api.LoginResponse;
    import com.electrotank.electroserver5.api.MessageType;
    import com.gamebook.utils.network.clock.Clock;

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
    public class SyncExample extends MovieClip
    {

        private var _es:ElectroServer;

        public function SyncExample() {
            trace("initialize");
            initialize();
        }

        private function initClock():void {

            var ts:Clock = new Clock(_es, "TimeStampPlugin");
            ts.start();

            ts.addEventListener(Clock.CLOCK_READY, onClockReady);

        }

        private function onClockReady(e:Event):void {
            var sc:Clock = e.target as Clock;

            var ce:CarExample = new CarExample();
            ce.es = _es;
            ce.clock = sc;
            ce.initialize();

            addChild(ce);
        }

        private function initialize():void {
            //create a new ElectroServer instance
            _es = new ElectroServer();

            //add event listeners
            _es.engine.addEventListener(MessageType.ConnectionResponse.name, onConnectionEvent);
            _es.engine.addEventListener(MessageType.LoginResponse.name, onLoginResponse);

            _es.loadAndConnect("settings.xml");
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

                initClock();

            }
            else {
                trace("Error logging in");
            }
        }

    }

}
