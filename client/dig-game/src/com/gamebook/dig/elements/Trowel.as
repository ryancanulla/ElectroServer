package com.gamebook.dig.elements {
	import flash.display.MovieClip;
	
	/**
	 * ...
	 * @author Jobe Makar - jobe@electrotank.com
	 */
	[Embed(source='../../../../assets/dig.swf', symbol='Trowel')]
	public class Trowel extends MovieClip{
		
		private var _digging:Boolean;
		
		public function Trowel() {
			stop();
		}
		
		public function dig():void {
			gotoAndStop(2);
			_digging = true;
		}
		
		public function stopDigging():void {
			gotoAndStop(1);
			_digging = false;
		}
		
		public function get digging():Boolean { return _digging; }
		
	}
	
}