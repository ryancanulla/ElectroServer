package com.gamebook.syncexample.guy {
	import com.gamebook.utils.network.movement.Converger;
	import com.gamebook.utils.NumberUtil;
	import flash.display.MovieClip;
	
	/**
	 * ...
	 * @author Jobe Makar - jobe@electrotank.com
	 */
	[Embed(source='../../../../assets/assets.swf', symbol='Guy')]
	public class Guy extends MovieClip{
		
		private var _playerName:String;
		private var _isMe:Boolean;
		
		private var _endx:Number;
		private var _endy:Number;
		
		private var _angleWalking:Number;
		
		//declare stage variables in the character
		public var ani0_mc:MovieClip;
		public var ani1_mc:MovieClip;
		public var ani2_mc:MovieClip;
		public var ani3_mc:MovieClip;
		public var ani4_mc:MovieClip;
		public var ani5_mc:MovieClip;
		public var ani6_mc:MovieClip;
		public var ani7_mc:MovieClip;
		
		private var ani_mc:MovieClip;
		
		
		public function Guy() {
			_isMe = false;
			_endx = 0;
			_endy = 0;
			
			//turn off all 8 rotations and stop them from animating
			for (var i:int = 0; i < 8;++i) {
				var ani:MovieClip = this["ani" + i.toString() + "_mc"];
				ani.visible = false;
				ani.stop();
			}
			
			//turn on 1 direction so we can see it
			ani_mc = ani0_mc;
			ani_mc.visible = true;
		}
		
		public function run():void {
			if (!isMe) {
				
				//linear
				if (_endx != x || _endy != y) {
					
					//angle character is walking
					var ang:Number = Math.atan2(_endy - y, _endx - x);
					
					//frame-based speed
					var speed:Number = 3;
					
					//distance to travel in the x and y directions based on the angle
					var xs:Number = speed*Math.cos(ang);
					var ys:Number = speed*Math.sin(ang);
					
					//where the character will be after this frame
					var tx:Number = x + xs;
					var ty:Number = y + ys;
					
					//determine if we past the target
					var xdir1:Number = (_endx - x) / Math.abs(_endx - x);
					var xdir2:Number = (_endx - tx) / Math.abs(_endx - tx);
					var ydir1:Number = (_endy - y) / Math.abs(_endy - y);
					var ydir2:Number = (_endy - ty) / Math.abs(_endy - ty);
					
					//check to seee if you diveded by zero above
					if (isNaN(xdir1) || isNaN(xdir2)) {
						xdir1 = 0;
						xdir2 = 0;
					}
					
					//check to seee if you diveded by zero above
					if (isNaN(ydir1) || isNaN(ydir2)) {
						ydir1 = 0;
						ydir2 = 0;
					}
					
					//if the normalized directions don't match, then you've just stepped past the target position
					if (xdir1 != xdir2 || ydir1 != ydir2) {
						tx = _endx;
						ty = _endy;
					}
					
					//update position
					x = tx;
					y = ty;
					
					
				}
				
			}
			
			//show the right character angle and walk state
			showCharacterAngle();
			
			//if the charcter is me, then send the target position to the current position
			if (isMe) {
				_endx = x;
				_endy = y;
			}
		}
		
		/**
		 * Displays the correct angle and walk state for the character
		 */
		private function showCharacterAngle():void {
			var isWalking:Boolean = x != _endx || y != _endy;
			if (!isWalking) {
				ani_mc.stop();
			} else {
				var angle:Number = Math.atan2(_endy - y, _endx - x) * 180 / Math.PI;
				if (isMe) {
					angle = _angleWalking;
				}
				var rotationIndex:int = NumberUtil.findAngleIndex(angle, 45);
				var ani:MovieClip = this["ani" + rotationIndex.toString() + "_mc"];
				if (ani != ani_mc) {
					ani_mc.visible = false;
					ani_mc.stop();
					
					ani_mc = ani;
					ani_mc.visible = true;
				}
				ani_mc.play();
			}
		}
		
		public function walkTo(endx:Number, endy:Number):void {
			_endx = endx;
			_endy = endy;
		}
		
		public function get playerName():String { return _playerName; }
		
		public function set playerName(value:String):void {
			_playerName = value;
		}
		
		public function get isMe():Boolean { return _isMe; }
		
		public function set isMe(value:Boolean):void {
			_isMe = value;
		}
		
		public function set angleWalking(value:Number):void {
			_angleWalking = value;
		}
		
	}
	
}