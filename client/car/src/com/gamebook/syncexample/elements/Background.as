package com.gamebook.syncexample.elements {
	import flash.display.MovieClip;
	
	/**
	 * ...
	 * @author Jobe Makar - jobe@electrotank.com
	 */
	[Embed(source='../../../../assets/assets.swf', symbol='Background')]
	public class Background extends MovieClip{
		
		public function Background() {
			this.cacheAsBitmap = true;
		}
		
	}
	
}