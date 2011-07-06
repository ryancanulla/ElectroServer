package
{
    import com.gamebook.dig.GameFlow;

    import flash.display.Sprite;

    public class Main extends Sprite
    {
        public function Main() {
            var gameFlow:GameFlow = new GameFlow();
            addChild(gameFlow);
        }
    }
}
