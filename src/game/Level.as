package game 
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.flashpunk.graphics.Spritemap;
	import net.flashpunk.World;
	import net.flashpunk.FP;
	
	public class Level extends World
	{
		private var dyingCreatures:Array;
		private var dyingProjectiles:Array;
		private var creatures:Array;
		private var pl:Player;
		private var projectiles:Array;
		private var items:Array;
		private var width:uint;
		private var height:uint;
		private var creatureBuckets:Array;
		private var tiles:Array;
		private var roomDifficulties:Array;
		private var lengthSetting:uint;
		private var difficulty:uint;
		private var kills:uint;
		private var lastPR:uint;
		private var switchTime:Number;
		public var crime:uint;
		
		//visual constants
		private static const WALLHEIGHT:uint = 40;
		private static const SWITCHSPEED:Number = 1.75;
		//code constants
		public static const ROOMWIDTH:uint = TILESIZE * 18;
		public static const ROOMHEIGHT:uint = TILESIZE * 12;
		private static const BUCKETSCHECKRADIUS:uint = 3;
		private static const BUCKETSIZE:uint = 50;
		public static const TILESIZE:uint = 50;
		
		//progression
		private static const ITEMWHEELSIZE:uint = 13;
		private static const MINROOMFACTOR:Number = 2.5;
		private static const SIDEROOMCHANCE:Number = 0.6;
		private static const SIDEROOMCHANCEDEGRADE:Number = 0.75;
		private static const NUMNPCROOMS:uint = 12;
		private static const COVERTRIES:uint = 1200;
		private static const SUPEREARLYLENGTH:uint = 3;
		
		public function loadLevel(loadFrom:Array, iOn:uint):uint
		{
			//load settings
			width = loadFrom[iOn++];
			height = loadFrom[iOn++];
			lengthSetting = loadFrom[iOn++];
			difficulty = loadFrom[iOn++];
			kills = loadFrom[iOn++];
			lastPR = loadFrom[iOn++];
			crime = loadFrom[iOn++];
			
			//load tiles and related
			tiles = new Array();
			for (var i:uint = 0; i < tWidth * tHeight; i++)
				tiles.push(loadFrom[iOn++]);
			roomDifficulties = new Array();
			for (i = 0; i < rWidth * rHeight; i++)
				roomDifficulties.push(loadFrom[iOn++]);
			
			//load items
			var numItems:uint = loadFrom[iOn++];
			items = new Array();
			for (i = 0; i < numItems; i++)
			{
				items.push(new Point(loadFrom[iOn++], loadFrom[iOn++]));
				items.push(loadFrom[iOn++]);
				items.push(loadFrom[iOn++]);
			}
				
			creatures = new Array();
			makeCreatureBuckets();
			
			//load player
			pl = new Player();
			iOn = pl.load(loadFrom, iOn);
			addCreature(pl);
			
			//load creatures
			var numCreatures:uint = loadFrom[iOn++];
			for (i = 0; i < numCreatures; i++)
			{
				var cr:AI = new AI();
				iOn = cr.load(loadFrom, iOn);
				addCreature(cr);
			}
			
			return iOn;
		}
		
		public function saveLevel(saveTo:Array):void
		{
			//save settings
			saveTo.push(width);
			saveTo.push(height);
			saveTo.push(lengthSetting);
			saveTo.push(difficulty);
			saveTo.push(kills);
			saveTo.push(lastPR);
			saveTo.push(crime);
			
			//save tiles and related
			for (var i:uint = 0; i < tWidth * tHeight; i++)
				saveTo.push(tiles[i]);
			for (i = 0; i < rWidth * rHeight; i++)
				saveTo.push(roomDifficulties[i]);
			
			//save items
			saveTo.push(items.length / 3);
			for (i = 0; i < items.length / 3; i++)
			{
				saveTo.push((items[i * 3] as Point).x);
				saveTo.push((items[i * 3] as Point).y);
				saveTo.push(items[i * 3 + 1]);
				saveTo.push(items[i * 3 + 2]);
			}
			
			//save player
			pl.save(saveTo);
			
			//save creatures
			saveTo.push(creatures.length - 1);
			for (i = 0; i < creatures.length; i++)
				if (creatures[i] != pl)
					(creatures[i] as Creature).save(saveTo);
		}
		
		private function makeCreatureBuckets():void
		{
			creatureBuckets = new Array();
			for (var i:uint = 0; i < bWidth * bHeight; i++)
				creatureBuckets.push(new Array());
		}
		
		public function killAll():void
		{
			for (var i:uint = 0; i < creatures.length; i++)
			{
				var cr:Creature = creatures[i];
				if (cr != pl && !cr.isNPC)
				{
					var ai:AI = cr as AI;
					if (ai.activation != -1)
						ai.kill();
				}
			}
		}
		
		public function playIntro():void
		{
			pl.playIntro(crime);
		}
		
		public function Level(length:uint = 999, diff:uint = 0)
		{
			switchTime = -1;
			dyingCreatures = new Array();
			dyingProjectiles = new Array();
			projectiles = new Array();
			
			if (length == 999)
				return;
			
			//stuff that isn't tied to the map generator
			items = new Array();
			lastPR = Database.NONE;
			lengthSetting = length;
			difficulty = diff;
			kills = 0;
			
			mapGenerate(Main.data.lengthSettings[length][3]);
		}
		
		private function addCreature(cr:Creature):void
		{
			creatures.push(cr);
			creatureBuckets[toBucket(cr.position)].push(cr);
		}
		
		public function get player():Player { return pl; }
		public function addProjectile(prj:Projectile):void { projectiles.push(prj); }
		public function collideWall(pos:Point, rad:uint):Boolean
		{
			//quick check to see if this is an invalid place to walk to
			var buc:uint = toBucket(pos);
			if (buc == Database.NONE)
				return true;
				
			var tR:uint = Math.ceil(rad * 1.0 / TILESIZE);
			var xCenter:uint = pos.x / TILESIZE;
			var yCenter:uint = pos.y / TILESIZE;
			var xStart:int = xCenter - tR;
			var yStart:int = yCenter - tR;
			var xEnd:uint = xCenter + tR + 1;
			var yEnd:uint = yCenter + tR + 1;
			if (xStart < 0)
				xStart = 0;
			if (yStart < 0)
				yStart = 0;
			if (xEnd >= tWidth)
				xEnd = tWidth - 1;
			if (yEnd >= tHeight)
				yEnd = tHeight - 1;
				
			var cRect:Rectangle = new Rectangle(pos.x - rad, pos.y - rad, 2 * rad, 2 * rad);
				
			for (var y:uint = yStart; y <= yEnd; y++)
				for (var x:uint = xStart; x <= xEnd; x++)
				{
					var solid:Boolean = tileSolid(x, y);
					
					if (solid)
					{
						var tRect:Rectangle = new Rectangle(x * TILESIZE, y * TILESIZE, TILESIZE + 1, TILESIZE + 1);
						if (rectCollide(cRect, tRect) || rectCollide(tRect, cRect))
							return true;
					}
				}
				
			return false;
		}
		
		private function tileSolid(x:uint, y:uint):Boolean
		{
			var tI:uint = toTI(x, y);
			var tile:uint = tiles[tI];
			if (switchTime != -1 && toRI(x * TILESIZE / ROOMWIDTH, y * TILESIZE / ROOMHEIGHT) == playerRoom)
			{
				var alt:uint = Main.data.tiles[tile][7];
				if (alt != Database.NONE && Main.data.tiles[alt][4] != Database.NONE)
					return true;
			}
			return Main.data.tiles[tile][4] != Database.NONE;
		}
		
		private function rectCollide(r1:Rectangle, r2:Rectangle):Boolean
		{
			return r1.contains(r2.x, r2.y) || r1.contains(r2.x + r2.width, r2.y) || r1.contains(r2.x, r2.y + r2.height) ||
					r1.contains(r2.x + r2.width, r2.y + r2.height);
		}
		
		//room handling
		private function get rWidth():uint { return width / ROOMWIDTH; }
		private function get rHeight():uint { return height / ROOMHEIGHT; }
		private function toRX(i:uint):uint { return i % rWidth; }
		private function toRY(i:uint):uint { return i / rWidth; }
		private function toRI(x:uint, y:uint):uint { return x + y * rWidth; }
		
		//tile handling
		private function get tWidth():uint { return width / TILESIZE; }
		private function get tHeight():uint { return height / TILESIZE; }
		private function toTX(i:uint):uint { return i % tWidth; }
		private function toTY(i:uint):uint { return i / tWidth; }
		private function toTI(x:uint, y:uint):uint { return x + y * tWidth; }
		
		public function getCreaturesAround(position:Point):Array
		{
			var center:uint = toBucket(position);
			if (center == Database.NONE)
				return new Array(); //you are off map, so don't bother
			var centerX:uint = toBX(center);
			var centerY:uint = toBY(center);
			var startX:int = centerX - BUCKETSCHECKRADIUS;
			var startY:int = centerY - BUCKETSCHECKRADIUS;
			var endX:uint = centerX + BUCKETSCHECKRADIUS + 1;
			var endY:uint = centerY + BUCKETSCHECKRADIUS + 1;
			if (startX < 0)
				startX = 0;
			if (startY < 0)
				startY = 0;
			if (endX >= bWidth)
				endX = bWidth - 1;
			if (endY >= bHeight)
				endY = bHeight - 1;
				
			var near:Array = new Array();
			for (var y:uint = startY; y <= endY; y++)
				for (var x:uint = startX; x <= endX; x++)
					for (var j:uint = 0; j < creatureBuckets[toBI(x, y)].length; j++)
						near.push(creatureBuckets[toBI(x, y)][j]);
			return near;
		}
		
		public function get isActiveEnemy():Boolean
		{
			for (var i:uint = 0; i < creatures.length; i++)
			{
				var cr:Creature = creatures[i];
				
				if (cr != pl && !cr.dying && !cr.isNPC && (cr as AI).activation >= 0)
					return true; //this enemy is still active, so don't drop an item
			}
			return false;
		}
		
		private function getRoom(cr:Creature):uint
		{
			return toRI(cr.position.x / ROOMWIDTH, cr.position.y / ROOMHEIGHT);
		}
		
		private function get playerRoom():uint
		{
			return getRoom(player);
		}
		
		private function getRoomProgression(room:uint):Array
		{
			var dif:uint = roomDifficulties[room];
			
			var prog:uint = 1 + Main.data.progressions.length * dif / progressionLength;
			// note that super early progression (progression #0) is special and should not be activated normally
			if (prog >= Main.data.progressions.length)
				prog = Main.data.progressions.length - 1;
			
			if (dif <= SUPEREARLYLENGTH)
				prog = 0;
				
			while (Main.data.progressions[prog][1] == Database.NONE)
				prog -= 1;
			
			return Main.data.progressions[prog];
		}
		
		private function get roomProgression():Array
		{
			return getRoomProgression(playerRoom);
		}
		
		private function dropItem(cr:Creature):void
		{
			//first, find out if it's valid for them to drop an item
			var drops:Array = new Array();
			if (!isActiveEnemy)
			{
				//that was the last enemy of the room, so unlock the doors and give it a special drop
				toggleRoom();
			
				//pick the special drop
				drops.push(pl.getItemDrop(roomProgression[1]));
			}
			
			//increment your kills
			kills += 1;
			
			//does your new kills total qualify you for any difficulty-based drops?
			var difAra:Array = Main.data.difficulties[difficulty];
			for (var i:uint = 0; i < (difAra.length - 5) / 2; i++)
			{
				var freq:uint = difAra[i * 2 + 6];
				var it:uint = difAra[i * 2 + 5];
				if (kills % freq == 0 && (Main.data.items[it][1] != 2 || (pl.hasWeaponThatUses(it) && pl.ammoNotFull(it))))
					drops.push(it);
			}
			
			//place the items
			for (i = 0; i < drops.length; i++)
			{
				var iPos:Point = new Point(cr.position.x, cr.position.y - Player.WEAPONDROPHEIGHT);
				if (drops.length != 0)
				{
					var itemWheel:Point = Point.polar(ITEMWHEELSIZE, 2 * Math.PI * i / drops.length);
					iPos.x += itemWheel.x;
					iPos.y += itemWheel.y;
				}
				items.push(iPos);
				items.push(drops[i]);
				items.push(false); //it's not preserved
			}
		}
		
		public function move (cr:Creature, oldPos:Point):void
		{
			var oldB:uint = toBucket(oldPos);
			var newB:uint = toBucket(cr.position);
			if (oldB == newB)
				return; //don't bother
				
			var oldBucket:Array = creatureBuckets[oldB];
			var nOB:Array = new Array();
			for (var i:uint = 0; i < oldBucket.length; i++)
				if (oldBucket[i] != cr)
					nOB.push(oldBucket[i]);
			creatureBuckets[oldB] = nOB;
			
			creatureBuckets[newB].push(cr);
		}
		
		//bucket handling
		private function get bWidth():uint { return width / BUCKETSIZE; }
		private function get bHeight():uint { return height / BUCKETSIZE; }
		private function toBX(bucket:uint):uint { return bucket % bWidth; }
		private function toBY(bucket:uint):uint { return bucket / bWidth; }
		private function toBI(x:uint, y:uint):uint { return x + y * bWidth; }
		private function toBucket(position:Point):uint
		{
			var x:int = position.x / BUCKETSIZE;
			var y:int = position.y / BUCKETSIZE;
			if (x < 0 || y < 0 || x >= bWidth || y >= bHeight)
				return Database.NONE;
			return x + y * bWidth;
		}
		
		public override function update():void
		{
			if (switchTime != -1)
			{
				switchTime += FP.elapsed * SWITCHSPEED;
				if (switchTime >= 1)
					switchTime = -1;
			}
			
			var newDC:Array = new Array();
			for (var i:uint = 0; i < dyingCreatures.length; i++)
			{
				var dc:Creature = dyingCreatures[i];
				dc.update();
				if (!dc.dead)
					newDC.push(dc);
			}
			dyingCreatures = newDC;
			
			var newCret:Array = new Array();
			for (i = 0; i < creatures.length; i++)
			{
				var cr:Creature = creatures[i];
				cr.update();
				if (cr.dying)
				{
					//maybe drop an item?
					if (!cr.isNPC && cr != pl && !(cr as AI).isBoss)
						dropItem(cr);
					
					if (cr == pl)
					{
						(FP.engine as Main).gameOver();
					}
					else if ((cr as AI).isBoss)
					{
						//the game is over!
						killAll();
						pl.playOutro();
					}
					
					dyingCreatures.push(cr);
					
					//remove them from their bucket
					var nB:Array = new Array();
					var buc:Array = creatureBuckets[toBucket(cr.deathStart)];
					for (var j:uint = 0; j < buc.length; j++)
						if (buc[j] != cr)
							nB.push(buc[j]);
					if (buc.length == nB.length)
						trace("Failed to remove dead person");
					creatureBuckets[toBucket(cr.deathStart)] = nB;
				}
				else
					newCret.push(cr);
			}
			creatures = newCret;
				
			var newProj:Array = new Array();
			for (i = 0; i < projectiles.length; i++)
			{
				var prj:Projectile = projectiles[i];
				prj.update();
				if (prj.dying)
					dyingProjectiles.push(prj);
				else if (!prj.dead)
					newProj.push(prj);
			}
			projectiles = newProj;
			
			var newDPrj:Array = new Array();
			for (i = 0; i < dyingProjectiles.length; i++)
			{
				var dPrj:Projectile = dyingProjectiles[i];
				dPrj.update();
				if (!dPrj.dead)
					newDPrj.push(dPrj);
			}
			dyingProjectiles = newDPrj;
			
			//activate enemies
			if (lastPR != playerRoom && !pl.forceWalking && !pl.dying)
			{
				lastPR = playerRoom;
				activateRoom();
				clearItems();
			}
			
			//orient camera
			if (!pl.dying)
			{
				var rX:uint = toRX(playerRoom) * ROOMWIDTH;
				var rY:uint = toRY(playerRoom) * ROOMHEIGHT;
				FP.camera.x = rX;
				FP.camera.y = rY;
				
				if (player.position.x < rX + TILESIZE)
				{
					//on the left border
					FP.camera.x -= ROOMWIDTH / 2 * (rX + TILESIZE - player.position.x) / TILESIZE;
				}
				else if (player.position.x > rX + ROOMWIDTH - TILESIZE)
				{
					//on the right border
					FP.camera.x += ROOMWIDTH / 2 * (player.position.x - rX - ROOMWIDTH + TILESIZE) / TILESIZE;
				}
				if (player.position.y < rY + TILESIZE)
				{
					//on the top border
					FP.camera.y -= ROOMHEIGHT / 2 * (rY + TILESIZE - player.position.y) / TILESIZE;
				}
				else if (player.position.y > rY + ROOMHEIGHT - TILESIZE)
				{
					//on the bottom border
					FP.camera.y += ROOMHEIGHT / 2 * (player.position.y - rY - ROOMHEIGHT + TILESIZE) / TILESIZE;
				}
			}
		}
		
		public function setOG():void
		{
			for (var i:uint = 0; i < creatures.length; i++)
			{
				var cr:Creature = creatures[i];
				if (cr != pl)
					(cr as AI).setOG(oG);
			}
		}
		
		private function clearItems():void
		{
			if (items.length > 0)
			{
				var newIt:Array = new Array();
				for (var i:uint = 0; i < items.length / 3; i++)
				{
					var itPos:Point = items[i * 3];
					var it:uint = items[i * 3 + 1];
					var itSave:Boolean = items[i * 3 + 2];
					if (itSave)
					{
						newIt.push(itPos);
						newIt.push(it);
						newIt.push(itSave);
					}
				}
				items = newIt;
			}
		}
		
		private function activateRoom():void
		{
			var activeAny:Boolean = false;
			for (var i:uint = 0; i < creatures.length; i++)
			{
				var cr:Creature = creatures[i];
				if (cr != pl && getRoom(cr) == playerRoom && (cr as AI).activation == -1)
				{
					activeAny = true;
					(cr as AI).activation = 0;
				}
			}
			if (activeAny)
				toggleRoom();
		}
		
		public function trySummon(sum:uint):Creature
		{
			var tX:uint = toRX(playerRoom) * ROOMWIDTH / TILESIZE;
			var tY:uint = toRY(playerRoom) * ROOMHEIGHT / TILESIZE;
			var x:uint = tX + 2 + Math.floor(Math.random() * (ROOMWIDTH / TILESIZE - 4));
			var y:uint = tY + 2 + Math.floor(Math.random() * (ROOMHEIGHT / TILESIZE - 4));
			
			for (var cY:uint = 0; cY < 3; cY++)
				for (var cX:uint = 0; cX < 3; cX++)
				{
					var i:uint = toTI(x + cX - 1, y + cY - 1);
					if (tileSolid(x + cX - 1, y + cY - 1) || creatureBuckets[i].length > 0)
						return null;
				}
			
			var cr:AI = new AI(new Point(x * TILESIZE, y * TILESIZE), sum);
			cr.activation = 0;
			addCreature(cr);
			return cr;
		}
		
		private function get oG():uint
		{
			if (Main.data.crimes[crime][2])
				return player.gender;
			if (player.gender == 0)
				return 1;
			else
				return 0;
		}
		public function get itemsArray():Array { return items; }
		
		public static function drawItem(position:Point, type:uint):void
		{
			var iType:uint = Main.data.items[type][1];
			var sheet:uint;
			var frame:uint;
			var color:uint;
			var correspondsTo:uint = Main.data.items[type][4];
			
			if (iType == 3)
			{
				var pc:uint = Main.data.weapons[correspondsTo][7];
				color = Main.data.weapons[correspondsTo][8];
				var ft:uint = Main.data.pieces[pc][1];
				frame = Main.data.pieces[pc][2];
				sheet = Main.data.features[ft][1];
			}
			else if (iType == 4)
			{
				pc = Main.data.armors[correspondsTo][4 + (FP.world as Level).player.gender];
				color = Main.data.armors[correspondsTo][6];
				ft = Main.data.pieces[pc][1];
				frame = Main.data.pieces[pc][2];
				sheet = Main.data.features[ft][1];
			}
			else
			{
				sheet = Main.data.items[type][5];
				frame = Main.data.items[type][6];
				color = Main.data.items[type][7];
			}
			
			var spr:Spritemap = Main.data.spriteSheets[sheet];
			spr.frame = frame;
			spr.centerOrigin();
			spr.angle = 0;
			spr.scaleX = 1;
			spr.scaleY = 1;
			spr.color = color;
			spr.render(FP.buffer, position, FP.camera);
		}
		
		private function dArHeight(ar:Array):Number
		{
			switch(ar[0])
			{
			case 0: //creature
				return (ar[1] as Creature).position.y;
			case 1: //item
				return (items[ar[1] * 3] as Point).y;
			case 2: //projectile
				return (ar[1] as Projectile).position.y;
			case 3: //tile
				return (toTY(ar[1]) * TILESIZE);
			default: //none
				return 0;
			}
		}
		
		public function dARSort(a:Array, b:Array):Number
		{
			return dArHeight(a) - dArHeight(b);
		}
		
		private function drawMinimap():void
		{
			for (var y:uint = 0; y < tHeight; y++)
				for (var x:uint = 0; x < tWidth; x++)
				{
					var c:uint;
					if (tileSolid(x, y))
						c = 0xFF0000;
					else
						c = 0xFFFFFF;
					
					FP.buffer.fillRect(new Rectangle(x, y, 1, 1), c);
				}
		}
		
		private function drawTile(i:uint, sWI:Boolean = false):void
		{
			var tX:Number = toTX(i) * TILESIZE;
			var tY:Number = toTY(i) * TILESIZE;
			var tile:uint = tiles[i];
			var sw:Number = 1;
			var alt:uint = Main.data.tiles[tile][7];
			if (switchTime != -1 && alt != Database.NONE && toRI(toTX(i) * TILESIZE / ROOMWIDTH, toTY(i) * TILESIZE / ROOMHEIGHT) == playerRoom)
			{
				if (Main.data.tiles[alt][4] != Database.NONE)
				{
					tiles[i] = alt;
					drawTile(i, true);
					tiles[i] = tile;
					return;
				}
				sw = switchTime;
				if (sWI)
					sw = 1 - sw;
			}
			if (!tileSolid(tX / TILESIZE, tY / TILESIZE) || //you're a floor tile or
				switchTime != -1 || //doors are possibly moving or
				tY > height - TILESIZE || !tileSolid(tX / TILESIZE, tY / TILESIZE + 1)) //the guy below you is a floor tile
				drawTileBit(tile, 1, tX, tY, sw);
			drawTileBit(tile, 4, tX, tY - WALLHEIGHT * sw, sw);
		}
		
		private function drawTileBit(tile:uint, start:uint, x:Number, y:Number, sw:Number = 1):void
		{
			var sh:uint = Main.data.tiles[tile][start];
			if (sh == Database.NONE)
				return;
			var spr:Spritemap = Main.data.spriteSheets[sh];
			spr.frame = Main.data.tiles[tile][start + 1];
			spr.color = Main.data.tiles[tile][start + 2];
			spr.originX = 0;
			spr.originY = 0;
			if (sw != 1)
			{
				var alt:Array = Main.data.tiles[Main.data.tiles[tile][7]];
				var altColor:uint = alt[start + 2];
				if (altColor != 0)
					spr.color = FP.colorLerp(altColor, spr.color, sw);
			}
			spr.render(FP.buffer, new Point(x, y), FP.camera);
		}
		
		public override function render():void
		{
			/**
			drawMinimap();
			return;
			/**/
			
			//draw tiles
			var yStart:uint = FP.camera.y / TILESIZE;
			var xStart:uint = FP.camera.x / TILESIZE;
			var yEnd:uint = yStart + FP.height / TILESIZE;
			var xEnd:uint = xStart + FP.width / TILESIZE;
			
			//create the to-sort draw array
			var dAr:Array = new Array();
			for (var y:uint = yStart; y < yEnd; y++)
				for (var x:uint = xStart; x < xEnd; x++)
				{
					var bucket:Array = creatureBuckets[toBI(x, y)];
					for (var i:uint = 0; i < bucket.length; i++)
					{
						var ar:Array = new Array();
						ar.push(0); //creature
						ar.push(bucket[i]);
						dAr.push(ar);
					}
				}
			for (i = 0; i < items.length / 3; i++)
				if ((new Rectangle(FP.camera.x, FP.camera.y, FP.width, FP.height)).containsPoint(items[i * 3]))
				{
					ar = new Array();
					ar.push(1); //item
					ar.push(i);
					dAr.push(ar);
				}
			for (i = 0; i < projectiles.length; i++)
			{
				ar = new Array();
				ar.push(2); //projectile
				ar.push(projectiles[i]);
				dAr.push(ar);
			}
			//are you moving up or down?
			if (pl.forceWalking)
				yEnd += 2;
			for (y = yStart; y < yEnd; y++)
				for (x = xStart; x <= xEnd; x++)
				{
					if (!tileSolid(x, y))
						drawTile(toTI(x, y));
					else
					{
						ar = new Array();
						ar.push(3); //tile
						ar.push(toTI(x, y));
						dAr.push(ar);
					}
				}
			
			dAr.sort(dARSort);
			
			for (i = 0; i < dAr.length; i++)
			{
				ar = dAr[i];
				switch(ar[0])
				{
				case 0: //creature
					(ar[1] as Creature).render();
					break;
				case 1: //item
					drawItem(items[ar[1] * 3], items[ar[1] * 3 + 1]);
					break;
				case 2: //projectile
					(ar[1] as Projectile).render();
					break;
				case 3: //tile
					drawTile(ar[1]);
					break;
				}
			}
			
			for (i = 0; i < dyingCreatures.length; i++)
				(dyingCreatures[i] as Creature).render();
				
			for (i = 0; i < dyingProjectiles.length; i++)
				(dyingProjectiles[i] as Projectile).render();
				
			pl.renderUI();
			
			if (pl.fade > 0)
			{
				var snap:BitmapData = new BitmapData(FP.buffer.width, FP.buffer.height, true, (Math.floor(pl.fade * 0xFF) << 24) + pl.fadeColor);
				FP.buffer.draw(snap);
			}
		}
		
		public function get projDarken():Boolean
		{
			return getRoomProgression(playerRoom)[5];
		}
		
		private function toggleRoom():void
		{
			var tX:uint = toRX(playerRoom) * ROOMWIDTH / TILESIZE;
			var tY:uint = toRY(playerRoom) * ROOMHEIGHT / TILESIZE;
			
			switchTime = 0;
			
			for (var y:uint = 0; y < ROOMHEIGHT / TILESIZE; y++)
				for (var x:uint = 0; x < ROOMWIDTH / TILESIZE; x++)
				{
					var tI:uint = toTI(x + tX, y + tY);
					var tile:uint = tiles[tI];
					if (Main.data.tiles[tile][7] != Database.NONE)
						tiles[tI] = Main.data.tiles[tile][7];
				}
		}
		
		
		//map generation
		private function get progressionLength():uint
		{
			return Main.data.lengthSettings[lengthSetting][1];
		}
		
		private function get npcEvery():uint
		{
			return Main.data.lengthSettings[lengthSetting][2];
		}
		
		private function expandFrom(fromI:uint, roomTaken:Array, roomBack:Array, cont:int = 0, contTimer:uint = 0):Boolean
		{
			var fromD:uint = roomDifficulties[fromI];
			var fromX:uint = toRX(fromI);
			var fromY:uint = toRY(fromI);
			
			if (fromD == progressionLength)
				return true; //you have reached the end
			
			var possibilities:Array = new Array();
			if (fromX > 0)
				possibilities.push(-1);
			if (fromX < rWidth - 1)
				possibilities.push(1);
			if (fromY > 0)
				possibilities.push(-rWidth);
			if (fromY < rHeight - 1)
				possibilities.push(rWidth);
				
			var pickDir:int = 0;
			var finalPossibilities:Array = new Array();
			for (var i:uint = 0; i < possibilities.length; i++)
			{
				var dir:int = possibilities[i];
				if (!roomTaken[fromI + dir])
				{
					if (cont == dir && contTimer > 0)
					{
						contTimer -= 1;
						pickDir = cont;
					}
					finalPossibilities.push(dir);
				}
			}
			
			possibilities = null;
			
			if (finalPossibilities.length == 0)
				return false; //you are stuck
			
			//pick a direction
			var pick:uint;
			if (pickDir == 0)
			{
				pick = Math.random() * finalPossibilities.length;
				pickDir = finalPossibilities[pick];
			}
			pick = fromI + pickDir;
			finalPossibilities = null;
			
			if (pickDir != cont)
				contTimer = 3;
			
			//expand to that direction
			roomTaken[pick] = true;
			roomDifficulties[pick] = fromD + 1;
			roomBack[pick] = fromI;
			return expandFrom(pick, roomTaken, roomBack, pickDir, contTimer);
		}
		
		private function sideRoomFrom(fromI:uint, roomTaken:Array, roomBack:Array, chance:Number = SIDEROOMCHANCE):void
		{
			var fromD:uint = roomDifficulties[fromI];
			if (fromD >= progressionLength - 1 || fromD <= SUPEREARLYLENGTH)
				return; //don't expand the boss room, the prep room, or the very start
			
			var fromX:uint = toRX(fromI);
			var fromY:uint = toRY(fromI);
			var possibilities:Array = new Array();
			if (fromX > 0 && !roomTaken[fromI - 1])
				possibilities.push(fromI - 1);
			if (fromX < rWidth - 1 && !roomTaken[fromI + 1])
				possibilities.push(fromI + 1);
			if (fromY > 0 && !roomTaken[fromI - rWidth])
				possibilities.push(fromI - rWidth);
			if (fromY < rHeight - 1 && !roomTaken[fromI + rWidth])
				possibilities.push(fromI + rWidth);
				
			for (var i:uint = 0; i < possibilities.length; i++)
				if (Math.random() < chance)
				{
					//side room expand from there
					var toI:uint = possibilities[i];
					roomTaken[toI] = true;
					roomBack[toI] = fromI;
					roomDifficulties[toI] = fromD;
					
					sideRoomFrom(toI, roomTaken, roomBack, chance * SIDEROOMCHANCEDEGRADE);
				}
		}
		
		private function recutMap(rcut:Array):void
		{
			var roomTaken:Array = rcut[0];
			var roomBack:Array = rcut[1];
			var firstX:uint = rWidth;
			var firstY:uint = rHeight;
			var lastX:uint = 0;
			var lastY:uint = 0;
			for (var y:uint = 0; y < rHeight; y++)
				for (var x:uint = 0; x < rWidth; x++)
					if (roomTaken[toRI(x, y)])
					{
						if (x < firstX)
							firstX = x;
						if (x > lastX)
							lastX = x;
						if (y < firstY)
							firstY = y;
						if (y > lastY)
							lastY = y;
					}
					
			var rW:uint = lastX - firstX + 1;
			var rH:uint = lastY - firstY + 1;
			
			var newWidth:uint = rW * ROOMWIDTH;
			var newHeight:uint = rH * ROOMHEIGHT;
			
			var newTaken:Array = new Array();
			var newBack:Array = new Array();
			var newDif:Array = new Array();
			for (y = 0; y < rH; y++)
				for (x = 0; x < rW; x++)
				{
					var oldI:uint = toRI(x + firstX, y + firstY);
					newTaken.push(roomTaken[oldI]);
					newDif.push(roomDifficulties[oldI]);
					
					//translate roomback
					var bck:uint = roomBack[oldI];
					if (bck == Database.NONE)
						newBack.push(Database.NONE);
					else
					{
						var bckX:uint = toRX(bck);
						var bckY:uint = toRY(bck);
						newBack.push((bckX - firstX) + (bckY - firstY) * rW);
					}
				}
				
			//purposefully add a line of dead rooms below
			newHeight += ROOMHEIGHT;
			for (x = 0; x < rW; x++)
			{
				newDif.push(0);
				newTaken.push(false);
				newBack.push(Database.NONE);
			}
				
			var startI:uint = rcut[2];
			var startX:uint = toRX(startI);
			var startY:uint = toRY(startI);
			rcut[2] = (startX - firstX) + (startY - firstY) * rW;
				
			width = newWidth;
			height = newHeight;
			roomDifficulties = newDif;
			rcut[0] = newTaken;
			rcut[1] = newBack;
		}
		
		private function getNPCSchedule(npcs:Array = null):Array
		{
			//first, get the npcs
			if (!npcs)
			{
				npcs = new Array();
				for (var i:uint = 0; i < Main.data.classes.length; i++)
				{
					var aiPack:uint = Main.data.classes[i][11];
					if (aiPack != Database.NONE && Main.data.aiPackages[aiPack][1] != Database.NONE)
						npcs.push(i);
				}
			}
					
			//next, come up with an order which follows the following constaints:
			//1. each npc appears an equal number of times
			//2. an npc cannot appear twice in a row
			
			var order:Array = new Array();
			for (i = 0; i < NUMNPCROOMS; i++)
				order.push(Database.NONE);
			for (var j:uint = 0; j < NUMNPCROOMS / npcs.length; j++)
				for (i = 0; i < npcs.length; i++)
				{
					var validSpots:Array = new Array();
					for (var k:uint = 0; k < NUMNPCROOMS; k++)
						if (order[k] == Database.NONE && (k == 0 || order[k - 1] != npcs[i]) &&
												(k == NUMNPCROOMS - 1 || order[k + 1] != npcs[i]))
							validSpots.push(k);
					if (validSpots.length == 0)
					{
						//this is a bad position
						order = null;
						return getNPCSchedule(npcs);
					}
					else
					{
						//assign this room to that npc
						var pick:uint = Math.random() * validSpots.length;
						pick = validSpots[pick];
						order[pick] = npcs[i];
					}
				}
			return order;
		}
		
		private function mapGenerate(roomSide:uint):void
		{
			//initial room array
			width = ROOMWIDTH * roomSide;
			height = ROOMHEIGHT * roomSide;
			var roomTaken:Array = new Array();
			var roomBack:Array = new Array();
			roomDifficulties = new Array();
			for (var i:uint = 0; i < rWidth * rHeight; i++)
			{
				roomTaken.push(false);
				roomBack.push(Database.NONE);
				roomDifficulties.push(0);
			}
			
			//set start position
			var startX:uint = Math.random() * roomSide;
			var startY:uint = Math.random() * roomSide;
			var startI:uint = toRI(startX, startY);
			roomTaken[startI] = true;
			
			//make a path
			if (!expandFrom(startI, roomTaken, roomBack))
			{
				//there was an error in level generation; try again
				roomTaken = null;
				roomBack = null;
				mapGenerate(roomSide);
				return;
			}
			
			//find the end
			var roomOn:uint = Database.NONE;
			for (i = 0; i < roomDifficulties.length; i++)
				if (roomDifficulties[i] == progressionLength)
				{
					roomOn = i;
					break;
				}
			//path backwards from there
			while (roomOn != startI)
			{
				sideRoomFrom(roomOn, roomTaken, roomBack);
				
				roomOn = roomBack[roomOn];
			}
			
			//do you have enough rooms to qualify?
			var numRooms:uint = 0;
			for (i = 0; i < roomTaken.length; i++)
				if (roomTaken[i])
					numRooms += 1;
			if (numRooms < progressionLength * MINROOMFACTOR)
			{
				//restart
				roomTaken = null;
				roomBack = null;
				mapGenerate(roomSide);
				return;
			}
			
			//recut the map
			var rcut:Array = new Array();
			rcut.push(roomTaken);
			rcut.push(roomBack);
			rcut.push(startI);
			recutMap(rcut);
			roomTaken = rcut[0];
			roomBack = rcut[1];
			startI = rcut[2];
			startX = toRX(startI);
			startY = toRY(startI)
			rcut = null;
			
			//paint the basic shape
			tiles = new Array();
			for (i = 0; i < tWidth * tHeight; i++)
				tiles.push(true);
				
			for (i = 0; i < rWidth * rHeight; i++)
				if (roomTaken[i])
				{
					var rX:uint = toRX(i);
					var rY:uint = toRY(i);
					
					//carve out the general shape
					for (var y:uint = 1; y < ROOMHEIGHT / TILESIZE - 1; y++)
						for (var x:uint = 1; x < ROOMWIDTH / TILESIZE - 1; x++)
							tiles[toTI(x + rX * ROOMWIDTH / TILESIZE, y + rY * ROOMHEIGHT / TILESIZE)] = false;
							
					//place exit
					if (roomBack[i] != Database.NONE)
					{
						var rBX:uint = toRX(roomBack[i]);
						var rBY:uint = toRY(roomBack[i]);
						
						var xL:uint;
						var yT:uint;
						if (rBX != rX)
						{
							if (rBX > rX)
								xL = rBX * ROOMWIDTH / TILESIZE - 1;
							else
								xL = rX * ROOMWIDTH / TILESIZE - 1;
							yT = (rY + 0.5) * ROOMHEIGHT / TILESIZE - 1;
						}
						else
						{
							xL = (rX + 0.5) * ROOMWIDTH / TILESIZE - 1;
							if (rBY > rY)
								yT = rBY * ROOMHEIGHT / TILESIZE - 1;
							else
								yT = rY * ROOMHEIGHT / TILESIZE - 1;
						}
						
						for (y = yT; y <= yT + 1; y++)
							for (x = xL; x <= xL + 1; x++)
								tiles[toTI(x, y)] = false;
					}
				}
				
			//mark room content
			roomBack = null;
			var roomContent:Array = new Array();
			for (i = 0; i < roomTaken.length; i++)
			{
				if (roomDifficulties[i] == progressionLength)
					roomContent.push(1); //end boss
				else if (roomDifficulties[i] == progressionLength - 1)
					roomContent.push(2); //prep room
				else if (i == startI)
					roomContent.push(3); //start room
				else if (roomTaken[i])
					roomContent.push(0); //combat
				else
					roomContent.push(Database.NONE);
			}
			
			//get the NPC order
			var npcOrder:Array = getNPCSchedule();
			
			//place NPC rooms
			var numNPCs:uint = 0;
			for (i = 1; i < progressionLength / npcEvery; i++)
			{
				var dif:uint = i * npcEvery;
				if (dif < progressionLength - 1) //ensure it's not the boss or the start room
				{
					var possibilities:Array = new Array();
					for (var j:uint = 0; j < roomTaken.length; j++)
						if (roomTaken[j] && roomDifficulties[j] == dif)
							possibilities.push(j);
					var pick:uint = possibilities.length * Math.random();
					pick = possibilities[pick];
					roomContent[pick] = 4 + npcOrder[numNPCs]; //npc room
					numNPCs += 1;
				}
			}
			
			if (numNPCs != NUMNPCROOMS)
			{
				trace("Invalid number of NPC rooms (" + numNPCs + ")");
				//return;
			}
			
			//generate creatures
			creatures = new Array();
			makeCreatureBuckets();
			
			//place player
			pl = new Player(new Point((startX + 0.5) * ROOMWIDTH, (startY + 0.5) * ROOMHEIGHT));
			addCreature(pl);
			// free starting NPC
			//addCreature(new AI(new Point(pl.position.x + 100, pl.position.y), 10));
			
			//apply content info
			for (i = 0; i < roomContent.length; i++)
			{
				var roomCenter:Point = new Point((toRX(i) + 0.5) * ROOMWIDTH, (toRY(i) + 0.5) * ROOMHEIGHT);
				var minCover:uint = 0;
				var maxCover:uint = 0;
				var encPick:uint = Database.NONE;
				var tileset:uint = 0;
				switch(roomContent[i])
				{
				case 0: //enemy encounter
					//pick an encounter
					var prog:Array = getRoomProgression(i);
					encPick = Math.random() * (prog[3] - prog[2] + 1) + prog[2];
					tileset = getRoomProgression(i)[4];
					minCover = Main.data.tilesets[tileset][7];
					maxCover = Main.data.tilesets[tileset][8];
					break;
				case 1: //boss encounter
					addCreature(new AI(roomCenter, 1, Main.data.difficulties[difficulty][4] * 0.01));
				case 2: //prep room
					if (roomContent[i] == 2)
					{
						var off:uint = Main.data.featureLists[1][1];
						for (var pY:uint = 0; pY < 4; pY++)
							for (var pX:uint = 0; pX < 4; pX++)
							{
								var it:uint = Main.data.featureLists[1][pY * 4 + pX + 2];
								if (it != Database.NONE)
								{
									items.push(new Point(roomCenter.x - 2 * off + pX * off, roomCenter.y - 2 * off + pY * off));
									items.push(it);
									items.push(true);
								}
							}
					}
					tileset = getRoomProgression(i)[4];
					break;
				case 3: //start room
					tileset = getRoomProgression(i)[4];
					break;
				case Database.NONE: //empty room
					break;
				default: //npc room
					addCreature(new AI(roomCenter, roomContent[i] - 4));
					tileset = getRoomProgression(i)[4];
					minCover = Main.data.tilesets[tileset][9];
					maxCover = Main.data.tilesets[tileset][10];
					break;
				}
				translateTileset(i, tileset);
				if (encPick != Database.NONE)
					placeEnemies(encPick, i);
				addCover(minCover, maxCover, i, tileset);
			}
		}
		
		private function translateTileset(roomI:uint, tileset:uint):void
		{
			var bX:uint = toRX(roomI) * ROOMWIDTH / TILESIZE;
			var bY:uint = toRY(roomI) * ROOMHEIGHT / TILESIZE;
			
			for (var y:uint = 0; y < ROOMHEIGHT / TILESIZE; y++)
				for (var x:uint = 0; x < ROOMWIDTH / TILESIZE; x++)
				{
					var tI:uint = toTI(x + bX, y + bY);
					var sol:Boolean = tiles[tI];
					var start:uint;
					var end:uint;
					if (sol)
					{
						start = 3;
						end = 4;
					}
					else if (x == 0 || y == 0 || x == ROOMWIDTH / TILESIZE - 1 || y == ROOMHEIGHT / TILESIZE - 1)
					{
						start = 5;
						end = 5;
					}
					else
					{
						start = 1;
						end = 2;
					}
					start = Main.data.tilesets[tileset][start];
					end = Main.data.tilesets[tileset][end];
					var pick:uint = Math.random() * (end - start + 1) + start;
					tiles[tI] = pick;
				}
		}
		
		private function placeEnemies(encounter:uint, roomI:uint):void
		{
			var bX:uint = toRX(roomI) * ROOMWIDTH / BUCKETSIZE;
			var bY:uint = toRY(roomI) * ROOMHEIGHT / BUCKETSIZE;
			var enc:Array = Main.data.encounters[encounter];
			
			var toPlace:Array = new Array();
			for (var i:uint = 0; i < (enc.length - 1) / 3; i++)
			{
				var type:uint = enc[i * 3 + 1];
				var min:uint = enc[i * 3 + 2];
				var max:uint = enc[i * 3 + 3];
				
				var amount:uint = Math.random() * (max - min + 1) + min;
				for (var j:uint = 0; j < amount; j++)
					toPlace.push(type);
			}
			
			for (i = 0; i < COVERTRIES && toPlace.length > 0; i++)
			{
				var x:uint = bX + 2 + Math.random() * (ROOMWIDTH / BUCKETSIZE - 4);
				var y:uint = bY + 2 + Math.random() * (ROOMHEIGHT / BUCKETSIZE - 4);
				
				if (creatureBuckets[toBI(x, y)].length == 0 && !tileSolid(x, y))
				{
					type = toPlace.pop();
					var xR:Number = Math.random() * 0.5 + 0.25;
					var yR:Number = Math.random() * 0.5 + 0.25;
					addCreature(new AI(new Point((x + xR) * BUCKETSIZE, (y + yR) * BUCKETSIZE), type));
				}
			}
		}
		
		private function addCover(minCover:uint, maxCover:uint, roomI:uint, tileset:uint):void
		{
			var cover:uint = Math.random() * (maxCover - minCover) + minCover;
			if (cover == 0)
				return;
			
			var tX:uint = toRX(roomI) * ROOMWIDTH / TILESIZE;
			var tY:uint = toRY(roomI) * ROOMHEIGHT / TILESIZE;
			
			for (var j:uint = 0; j < COVERTRIES && cover > 0; j++)
			{
				//pick a location for the cover
				var cX:uint = tX + 3 + Math.random() * (ROOMWIDTH / TILESIZE - 6);
				var cY:uint = tY + 3 + Math.random() * (ROOMHEIGHT / TILESIZE - 6);
				
				//get the dimensions
				var coverWidth:uint = 1;
				var coverHeight:uint = 1;
				
				//check the area
				var valid:Boolean = true;
				for (var y:uint = cY - 1; y < cY + coverHeight + 1; y++)
					for (var x:uint = cX - 1; x < cX + coverWidth + 1; x++)
						if (creatureBuckets[toTI(x, y)].length > 0 || tiles[toTI(x, y)] == Database.NONE || tileSolid(x, y))
						{
							valid = false;
							break;
						}
				if (valid)
				{
					cover -= 1;
					for (y = cY; y < cY + coverHeight; y++)
						for (x = cX; x < cX + coverWidth; x++)
							tiles[toTI(x, y)] = Database.NONE;
				}
			}
			
			//convert all the temp spots into cover
			for (y = 0; y < ROOMHEIGHT / TILESIZE; y++)
				for (x = 0; x < ROOMWIDTH / TILESIZE; x++)
					if (tiles[toTI(x + tX, y + tY)] == Database.NONE)
						tiles[toTI(x + tX, y + tY)] = Main.data.tilesets[tileset][6];
		}
	}

}