package
{
	import com.gamebook.chatroom.ChatFlow;

	import flash.display.Sprite;

	[SWF(width="800", height="600", frameRate="30", backgroundColor="0xFFFFFF")]
	public class Main extends Sprite
	{
		public function Main() {
			//create the chat flow
			var chatFlow:ChatFlow = new ChatFlow();
			chatFlow.x = 20;
			chatFlow.y = 20;
			addChild(chatFlow);

		}
	}
}