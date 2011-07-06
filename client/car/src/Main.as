package
{
    import com.gamebook.syncexample.SyncExample;

    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;

    public class Main extends Sprite
    {
        public function Main() {

            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;

            var se:SyncExample = new SyncExample();
            addChild(se);
        }
    }
}
