package game 
{
	import flash.geom.Point;
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Spritemap;
	import net.flashpunk.utils.Draw;
	
	public class Projectile 
	{
		private static const OFFSCREEN:uint = 25;
		private static const MINDAMAGE:uint = 3;
		private static const WALLHITRADIUS:uint = 8;
		private static const DARKENAMOUNT:Number = 0.6;
		
		//stats
		private var damage:uint;
		public var position:Point;
		private var direction:Point;
		public var dead:Boolean;
		public var dying:Boolean;
		private var player:Boolean;
		private var pierceList:Array;
		private var bombTimer:Number;
		private var bombPoof:Array;
		
		private static const BOMBFLASHRATE:Number = 0.12;
		private static const BOMBBOOMLENGTH:Number = 0.035;
		private static const NUMPOOFS:uint = 250;
		private static const POOFSPEED:Number = 35;
		private static const POOFLIFE:Number = 0.55;
		
		//appearance
		private var proj:uint;
		
		
		public function Projectile(dam:uint, p:uint, pos:Point, dir:Point, pl:Boolean) 
		{
			damage = dam;
			proj = p;
			position = pos;
			dead = false;
			player = pl;
			pierceList = new Array();
			bombTimer = 1;
			bombPoof = null;
			dying = false;
			
			if (!isBomb)
			{
				var angle:Number = Math.atan2(dir.y, dir.x);
				var aimVar:Number = Main.data.projectiles[proj][3] * 0.01;
				angle += Math.PI * (2 - aimVar + 2 * aimVar * Math.random());
				direction = Point.polar(1, angle);
			}
			else
			{
				playSound(11);
				direction = new Point(1, 0);
			}
		}
		
		private function get isBomb():Boolean { return proj == 0; }
		
		private function checkHitOne(cr:Creature):Boolean
		{
			if (!cr.vulnerable)
				return false;
			var dis:Number = (new Point(position.x - cr.position.x, position.y - cr.position.y)).length;
			if (dis < hitRadius)
			{
				//check pierce list
				for (var i:uint = 0; i < pierceList.length; i++)
					if (pierceList[i] == cr)
						return false; //they're on the pierce list, so you can't hit them
				
				playSound(8);
				cr.takeHit(damage, direction);
				
				damage *= pierceAmount;
				if (damage <= MINDAMAGE)
					dead = true;
				else
					pierceList.push(cr);
				return true;
			}
			return false;
		}
		
		private function checkHit():Boolean
		{
			if (player)
			{
				var creatures:Array = (FP.world as Level).getCreaturesAround(position);
				for (var i:uint = 0; i < creatures.length; i++)
					if (creatures[i] != (FP.world as Level).player && checkHitOne(creatures[i]))
						return true;
			}
			else if (checkHitOne((FP.world as Level).player))
				return true;
			return false;
		}
		
		private function get piece():uint { return Main.data.projectiles[proj][5]; }
		private function get pierceAmount():Number { return Main.data.projectiles[proj][4] * 0.01; }
		private function get hitRadius():uint { return Main.data.projectiles[proj][2]; }
		private function get projWallCollide():Boolean
		{
			var ftT:Array = Main.data.features[Main.data.pieces[piece][1]];
			return (FP.world as Level).collideWall(new Point(
													position.x,
													position.y),
													WALLHITRADIUS) &&
					(FP.world as Level).collideWall(new Point(
													position.x,
													position.y + ftT[5] - ftT[3]),
													WALLHITRADIUS);
		}
		
		public function update():void
		{
			if (isBomb)
			{
				if (!bombPoof)
				{
					bombTimer -= FP.elapsed * Player.BOMBFUSESPEED;
					if (bombBoom)
						dying = true;
					if (bombTimer <= 0)
					{
						playSound(12);
						
						var crs:Array = (FP.world as Level).getCreaturesAround(position);
						for (var i:uint = 0; i < crs.length; i++)
						{
							var cr:Creature = crs[i];
							var dif:Point = new Point(cr.position.x - position.x, cr.position.y - position.y);
							if (dif.length <= Player.BOMBAOE + cr.raceMaskSize)
								cr.takeHit(damage, dif);
						}
						bombPoof = new Array();
						bombTimer = POOFLIFE;
						for (i = 0; i < NUMPOOFS; i++)
						{
							var pP:Point = Point.polar(Math.random() * Player.BOMBAOE, Math.random() * 2 * Math.PI);
							pP.x += position.x;
							pP.y += position.y;
							bombPoof.push(pP);
						}
					}
				}
				else
				{
					bombTimer -= FP.elapsed;
					if (bombTimer <= 0)
						dead = true;
				}
				return;
			}
			
			var spd:Number = FP.elapsed * Main.data.projectiles[proj][1];
			
			var step:Point = new Point(direction.x, direction.y);
			var steps:uint = Math.ceil(spd);
			step.normalize(spd / steps);
			
			for (i = 0; i < steps; i++)
			{
				if (projWallCollide)
					dead = true;
				
				if (!dead)
					checkHit();
				
				if (dead)
					return;
				
				position.x += step.x;
				position.y += step.y;
			}
			
			if (position.x < FP.camera.x - OFFSCREEN || position.y < FP.camera.y - OFFSCREEN ||
				position.x > FP.camera.x + FP.width + OFFSCREEN ||
				position.y > FP.camera.y + FP.height + OFFSCREEN)
					dead = true;
		}
		
		private function playSound(id:uint):void
		{
			var soundPack:uint = Main.data.projectiles[proj][id];
			Main.playSound(soundPack);
		}
		
		private function get bombFlash():Boolean
		{
			if (!isBomb)
				return false;
				
			var prop:Number = Math.sqrt(bombTimer);
			prop /= BOMBFLASHRATE;
			prop -= Math.floor(prop);
			return prop > 0.5;
		}
		
		private function get bombBoom():Boolean
		{
			return isBomb && bombTimer <= BOMBBOOMLENGTH;
		}
		
		public function render():void
		{
			if (bombPoof)
			{
				var pSpr:Spritemap = Main.data.spriteSheets[Main.data.projectiles[0][8]];
				pSpr.scaleX = Creature.POOFSCALEEND * (POOFLIFE - bombTimer) / POOFLIFE + bombTimer / POOFLIFE;
				pSpr.scaleY = pSpr.scaleX;
				pSpr.angle = 0;
				pSpr.frame = Main.data.projectiles[0][9];
				pSpr.color = Main.data.projectiles[0][10];
				for (var i:uint = 0; i < bombPoof.length; i++)
				{
					var pP:Point = bombPoof[i];
					pSpr.render(FP.buffer, new Point(pP.x, pP.y - POOFSPEED * (POOFLIFE - bombTimer)), FP.camera);
				}
				return;
			}
			
			var angle:Number = Math.atan2(direction.y, direction.x) * 180 / Math.PI;
			
			var c:uint = Main.data.projectiles[proj][6];
			if (bombFlash)
				c = 0xFFFFFF;
			if (player && (FP.world as Level).projDarken)
				c = FP.colorLerp(c, 0, DARKENAMOUNT);
			Creature.drawFeature(position, piece, c, 0, 0, false, false, angle); // direction.x < 0, Math.abs(angle) > 90, angle);
			
			if (bombBoom)
				Draw.circlePlus(position.x, position.y, Player.BOMBAOE);
		}
	}

}