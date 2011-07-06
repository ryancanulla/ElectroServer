package {
	import com.electrotank.electroserver5.ElectroServer;
	import com.electrotank.electroserver5.api.ConnectionResponse;
	import com.electrotank.electroserver5.api.LoginRequest;
	import com.electrotank.electroserver5.api.LoginResponse;
	import com.electrotank.electroserver5.api.MessageType;
	import com.electrotank.electroserver5.api.PrivateMessageEvent;
	import com.electrotank.electroserver5.api.PrivateMessageRequest;
	import com.electrotank.electroserver5.util.ES5TraceAdapter;
	import com.electrotank.logging.adapter.ILogger;
	import com.electrotank.logging.adapter.Log;

	import flash.display.Sprite;
	import flash.text.TextField;

	public class Main extends Sprite {

		//add this so we can see the logs get traced
		Log.setLogAdapter(new ES5TraceAdapter());

		//create a new ElectroSerserver instance to gain access to the API
		private var _es:ElectroServer = new ElectroServer();
		private var _log:TextField = new TextField();

		public function Main():void {
			createChildren();
			//load settings file and connect
			_es.loadAndConnect("settings.xml");
			log("Connecting... \n");

			//listen to key events to know when a connection has succeeded (or failed), and when login has succeeded (or failed)
			_es.engine.addEventListener(MessageType.ConnectionResponse.name, onConnectionResponse);
			_es.engine.addEventListener(MessageType.LoginResponse.name, onLoginResponse);
			_es.engine.addEventListener(MessageType.PrivateMessageEvent.name, onPrivateMessageEvent);
		}

		private function createChildren():void {
			_log.width = 400;
			_log.height = 300;
			_log.x = 25;
			_log.y = 25;
			_log.border = true;
			addChild(_log);
		}

		private function onConnectionResponse(e:ConnectionResponse):void {
			if (e.successful) {
				log("Connected! \n");

				//connection succeeded, so login
				var lr:LoginRequest = new LoginRequest();
				lr.userName = "CelticsFan" + Math.round(1000 * Math.random()).toString();

				// send login request
				_es.engine.send(lr);
				log("Logging in... \n");
			}
			else {
				log("Connection error: " + e.error + "\n");
			}
		}

		private function onLoginResponse(e:LoginResponse):void {
			log("Logged in! \n");
			if(e.successful) {
				var privateMessage:PrivateMessageRequest = new PrivateMessageRequest();
				privateMessage.userNames = [e.userName];
				privateMessage.message = "Want to play a game?";

				_es.engine.send(privateMessage);
				log("Sending myself a private message.\n");
			}
			else {
				log("Login error: " + e.error + "\n");
			}
		}

		private function onPrivateMessageEvent(e:PrivateMessageEvent):void {
			log("Private message from " + e.userName + " : " + e.message + "\n");
		}

		private function log(e:String):void {
			_log.appendText(e);
		}

	}

}
