package
{
    import com.gamebook.syncexample.ConnectAndLogin;

    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;

    /**
     * ...
     * @author Jobe Makar - jobe@electrotank.com
     */
    public class Main extends Sprite
    {

        public function Main():void {

            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;

            var conn:ConnectAndLogin = new ConnectAndLogin();
            addChild(conn);
        }

    }

}
