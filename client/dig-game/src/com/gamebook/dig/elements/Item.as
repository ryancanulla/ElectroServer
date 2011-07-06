package com.gamebook.dig.elements {
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.filters.BlurFilter;
	import flash.filters.DropShadowFilter;
	
	/**
	 * ...
	 * @author Jobe Makar - jobe@electrotank.com
	 */
	[Embed(source='../../../../assets/dig.swf', symbol='Item')]
	public class Item extends MovieClip {
		
		private var _itemType:int;
		private var _scaleMov:Number;
		
		public function Item() {
			stop();
			
			scaleX = scaleY = .25;
			_scaleMov = 0;
			addEventListener(Event.ENTER_FRAME, enterFrame);
			
			filters = [new DropShadowFilter()];
		}
		
		private function enterFrame(e:Event):void {
			var k:Number = .25;
			var decay:Number = .8;
			_scaleMov *= decay;
			_scaleMov += (1 - scaleX) * k;
			
			scaleX = scaleY = scaleX + _scaleMov;
		}
		
		public function set itemType(value:int):void {
			_itemType = value;
			gotoAndStop(_itemType + 1);
		}
	}
	
}