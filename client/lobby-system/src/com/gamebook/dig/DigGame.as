package com.gamebook.dig {
	import com.electrotank.electroserver5.ElectroServer;
	import com.electrotank.electroserver5.api.EsObject;
	import com.electrotank.electroserver5.api.PluginMessageEvent;
	import com.electrotank.electroserver5.api.MessageType;
	import com.electrotank.electroserver5.api.LeaveRoomRequest;
	import com.electrotank.electroserver5.api.PluginRequest;
	import com.electrotank.electroserver5.zone.Room;
	import com.gamebook.dig.elements.Background;
	import com.gamebook.dig.elements.Item;
	import com.gamebook.dig.elements.Trowel;
	import com.gamebook.dig.player.Player;
	import com.gamebook.dig.player.PlayerManager;
	import fl.controls.Button;
	import fl.controls.List;
	import fl.controls.UIScrollBar;
	import fl.data.DataProvider;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.media.Sound;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.ui.Mouse;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	
	/**
	 * ...
	 * @author Jobe Makar - jobe@electrotank.com
	 */
	public class DigGame extends MovieClip {
		
		public static const BACK_TO_LOBBY:String = "backToLobby";
		
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
		
		private var _countdownField:TextField;
		private var _countdownTimer:Timer;
		private var _secondsLeft:int;
		private var _gameStarted:Boolean;
		
		private var _lastTimeSent:int;
		
		private var _okToSendMousePosition:Boolean;
		
		private var _waitingField:TextField;
		
		public function DigGame() {
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		private function onAddedToStage(e:Event):void {
			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoved);
		}
		
		public function initialize():void {
			
			_gameStarted = false;
			
			_lastTimeSent = -1;
			
			_okToSendMousePosition = true;
			
			addEventListener(Event.ENTER_FRAME, run);
			
			//add a background
			var bg:Background = new Background();
			addChild(bg);
			
			//add the player list UI
			_playerListUI = new List();
			_playerListUI.x = 650;
			_playerListUI.y = 10;
			_playerListUI.width = 800 - _playerListUI.x - 10;
			addChild(_playerListUI);
			
			//create a container for items that are added
			_itemsHolder = new MovieClip();
			addChild(_itemsHolder);
			
			//add mouse follower
			_trowel = new Trowel();
			addChild(_trowel);
			
			//hide the mouse
			Mouse.hide();
			
			_es.engine.addEventListener(MessageType.PluginMessageEvent.name, onPluginMessageEvent);
			
			_myUsername = _es.managerHelper.userManager.me.userName;
			
			_playerManager = new PlayerManager();
			
			createWaitingField();
			
			sendInitializeMe();
		}
		
		private function createWaitingField():void {
			var tf:TextFormat = new TextFormat();
			tf.size = 30;
			tf.bold = true;
			tf.font = "Arial";
			tf.color = 0xFFFFFF;
			
			var field:TextField = new TextField();
			field.x = 320;
			field.y = 150;
			field.autoSize = TextFieldAutoSize.CENTER;
			field.defaultTextFormat = tf;
			
			field.text = "Waiting for players...";
			
			_waitingField = field;
			
			addChild(field);
		}
		
		private function run(e:Event):void {
			if (getTimer()-_lastTimeSent > 500 && _okToSendMousePosition) {
				sendMousePosition();
			}
			
			for (var i:int = 0; i < _playerManager.players.length;++i) {
				var p:Player = _playerManager.players[i];
				if (!p.isMe) {
					p.trowel.run();
				}
			}
		}
		
		private function sendMousePosition():void{
			_lastTimeSent = getTimer();
			
			var esob:EsObject = new EsObject();
			esob.setString(PluginConstants.ACTION, PluginConstants.POSITION_UPDATE);
			esob.setInteger(PluginConstants.X, _trowel.x);
			esob.setInteger(PluginConstants.Y, _trowel.y);
			
			sendToPlugin(esob);
		}
		
		private function playSound(snd:Sound):void {
			snd.play();
		}
		
		private function sendInitializeMe():void {
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
			pr.parameters = esob;
			pr.roomId = _room.id;
			pr.zoneId = _room.zoneId;
			pr.pluginName = PluginConstants.PLUGIN_NAME;
			
			//send it
			_es.engine.send(pr);
		}
		
		/**
		 * Called when a message is received from a plugin
		 */
		public function onPluginMessageEvent(e:PluginMessageEvent):void {
			var esob:EsObject = e.parameters;
			
			//get the action which determines what we do next
			var action:String = esob.getString(PluginConstants.ACTION);
			switch (action) {
				case PluginConstants.POSITION_UPDATE:
					handlePositionUpdate(esob);
					break;
				case PluginConstants.DONE_DIGGING:
					handleDoneDigging(esob);
					break;
				case PluginConstants.DIG_HERE:
					handleDigHere(esob);
					break;
				case PluginConstants.PLAYER_LIST:
					handlePlayerList(esob);
					break;
				case PluginConstants.START_COUNTDOWN:
					handleStartCountdown(esob);
					break;
				case PluginConstants.STOP_COUNTDOWN:
					handleStopCountdown(esob);
					break;
				case PluginConstants.START_GAME:
					handleStartGame(esob);
					break;
				case PluginConstants.GAME_OVER:
					handleGameOver(esob);
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
		
		private function handleDigHere(esob:EsObject):void{
			var name:String = esob.getString(PluginConstants.NAME);
			var player:Player = _playerManager.playerByName(name);
			if (!player.isMe) {
				player.trowel.dig();
			}
		}
		
		private function handlePositionUpdate(esob:EsObject):void{
			var name:String = esob.getString(PluginConstants.NAME);
			var tx:int = esob.getInteger(PluginConstants.X);
			var ty:int = esob.getInteger(PluginConstants.Y);
			
			var player:Player = _playerManager.playerByName(name);
			if (!player.isMe) {
				player.trowel.moveTo(tx, ty);
			}
		}
		
		private function handleGameOver(esob:EsObject):void {
			_gameStarted = false;
			_okToSendMousePosition = false;
			
			var str:String = "Game Over \n";
			
			var list:Array = esob.getEsObjectArray(PluginConstants.PLAYER_LIST);
			for (var i:int = 0; i < list.length;++i) {
				var ob:EsObject = list[i];
				var name:String = ob.getString(PluginConstants.NAME);
				var score:int = ob.getInteger(PluginConstants.SCORE);
				str += name + " - " + score.toString()+"\n";
			}
			
			
			var tf:TextFormat = new TextFormat();
			tf.size = 30;
			tf.bold = true;
			tf.font = "Arial";
			tf.color = 0xFFFFFF;
			
			var field:TextField = new TextField();
			field.x = 320;
			field.y = 150;
			field.autoSize = TextFieldAutoSize.CENTER;
			
			addChild(field);
			
			
			field.defaultTextFormat = tf;
			field.text = str;
			
			field.filters = [new GlowFilter(0x009900), new DropShadowFilter()];
			
			var lobby:Button = new Button();
			lobby.label = "Back to Lobby";
			lobby.width = 150;
			lobby.x = 300;
			lobby.y = 540;
			lobby.addEventListener(MouseEvent.CLICK, onLobbyClick);
			addChild(lobby);
			
		}
		
		private function onLobbyClick(e:MouseEvent):void {
			dispatchEvent(new Event(BACK_TO_LOBBY));
		}
		
		public function destroy():void {
			//- new format is _es.engine.addEventListener(MessageType.LoginResponse.name, onLoginResponse);
			_es.engine.addEventListener(MessageType.PluginMessageEvent.name, onPluginMessageEvent);
			//
			Mouse.show();
			
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoved);
			
			var lrr:LeaveRoomRequest = new LeaveRoomRequest();
			lrr.roomId = _room.id;
			lrr.zoneId = _room.zoneId;
			
			_es.engine.send(lrr);
		}
		
		private function handleStartGame(esob:EsObject):void{
			_gameStarted = true;
		}
		
		private function handleStopCountdown(esob:EsObject):void {
			if (_countdownTimer != null ) {
				_countdownTimer.stop();
				_countdownTimer.removeEventListener(TimerEvent.TIMER, onCountdownTimer);
				_countdownTimer = null;
				
				removeChild(_countdownField);
				_countdownField = null;
				
				if (_playerManager.players.length == 1) {
					createWaitingField();
				}
			}
		}
		
		private function handleStartCountdown(esob:EsObject):void {
			if (_waitingField != null) {
				removeChild(_waitingField);
				_waitingField = null;
			}
			
			_secondsLeft = esob.getInteger(PluginConstants.COUNTDOWN_LEFT);
			trace("secondsLeft: " + _secondsLeft.toString());
			
			_countdownField = new TextField();
			addChild(_countdownField);
			
			_countdownField.x = 320;
			_countdownField.y = 200;
			_countdownField.selectable = false;
			
			_countdownField.autoSize = TextFieldAutoSize.CENTER;
			
			var tf:TextFormat = new TextFormat();
			tf.size = 80;
			tf.bold = true;
			tf.font = "Arial";
			tf.color = 0xFFFFFF;
			
			
			_countdownField.defaultTextFormat = tf;
			_countdownField.text = _secondsLeft.toString();
			
			_countdownField.filters = [new GlowFilter(0x009900), new DropShadowFilter()];
			
			_countdownTimer = new Timer(1000);
			_countdownTimer.start();
			_countdownTimer.addEventListener(TimerEvent.TIMER, onCountdownTimer);
			
		}
		
		private function onCountdownTimer(e:TimerEvent):void {
			--_secondsLeft;
			_countdownField.text = _secondsLeft.toString();
		}
		
		private function mouseMoved(e:MouseEvent):void {
			updateTrowelPosition();
		}
		
		private function updateTrowelPosition():void{
			if (!_trowel.digging) {
				_trowel.x = mouseX;
				_trowel.y = mouseY;
			}
		}
		
		private function mouseDown(e:MouseEvent):void {
			if (_gameStarted && !_trowel.digging && _room != null) {
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
			
			for (var i:int = 0; i < _playerManager.players.length;++i) {
				var p:Player = _playerManager.players[i];
				dp.addItem( { label:p.name + ", score: " + p.score.toString(), data:p } );
			}
			
			_playerListUI.dataProvider = dp;
		}
		
		/**
		 * Parse the player list
		 */
		private function handlePlayerList(esob:EsObject):void{
			var players:Array = esob.getEsObjectArray(PluginConstants.PLAYER_LIST);
			for (var i:int = 0; i < players.length;++i) {
				var player_esob:EsObject = players[i];
				
				var p:Player = new Player();
				p.name = player_esob.getString(PluginConstants.NAME);
				p.score = player_esob.getInteger(PluginConstants.SCORE);
				p.isMe = p.name == _myUsername;
				
				if (!p.isMe) {
					addChild(p.trowel);
				}
				
				_playerManager.addPlayer(p);
			}
			refreshPlayerList();
		}
		
		/**
		 * Remove a player
		 */
		private function handleRemovePlayer(esob:EsObject):void{
			var name:String = esob.getString(PluginConstants.NAME);
			var player:Player = _playerManager.playerByName(name);
			if (!player.isMe) {
				removeChild(player.trowel);
			}
			_playerManager.removePlayer(name);
			refreshPlayerList();
		}
		
		/**
		 * Add a player
		 */
		private function handleAddPlayer(esob:EsObject):void{
			var p:Player = new Player();
			p.name  = esob.getString(PluginConstants.NAME);
			p.score = 0;
			p.isMe = p.name == _myUsername;
			if (!p.isMe) {
				addChild(p.trowel);
			}
			
			_playerManager.addPlayer(p);
			
			refreshPlayerList();
		}
		
		/**
		 * Called when the server tells the client something went wrong
		 */
		private function handleError(esob:EsObject):void{
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
			
			player.trowel.stopDigging();
			
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
				} else {
					//play a negative sound since you found nothing
					playSound(new NOTHING_SOUND());
				}
				
				//move trowel to wherever the mouse now is
				updateTrowelPosition();
			}
			
			//rebuild the player list to show updated scores
			refreshPlayerList();
		}
		
		public function set es(value:ElectroServer):void {
			_es = value;
		}
		
		public function set room(value:Room):void {
			_room = value;
		}
		
	}
	
}