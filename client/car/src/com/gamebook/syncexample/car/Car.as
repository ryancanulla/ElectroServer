package com.gamebook.syncexample.car
{
    import com.gamebook.utils.network.movement.Converger;
    import com.gamebook.utils.NumberUtil;
    import flash.display.MovieClip;

    /**
     * ...
     * @author Jobe Makar - jobe@electrotank.com
     */
    [Embed(source='../../../../assets/assets.swf', symbol='Car')]
    public class Car extends MovieClip
    {

        private var _playerName:String;
        private var _isMe:Boolean;
        private var _converger:Converger;

        public function Car() {
            _isMe = false;
            _converger = new Converger();
            _converger.interceptTimeMultiplier = 7;
            _converger.maxDurationInterceptTime = 2000;

            stop();

            scaleX = scaleY = .75;
        }

        public function run():void {
            trace("run");
            _converger.run();

            x = _converger.view.x;
            y = _converger.view.y;

            var rotationIndex:int = NumberUtil.findAngleIndex(_converger.view.angle, 10);
            gotoAndStop(rotationIndex + 1);

        }

        public function get playerName():String {
            return _playerName;
        }

        public function set playerName(value:String):void {
            _playerName = value;
        }

        public function get isMe():Boolean {
            return _isMe;
        }

        public function set isMe(value:Boolean):void {
            _isMe = value;
        }

        public function get converger():Converger {
            return _converger;
        }

    }

}
