package com.gamebook.chatroom {
	import com.electrotank.electroserver5.ElectroServer;
	import com.electrotank.electroserver5.api.ConnectionResponse;
	import com.electrotank.electroserver5.api.ErrorType;
	import com.electrotank.electroserver5.api.LoginRequest;
	import com.electrotank.electroserver5.api.LoginResponse;
	import com.electrotank.electroserver5.api.MessageType;
	import com.electrotank.electroserver5.events.ConnectionEvent;
	import com.gamebook.chatroom.ui.ErrorScreen;
	import com.gamebook.chatroom.ui.LoginScreen;

	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	/**
	 * ...
	 * @author Jobe Makar - jobe@electrotank.com
	 */
	public class ChatFlow extends MovieClip{

		private var _es:ElectroServer;
		private var _chatRoom:ChatRoom;

		public function ChatFlow() {
			initialize();
		}

		private function initialize():void {
			//create a new ElectroServer instance
			_es = new ElectroServer();
			_es.loadAndConnect("settings.xml");

			//add event listeners
			_es.engine.addEventListener(MessageType.ConnectionResponse.name, onConnectionEvent);
			_es.engine.addEventListener(MessageType.LoginResponse.name, onLoginResponse);
			_es.engine.addEventListener(MessageType.ConnectionClosedEvent.name, onConnectionClosed);
		}


		/**
		 * Called when a user is connected and logged in. It creates a chat room screen.
		 */
		private function createChatRoom():void{
			_chatRoom = new ChatRoom();
			_chatRoom.es = _es;
			_chatRoom.initialize();
			addChild(_chatRoom);
		}

		/**
		 * This is used to display an error if one occurs
		 */
		private function showError(msg:String):void {
			var alert:ErrorScreen = new ErrorScreen(msg);
			alert.x = 300;
			alert.y = 200;
			alert.addEventListener(ErrorScreen.OK, onErrorScreenOk);
			addChild(alert);
		}

		/**
		 * Called as the result of an OK event on an error screen. Removes the error screen.
		 */
		private function onErrorScreenOk(e:Event):void {
			var alert:ErrorScreen = e.target as ErrorScreen;
			alert.removeEventListener(ErrorScreen.OK, onErrorScreenOk);
			removeChild(alert);
		}

		/**
		 * Called when a connection attempt has succeeded or failed
		 */
		public function onConnectionEvent(e:ConnectionResponse):void {
			if (e.successful) {
				createLoginScreen();
			} else {
				showError("Failed to connect.");
			}
		}

		/**
		 * Creates a screen where a user can enter a username
		 */
		private function createLoginScreen():void{
			var login:LoginScreen = new LoginScreen();
			login.x = 400 - login.width / 2;
			login.y = 300 - login.height / 2;
			addChild(login);

			login.addEventListener(LoginScreen.OK, onLoginSubmit);
		}

		/**
		 * Called as a result of the OK event on the login screen. Creates and sends a login request to the server
		 */
		private function onLoginSubmit(e:Event):void {
			var screen:LoginScreen = e.target as LoginScreen;

			//create the request
			var lr:LoginRequest = new LoginRequest();
			lr.userName = screen.username;

			//send it
			_es.engine.send(lr);

			screen.removeEventListener(LoginScreen.OK, onLoginSubmit);
			removeChild(screen);
		}

		/**
		 * Called when the server responds to the login request. If successful, create the chat room screen
		 */
		public function onLoginResponse(e:LoginResponse):void {
			if (e.successful) {
				createChatRoom();
			} else {
				showError(e.error.name);
			}
		}

		public function onConnectionClosed(e:ConnectionEvent):void {
			showError("Connection was closed");
		}

	}

}