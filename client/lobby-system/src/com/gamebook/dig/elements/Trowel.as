package com.gamebook.dig.elements {
	import flash.display.MovieClip;
	
	/**
	 * ...
	 * @author Jobe Makar - jobe@electrotank.com
	 */
	[Embed(source='../../../../assets/dig.swf', symbol='Trowel')]
	public class Trowel extends MovieClip{
		
		private var _digging:Boolean;
		
		private var _targetX:Number;
		private var _targetY:Number;
		
		public function Trowel() {
			stop();
			_targetX = 0;
			_targetY = 0;
		}
		
		public function run():void {
			var k:Number = .15;
			var xm:Number = (_targetX - x) * k;
			var ym:Number = (_targetY - y) * k;
			x += xm;
			y += ym;
		}
		
		public function moveTo(tx:Number, ty:Number):void {
			_targetX = tx;
			_targetY = ty;
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