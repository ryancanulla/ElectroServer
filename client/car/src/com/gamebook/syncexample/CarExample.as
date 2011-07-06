package com.gamebook.syncexample
{
    import com.electrotank.electroserver5.ElectroServer;
    import com.electrotank.electroserver5.api.CreateRoomRequest;
    import com.electrotank.electroserver5.api.EsObject;
    import com.electrotank.electroserver5.api.JoinRoomEvent;
    import com.electrotank.electroserver5.api.MessageType;
    import com.electrotank.electroserver5.api.PublicMessageEvent;
    import com.electrotank.electroserver5.api.PublicMessageRequest;
    import com.electrotank.electroserver5.api.UserUpdateAction;
    import com.electrotank.electroserver5.api.UserUpdateEvent;
    import com.electrotank.electroserver5.user.User;
    import com.electrotank.electroserver5.zone.Room;
    import com.gamebook.syncexample.car.Car;
    import com.gamebook.syncexample.elements.Background;
    import com.gamebook.syncexample.elements.LampPost;
    import com.gamebook.utils.network.clock.Clock;
    import com.gamebook.utils.network.movement.Heading;

    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.utils.Dictionary;

    /**
     * ...
     * @author Jobe Makar - jobe@electrotank.com
     */
    public class CarExample extends MovieClip
    {

        private var _es:ElectroServer;
        private var _clock:Clock;
        private var _room:Room;

        private var _cars:Array;
        private var _carsByName:Dictionary;
        private var _lastTimeSent:Number;

        private var _myCar:Car;
        private var _okToSend:Boolean;

        private var _sortableItems:Array;
        private var _background:Background;

        private var _maxSpeed:Number;

        public function CarExample() {
        }

        public function initialize():void {
            _okToSend = false;

            _sortableItems = [];

            addEventListener(Event.ENTER_FRAME, enterFrame);

            _es.engine.addEventListener(MessageType.JoinRoomEvent.name, onJoinRoomEvent);
            _es.engine.addEventListener(MessageType.PublicMessageEvent.name, onPublicMessageEvent);
            _es.engine.addEventListener(MessageType.UserUpdateEvent.name, onUserListUpdateEvent);

            var crr:CreateRoomRequest = new CreateRoomRequest();
            crr.roomName = "Car";
            crr.zoneName = "Car";
            _es.engine.send(crr);

            _cars = [];
            _carsByName = new Dictionary();

            _lastTimeSent = -1;

            _maxSpeed = .18;

            var lp:LampPost = new LampPost();
            lp.x = 300;
            lp.y = 300;
            addChild(lp);
            _sortableItems.push(lp);

            _background = new Background();
            addChild(_background);

        }

        private function enterFrame(e:Event):void {
            updateHeading();

            moveCars();

            if (_clock.time - _lastTimeSent > 250 && _myCar != null && !_myCar.converger.course.isAccelerating) {
                sendUpdate();
            }

            sortItems();
        }

        private function sortItems():void {
            _sortableItems.sort(compare);

            var startInd:int = getChildIndex(_background) + 1;

            for (var i:int = 0; i < _sortableItems.length; ++i) {
                var dis:DisplayObject = _sortableItems[i];
                addChildAt(dis, startInd + i);
            }
        }

        private function compare(a:DisplayObject, b:DisplayObject):Number {
            return a.y > b.y ? 1 : (a.y == b.y ? 0 : -1);
        }

        private function moveCars():void {
            for (var i:int = 0; i < _cars.length; ++i) {
                var car:Car = _cars[i];
                car.run();
            }
        }

        private function updateHeading():void {
            if (_okToSend && !_myCar.converger.course.isAccelerating) {
                checkMousePosition();

                var ang_rad:Number = Math.atan2(mouseY - _myCar.y, mouseX - _myCar.x);
                var ang:Number = ang_rad * 180 / Math.PI;

                _myCar.run();
                var course:Heading = _myCar.converger.course;

                if (course.speed > 0) {
                    course.angle = ang;
                    course.x = _myCar.x;
                    course.y = _myCar.y;
                    course.time = _clock.time;
                }
            }

        }

        private function checkMousePosition():void {
            if (!_myCar.converger.course.isAccelerating) {
                var dis:Number = Math.sqrt(Math.pow(_myCar.y - mouseY, 2) + Math.pow(_myCar.x - mouseX, 2));

                if (dis < 50 && _myCar.converger.course.speed > 0) {
                    decel();
                }
                else if (dis > 75 && _myCar.converger.course.speed == 0) {
                    var ang_rad:Number = Math.atan2(mouseY - _myCar.y, mouseX - _myCar.x);
                    var ang:Number = ang_rad * 180 / Math.PI;
                    _myCar.converger.course.angle = ang;
                    accel();
                }
            }
        }

        private function decel():void {
            _myCar.converger.course.time = _clock.time;
            _myCar.converger.course.endSpeed = 0;
            _myCar.converger.course.accelTime = 500;
            _myCar.converger.course.accel = (_myCar.converger.course.endSpeed - _myCar.converger.course.speed) / _myCar.converger.course.accelTime;

            sendUpdate();
        }

        private function accel():void {
            trace("accel");
            _myCar.converger.course.time = _clock.time;
            _myCar.converger.course.speed = 0;
            _myCar.converger.course.endSpeed = _maxSpeed;
            _myCar.converger.course.accelTime = 500;
            _myCar.converger.course.accel = (_myCar.converger.course.endSpeed - _myCar.converger.course.speed) / _myCar.converger.course.accelTime;

            sendUpdate();
        }

        private function sendUpdate():void {
            if (_myCar != null && _okToSend && _myCar.converger.course.time > _lastTimeSent) {
                _lastTimeSent = _myCar.converger.course.time;

                var esob:EsObject = new EsObject();
                esob.setString(PluginConstants.ACTION, PluginConstants.UPDATE_HEADING);

                var heading:EsObject = formatHeading(_myCar.converger.course);

                esob.setEsObject(PluginConstants.HEADING, heading);

                var pmr:PublicMessageRequest = new PublicMessageRequest();
                pmr.esObject = esob;
                pmr.message = "";
                pmr.roomId = _room.id;
                pmr.zoneId = _room.zoneId;

                _es.engine.send(pmr);
            }
        }

        private function formatHeading(heading:Heading):EsObject {
            var esob:EsObject = new EsObject();

            esob.setNumber(PluginConstants.X, heading.x);
            esob.setNumber(PluginConstants.Y, heading.y);
            esob.setNumber(PluginConstants.SPEED, heading.speed);
            esob.setNumber(PluginConstants.ANGLE, heading.angle);
            esob.setNumber(PluginConstants.TIME, heading.time);
            esob.setNumber(PluginConstants.ACCEL_TIME, heading.accelTime);
            esob.setNumber(PluginConstants.END_SPEED, heading.endSpeed);
            esob.setString(PluginConstants.NAME, _myCar.playerName);

            return esob;
        }

        public function onPublicMessageEvent(e:PublicMessageEvent):void {
            var esob:EsObject = e.esObject;
            var action:String = esob.getString(PluginConstants.ACTION);

            switch (action) {
                case PluginConstants.UPDATE_HEADING:
                    handleUpdateHeading(esob);
                    break;
            }
        }

        private function handleUpdateHeading(esob:EsObject):void {
            var ob:EsObject = esob.getEsObject(PluginConstants.HEADING);
            var name:String = ob.getString(PluginConstants.NAME);
            var x:Number = ob.getNumber(PluginConstants.X);
            var y:Number = ob.getNumber(PluginConstants.Y);
            var angle:Number = ob.getNumber(PluginConstants.ANGLE);
            var time:Number = ob.getNumber(PluginConstants.TIME);
            var speed:Number = ob.getNumber(PluginConstants.SPEED);
            var accelTime:Number = ob.getNumber(PluginConstants.ACCEL_TIME);
            var endSpeed:Number = ob.getNumber(PluginConstants.END_SPEED);

            if (name == _myCar.playerName) {
                name = "my_mirror";
            }

            var car:Car = _carsByName[name];

            if (car == null) {
                car = new Car();
                car.playerName = name;
                car.converger.course.x = x;
                car.converger.course.y = y;
                addCar(car);
            }

            if (!car.isMe) {

                var path:Heading = new Heading();
                path.x = x;
                path.y = y;
                path.speed = speed;
                path.time = time;
                path.angle = angle;
                path.accelTime = accelTime;
                path.endSpeed = endSpeed;

                car.converger.intercept(path);

                if (name == "my_mirror") {
                    car.alpha = .5;
                }
            }

        }

        /**
         * In this particular example, only use the user list event to remove Guys
         */
        public function onUserListUpdateEvent(e:UserUpdateEvent):void {
            if (e.action == UserUpdateAction.DeleteUser) {
                var car:Car = _carsByName[e.userName];

                if (car != null) {
                    removeChild(car);

                    _carsByName[car.playerName] = null;

                    for (var i:int = 0; i < _cars.length; ++i) {
                        if (_cars[i] == car) {
                            _cars.splice(i, 1);
                            break;
                        }
                    }

                    for (i = 0; i < _sortableItems.length; ++i) {
                        if (_sortableItems[i] == car) {
                            _sortableItems.splice(i, 1);
                            break;
                        }
                    }
                }
            }
        }

        public function onJoinRoomEvent(e:JoinRoomEvent):void {
            _room = _es.managerHelper.zoneManager.zoneById(e.zoneId).roomById(e.roomId);

            _okToSend = true;

            var car:Car = new Car();
            car.playerName = _es.managerHelper.userManager.me.userName;

            _myCar = car;
            _myCar.converger.course.x = 100;
            _myCar.converger.course.y = 200;
            _myCar.converger.course.speed = 0;

            _myCar.converger.debug = true;

            addCar(car);

        }

        private function addCar(car:Car):void {
            _cars.push(car);
            _carsByName[car.playerName] = car;

            car.converger.clock = _clock;

            car.isMe = car.playerName == _es.managerHelper.userManager.me.userName;

            car.run();

            addChild(car);

            _sortableItems.push(car);

            sortItems();
        }

        public function set clock(value:Clock):void {
            _clock = value;
        }

        public function set es(value:ElectroServer):void {
            _es = value;
        }

    }

}
