package game 
{
	import flash.geom.Rectangle;
	import net.flashpunk.FP;
	import flash.geom.Point;
	import net.flashpunk.graphics.Spritemap;
	import net.flashpunk.graphics.Text;
	
	public class Creature 
	{
		//position data
		public var position:Point;
		private var knockback:Point;
		
		//targeting data
		protected var targetPoint:Point;
		
		//stats
		protected var rawSpeed:uint;
		protected var maxHealth:uint;
		private var rawDefense:uint;
		private var player:Boolean;
		
		//equipment
		private var weapon:uint;
		protected var altWeapon:uint;
		protected var chestArmor:uint;
		protected var legArmor:uint;
		protected var footArmor:uint;
		protected var faceArmor:uint;
		protected var ammo:Array;
		
		//variables
		protected var health:uint;
		protected var attackAnim:Number;
		private var walkAnim:Number;
		private var attackCooldown:Number;
		private var altLoaded:Boolean;
		
		//death animation
		private var deathAnim:Number;
		private var deathXTarget:Number;
		public var deathStart:Point;
		private var _poof:uint;
		private var _poofAr:Array;
		
		//appearance
		private var race:uint;
		private var skinColor:uint;
		public var gender:uint;
		private var hairColor:uint;
		private var hairStyle:uint;
		private var eyeColor:uint;
		
		//constants
		private static const MELEEARC:uint = Math.PI;
		private static const WALKANIMSPEEDBASE:Number = 1;
		private static const MAXSPEEDPEN:uint = 75;
		private static const WALKANIMSPEEDADD:Number = 0.003;
		private static const ATTACKPOWPOINT:Number = 0.5;
		private static const ATTACKINGSPEEDPENALTY:Number = 5;
		//death values
		private static const DEATHRATE:Number = 0.4;
		private static const DEATHROTRATE:Number = 1000;
		private static const DEATHXTARGETRANGE:Number = 200;
		private static const DEATHTHROWHEIGHT:Number = 650;
		private static const DEATHMARGIN:Number = 40;
		private static const POOFLENGTH:Number = 0.15;
		private static const PUFFLENGTH:Number = 0.35;
		private static const PUFFHEIGHT:uint = 35;
		private static const POOFDENSITY:uint = 80;
		private static const POOFWIDE:Number = 1.3;
		public static const POOFSCALEEND:Number = 0.55;
		//knockback values
		private static const KNOCKBACKMIN:uint = 5;
		private static const KNOCKBACKFACTOR:Number = 3.5;
		private static const KNOCKBACKFADE:Number = 800;
		//UI values
		public static const BARWIDTH:uint = 100;
		public static const BARHEIGHT:uint = 30;
		public static const BARBORDER:uint = 3;
		private static const UICOVERHEIGHT:uint = 40;
		private static const UICOVERCOLOR:uint = 0x111133;
		public static const BARMARGIN:uint = 2;
		private static const BARHEALTHCOLOR:uint = 0xFF0000;
		private static const BARBACKCOLOR:uint = 0x663333;
		public static const BARBORDERCOLOR:uint = 0x333333;
		public static const UITEXTCOLOR:uint = 0x666666;
		public static const UITEXTCOLORSELECTED:uint = 0x999999;
		public static const UITEXTCOLORBAD:uint = 0x993333;
		public static const UIAMMOOFF:uint = 10;
		
		public function save (saveTo:Array):void
		{
			if (dying)
				return; //don't save dying creatures
			
			//basic
			saveTo.push(position.x);
			saveTo.push(position.y);
			saveTo.push(player);
			
			//appearance
			saveTo.push(race);
			saveTo.push(gender);
			saveTo.push(skinColor);
			saveTo.push(hairStyle);
			saveTo.push(hairColor);
			saveTo.push(eyeColor);
			
			//player-specific stuff
			if (player)
			{
				saveTo.push(ammo.length);
				for (var i:uint = 0; i < ammo.length; i++)
					saveTo.push(ammo[i]);
					
				saveTo.push((this as Player).coins);
				saveTo.push((this as Player).ingots);
				for (i = 0; i < Main.data.dialoguePackages.length; i++)
					saveTo.push((this as Player).talkedTo[i]);
				
				//note that NPC dialogue stuff shouldn't save; in fact, you shouldn't be allowed to save while talking to an NPC
			}
			else
			{
				saveTo.push((this as AI).activation);
				saveTo.push((this as AI).aiPackage);
			}
			
			//stats
			saveTo.push(rawSpeed);
			saveTo.push(rawDefense);
			saveTo.push(maxHealth);
			saveTo.push(health);
			
			//weapon
			saveTo.push(weapon);
			saveTo.push(altWeapon);
			
			//armor
			saveTo.push(chestArmor);
			saveTo.push(legArmor);
			saveTo.push(footArmor);
			saveTo.push(faceArmor);
			
			//variables
			saveTo.push(altLoaded);
			saveTo.push(attackCooldown);
			saveTo.push(attackAnim);
			saveTo.push(walkAnim);
		}
		
		public function load (loadFrom:Array, iOn:uint):uint
		{
			//basic
			position = new Point(loadFrom[iOn++], loadFrom[iOn++]);
			player = loadFrom[iOn++];
			
			//appearance
			race = loadFrom[iOn++];
			gender = loadFrom[iOn++];
			skinColor = loadFrom[iOn++];
			hairStyle = loadFrom[iOn++];
			hairColor = loadFrom[iOn++];
			eyeColor = loadFrom[iOn++];
			
			//player-specific stuff
			if (player)
			{
				 var amL:uint = loadFrom[iOn++];
				 ammo = new Array();
				 for (var i:uint = 0; i < amL; i++)
					ammo.push(loadFrom[iOn++]);
					
				(this as Player).coins = loadFrom[iOn++];
				(this as Player).ingots = loadFrom[iOn++];
				
				for (i = 0; i < Main.data.dialoguePackages.length; i++)
					(this as Player).talkedTo[i] = loadFrom[iOn++];
				
				//note that NPC dialogue stuff shouldn't save; in fact, you shouldn't be allowed to save while talking to an NPC
			}
			else
			{
				ammo = null;
				(this as AI).activation = loadFrom[iOn++];
				(this as AI).aiPackage = loadFrom[iOn++];
			}
			
			//stats
			rawSpeed = loadFrom[iOn++];
			rawDefense = loadFrom[iOn++];
			maxHealth = loadFrom[iOn++];
			health = loadFrom[iOn++];
			
			//weapons
			weapon = loadFrom[iOn++];
			altWeapon = loadFrom[iOn++];
			
			//armor
			chestArmor = loadFrom[iOn++];
			legArmor = loadFrom[iOn++];
			footArmor = loadFrom[iOn++];
			faceArmor = loadFrom[iOn++];
			
			//variables
			altLoaded = loadFrom[iOn++];
			attackCooldown = loadFrom[iOn++];
			attackAnim = loadFrom[iOn++];
			walkAnim = loadFrom[iOn++];
			
			return iOn;
		}
		
		public function kill():void { health = 0; }
		
		public function setAppearance(gen:uint, hairS:uint, hairC:uint, skinC:uint, eyeC:uint, hat:uint):void
		{
			gender = gen;
			hairStyle = Main.data.featureLists[raceHairList][hairS + 1];
			hairColor = Main.data.featureLists[raceHairColorList][hairC + 1];
			skinColor = Main.data.featureLists[raceSkinColorList][skinC + 1];
			eyeColor = Main.data.featureLists[raceEyeColorList][eyeC + 1];
			faceArmor = Main.data.featureLists[0][hat + 1];
		}
		
		public function get isNPC():Boolean { return false; }
		
		public function Creature(startPosition:Point = null, cClass:uint = 0, isPlayer:Boolean = false) 
		{
			//variables that aren't loaded by the loader
			deathAnim = -1;
			targetPoint = position;
			_poof = Database.NONE;
			_poofAr = null;
			knockback = null;
			
			if (startPosition == null)
				return; //it is meant to be loaded
			
			position = startPosition;
			player = isPlayer;
			
			//appearance
			race = Main.data.classes[cClass][1];
			if (raceHasGender)
				gender = Math.random() * 2;
			else
				gender = 0;
			skinColor = pickFromList(raceSkinColorList);
			hairColor = pickFromList(raceHairColorList);
			hairStyle = pickFromList(raceHairList);
			eyeColor = pickFromList(raceEyeColorList);
			
			//stats
			rawSpeed = Main.data.classes[cClass][3];
			maxHealth = Main.data.classes[cClass][2];
			rawDefense = Main.data.classes[cClass][4];
			
			//equipment
			weapon = Main.data.classes[cClass][9];
			altWeapon = Main.data.classes[cClass][10];
			chestArmor = Main.data.classes[cClass][5];
			legArmor = Main.data.classes[cClass][6];
			footArmor = Main.data.classes[cClass][7];
			faceArmor = Main.data.classes[cClass][8];
			if (player)
			{
				ammo = new Array();
				for (var i:uint = 0; Main.data.items[i][1] == 2; i++)
				{
					var halfFull:uint = Main.data.items[i][3] / 2;
					ammo.push(halfFull);
				}
			}
			else
				ammo = null;
			
			health = maxHealth;
			attackAnim = -1;
			walkAnim = -1;
			attackCooldown = 0;
			altLoaded = true;
		}
		
		public function poof(color:uint):void
		{
			deathStart = new Point(position.x, position.y);
			_poofAr = new Array();
			_poof = color;
			deathAnim = 0;
		}
		
		private function pickFromList(list:uint):uint
		{
			if (list == Database.NONE)
				return Database.NONE;
			var lst:Array = Main.data.featureLists[list];
			var len:uint = lst.length - 1;
			var pick:uint = 1 + Math.random() * len;
			return lst[pick];
		}
		
		public static function drawFeature(position:Point, piece:uint, color:uint, dRot:Number, add:uint, hFlip:Boolean = false, vFlip:Boolean = false, rotation:Number = 0):void
		{
			if (color == Database.NONE || piece == Database.NONE)
				return; //it's invisible
			
			var ftT:Array = Main.data.features[Main.data.pieces[piece][1]];
			var spr:Spritemap = Main.data.spriteSheets[ftT[1]];
			spr.color = color;
			spr.originX = ftT[2];
			spr.originY = ftT[3];
			spr.angle = -rotation - dRot;
			if (vFlip)
				spr.scaleY = -1;
			else
				spr.scaleY = 1;
			if (hFlip)
				spr.scaleX = -1;
			else
				spr.scaleX = 1;
			spr.frame = Main.data.pieces[piece][2] + add;
			
			var addP:Point = new Point(ftT[4], ftT[5]);
			if (dRot != 0)
			{
				var addPN:Number = Math.atan2(addP.y, addP.x);
				addP = Point.polar(addP.length, addPN + dRot * Math.PI / 180);
			}
			
			spr.render(FP.buffer, new Point(position.x + addP.x, position.y + addP.y), FP.camera);
		}
		
		protected function tempSwitch():void
		{
			var tW:uint = altWeapon;
			altWeapon = weapon;
			weapon = tW;
		}
		
		protected function unloadAlt():void { altLoaded = false;}
		
		protected function perfectSwitch():void
		{
			var tW:uint = altWeapon;
			altWeapon = weapon;
			weapon = tW;
			attackCooldown = 0;
			attackAnim = -1;
		}
		
		protected function switchWeapon():void
		{
			if (canSwitch)
			{
				var oldAL:Boolean = altLoaded;
				altLoaded = attackCooldown <= 0; //is your current weapon loaded?
				var tW:uint = altWeapon;
				altWeapon = weapon;
				weapon = tW;
				if (!oldAL || !hasAmmo)
					attackCooldown = weaponCooldown; //your alt weapon wasn't loaded, so you have to load it
				else
					attackCooldown = 0; //your alt weapon was loaded, so cooldown is done now
			}
		}
		
		protected function get canSwitch():Boolean { return altWeapon != Database.NONE && attackAnim == -1; }
		protected function get canAttack():Boolean { return attackAnim == -1 && attackCooldown <= 0; }
		protected function get hasAmmo():Boolean
		{
			if (!player || weaponAmmoType == Database.NONE)
				return true;
			return ammo[weaponAmmoType] > 0;
		}
		
		protected function attack():void
		{
			if (canAttack)
			{
				attackAnim = 0;
				attackCooldown = weaponCooldown;
				
				//deduct ammo
				if (player && weaponAmmoType != Database.NONE)
					ammo[weaponAmmoType] -= 1;
			}
		}
		
		private function moveInner(amount:Point):Boolean
		{
			if (Math.abs(amount.x) > Math.abs(amount.y))
			{
				//x first
				var movedX:Boolean = moveInnerPart(new Point(amount.x, 0));
				var movedY:Boolean = moveInnerPart(new Point(0, amount.y));
				return movedX || movedY;
			}
			else
			{
				//y first
				movedY = moveInnerPart(new Point(0, amount.y));
				movedX = moveInnerPart(new Point(amount.x, 0));
				return movedX || movedY;
			}
		}
		
		private function moveInnerPart(amount:Point):Boolean
		{
			var steps:uint = Math.ceil(amount.length);
			var stepSize:Point = new Point(amount.x / steps, amount.y / steps);
			
			//try this from the end to the beginning
			//for precise movements
			var startP:Point = new Point(position.x, position.y);
			for (var i:uint = steps; i >= 1; i--)
			{
				position = new Point(startP.x + stepSize.x * i, startP.y + stepSize.y * i);
				
				var crs:Array = (FP.world as Level).getCreaturesAround(position);
				var coll:Boolean = (FP.world as Level).collideWall(position, raceMaskSize);
				for (var j:uint = 0; !coll && j < crs.length; j++)
				{
					var cr:Creature = crs[j];
					if (cr != this &&
						(new Point(cr.position.x - position.x, cr.position.y - position.y)).length <=
							raceMaskSize + cr.raceMaskSize)
						coll = true;
				}
				
				if (!coll)
				{
					//this is a valid move
					//so update your buckets
					(FP.world as Level).move(this, startP);
					return true;
				}
			}
			
			//you couldn't move at all, so revert to your starting position
			position = startP;
			
			return false;
		}
		
		protected function move(dir:Point):Boolean
		{
			if (knockback)
				return false; //can't move manually when there is knockback
			var spd:Number = speed * FP.elapsed;
			dir.normalize(spd);
			var moved:Boolean = moveInner(dir);
			if (walkAnim == -1)
				walkAnim = 0;
			return moved;
		}
		
		public function get vulnerable():Boolean { return true; }
		
		private function oneMeleeHit(vs:Creature):Boolean
		{
			if (this == vs || !vs.vulnerable)
				return false;
				
			var dif:Point = new Point(vs.position.x - position.x, vs.position.y - position.y);
			if (dif.length < weaponProjectile)
			{
				var angle:Number = Math.atan2(dif.y, dif.x);
				var swingAngle:Number = Math.atan2(targetPoint.y - position.y, targetPoint.x - position.x);
				
				var angleDif:Number = FP.angleDiff(angle * 180 / Math.PI, swingAngle * 180 / Math.PI);
				if (Math.abs(angleDif) < MELEEARC * 0.5 * 180 / Math.PI)
				{
					vs.takeHit(weaponDamage, Point.polar(1, angle));
					return true;
				}
			}
			return false;
		}
		
		public function takeHit(amount:uint, knockDir:Point):void
		{
			if (amount > defense)
				amount -= defense;
			else
				amount = 0;
			if (health > amount)
				health -= amount;
			else
				health = 0;
			
			if (amount > KNOCKBACKMIN)
			{
				//knockback
				if (!knockback)
					knockback = new Point(0, 0);
				knockDir.normalize((amount - KNOCKBACKMIN) * KNOCKBACKFACTOR);
				knockback.x += knockDir.x;
				knockback.y += knockDir.y;
			}
		}
		
		private function meleeHit():Boolean
		{
			if (player)
			{
				var enemyList:Array = (FP.world as Level).getCreaturesAround(position);
				var hitAny:Boolean = false;
				for (var i:uint = 0; i < enemyList.length; i++)
					hitAny = oneMeleeHit(enemyList[i]) || hitAny;
				return hitAny;
			}
			else
				return oneMeleeHit((FP.world as Level).player);
		}
		
		private function get centerY():Number
		{
			if (raceArms == Database.NONE)
				return 0;
			return Main.data.features[Main.data.pieces[raceArms][1]][5];
		}
		
		private function getBoundedTarget(length:uint, swing:Boolean = false):Point
		{
			var dif:Point = new Point(targetPoint.x - position.x, targetPoint.y - position.y - centerY);
			
			if (swing)
			{
				var angle:Number = Math.atan2(dif.y, dif.x);
				var dir:int = -1;
				if (targetPoint.x < position.x)
					dir = 1
				angle += dir * MELEEARC / 2;
				if (attackAnim != -1)
					angle -= (attackAnim * dir * MELEEARC);
				else if (attackCooldown > 0)
					angle -= dir * MELEEARC; //just keep it down, to show it's not ready yet
				dif = Point.polar(length, angle);
			}
			else
				dif.normalize(length);
			
			return new Point(dif.x + position.x, dif.y + position.y + centerY);
		}
		
		private function drawFeatureRot(piece:uint, color:uint, frameAdd:uint = 0):void
		{
			if (piece == Database.NONE)
				return;
			var ftT:Array = Main.data.features[Main.data.pieces[piece][1]];
			var bT:Point = getBoundedTarget((Main.data.spriteSheets[ftT[1]] as Spritemap).width, weaponSwing);
			var trueBT:Point = getBoundedTarget((Main.data.spriteSheets[ftT[1]] as Spritemap).width);
			var armAngle:Number = Math.atan2(bT.y - position.y - ftT[5], bT.x - position.x - ftT[4])
								* 180 / Math.PI;
			var trueArmAngle:Number = Math.atan2(trueBT.y - position.y - ftT[5], trueBT.x - position.x - ftT[4])
								* 180 / Math.PI;
								
			drawFeature(position, piece, color, deathRotation, frameAdd, false, Math.abs(trueArmAngle) > 90, armAngle);
		}
		
		//derived stats
		protected function get speed():uint
		{
			var spdPen:uint = 0;
			if (chestArmor != Database.NONE)
				spdPen += Main.data.armors[chestArmor][3];
			if (legArmor != Database.NONE)
				spdPen += Main.data.armors[legArmor][3];
			if (footArmor != Database.NONE)
				spdPen += Main.data.armors[footArmor][3];
			
			var wspM:Number = 1;
			if (attackAnim != -1 || (attackCooldown > 0 && hasAmmo))
				wspM = ATTACKINGSPEEDPENALTY;
			spdPen += weaponSpeedPenalty * wspM;
				
			if (spdPen > MAXSPEEDPEN)
				spdPen = MAXSPEEDPEN;
			return rawSpeed * (100 - spdPen) / 100;
		}
		
		private function get defense():uint
		{
			var def:uint = rawDefense;
			if (chestArmor != Database.NONE)
				def += Main.data.armors[chestArmor][2];
			if (legArmor != Database.NONE)
				def += Main.data.armors[legArmor][2];
			if (footArmor != Database.NONE)
				def += Main.data.armors[footArmor][2];
			return def;
		}
		
		//weapon derived stats
		private function weaponPlaySound(add:uint):void
		{
			Main.playSound(Main.data.weapons[weapon][9 + add]);
		}
		private function get weaponDamage():uint { return Main.data.weapons[weapon][1]; }
		protected function get weaponSwing():Boolean { return Main.data.weapons[weapon][4] == 0; }
		private function get weaponAnimSpeed():Number { return Main.data.weapons[weapon][2] * 0.01; }
		private function get weaponCooldown():Number { return Main.data.weapons[weapon][3] * 0.01; }
		protected function get weaponProjectile():uint { return Main.data.weapons[weapon][5]; }
		private function get weaponSpeedPenalty():uint { return Main.data.weapons[weapon][6]; }
		private function get weaponPiece():uint { return Main.data.weapons[weapon][7]; }
		private function get weaponColor():uint { return Main.data.weapons[weapon][8]; }
		protected function get weaponAmmoType():uint
		{
			if (weaponSwing)
				return Database.NONE;
			return Main.data.projectiles[weaponProjectile][7];
		}
		
		//animation derived stats
		private function get walkAnimSpeed():Number { return WALKANIMSPEEDBASE + speed * WALKANIMSPEEDADD; }
		
		//race derived stats
		protected function get raceHasGender():Boolean { return Main.data.races[race][1] == 1; }
		private function get raceBody():uint { return Main.data.races[race][2]; }
		private function get raceLegs():uint { return Main.data.races[race][3]; }
		private function get raceArms():uint { return Main.data.races[race][4]; }
		private function get raceEyes():uint { return Main.data.races[race][5]; }
		private function get racePupils():uint { return Main.data.races[race][6]; }
		public function get raceHairList():uint { return Main.data.races[race][7] + gender; }
		public function get raceHairColorList():uint { return Main.data.races[race][8]; }
		public function get raceSkinColorList():uint { return Main.data.races[race][9]; }
		public function get raceEyeColorList():uint { return Main.data.races[race][10]; }
		public function get raceMaskSize():uint { return Main.data.races[race][11]; }
		
		public function get dead():Boolean { return (_poof != Database.NONE && _poofAr.length == 0) || 
													(position.y < FP.camera.y - DEATHMARGIN || deathAnim >= 1); }
		public function get dying():Boolean { return deathAnim != -1; }
		private function get deathRotation():Number
		{
			if (dying && _poof == Database.NONE)
				return DEATHROTRATE * deathAnim;
			else
				return 0;
		}
		
		private function deathSlowM(from:Number, add:Number):Number
		{
			return from + (1 - Math.pow(1 - deathAnim, 5)) * add;
		}
		
		public function update():void
		{
			if (health == 0 && !dying)
			{
				deathAnim = 0;
				deathStart = new Point(position.x, position.y);
				if (knockback && knockback.x < 0)
					deathXTarget = -DEATHXTARGETRANGE;
				else if (knockback && knockback.x > 0)
					deathXTarget = DEATHXTARGETRANGE;
				else
					deathXTarget = 2 * Math.random() * DEATHXTARGETRANGE - DEATHXTARGETRANGE;
				return;
			}
			if (dying)
			{
				var oDA:Number = deathAnim;
				deathAnim += FP.elapsed * DEATHRATE;
				if (_poof == Database.NONE)
					position = new Point(deathSlowM(deathStart.x, deathXTarget), deathSlowM(deathStart.y, -DEATHTHROWHEIGHT));
				else
				{
					//move poofs
					var nPA:Array = new Array();
					for (var i:uint = 0; i < _poofAr.length / 2; i++)
					{
						(_poofAr[i * 2] as Point).y -= FP.elapsed * PUFFHEIGHT / PUFFLENGTH;
						_poofAr[i * 2 + 1] += FP.elapsed;
						if (_poofAr[i * 2 + 1] < 1)
						{
							nPA.push(_poofAr[i * 2]);
							nPA.push(_poofAr[i * 2 + 1]);
						}
					}
					_poofAr = nPA;
					
					//generate poofs
					var oldPN:uint = oDA * POOFDENSITY / POOFLENGTH;
					var newPN:uint = deathAnim * POOFDENSITY / POOFLENGTH;
					if (newPN > POOFDENSITY)
						newPN = POOFDENSITY;
					while (oldPN < newPN)
					{
						var rand:Point = Point.polar(Math.random() * raceMaskSize * POOFWIDE, 2 * Math.random() * Math.PI);
						_poofAr.push(new Point(position.x + rand.x, position.y + rand.y));
						_poofAr.push(0);
						oldPN += 1;
					}
				}
				return;
			}
			
			if (knockback)
			{
				var newKnockback:Point = new Point(knockback.x, knockback.y);
				var nkbL:Number = knockback.length - KNOCKBACKFADE * FP.elapsed;
				knockback.normalize(knockback.length * FP.elapsed);
				moveInner(knockback);
				if (nkbL > 0)
				{
					knockback = newKnockback;
					knockback.normalize(nkbL);
				}
				else
					knockback = null;
			}
			
			if (attackAnim != -1)
			{
				var lAA:Number = attackAnim;
				attackAnim += FP.elapsed * weaponAnimSpeed;
				if (lAA < ATTACKPOWPOINT && attackAnim >= ATTACKPOWPOINT)
				{
					weaponPlaySound(0);
					if (weaponSwing)
					{
						if (meleeHit())
							weaponPlaySound(1);
					}
					else
					{
						//get direction
						var ftT:Array = Main.data.features[Main.data.pieces[weaponPiece][1]];
						var bT:Point = getBoundedTarget((Main.data.spriteSheets[ftT[1]] as Spritemap).width, weaponSwing);
						var armAngle:Number = Math.atan2(bT.y - position.y - ftT[5], bT.x - position.x - ftT[4]);
						
						var pAdd:Point = new Point(targetPoint.x - position.x, targetPoint.y - position.y);
						pAdd.normalize(-Main.data.features[Main.data.pieces[weaponPiece][1]][2]);
						var prj:Projectile = new Projectile(weaponDamage, weaponProjectile,
											new Point(position.x, position.y), Point.polar(1, armAngle), player);
						(FP.world as Level).addProjectile(prj);
					}
				}
				if (attackAnim >= 1)
					attackAnim = -1;
			}
			else if (attackCooldown > 0 && hasAmmo)
				attackCooldown -= FP.elapsed;
			if (walkAnim != -1)
			{
				walkAnim += FP.elapsed * walkAnimSpeed;
				if (walkAnim >= 1)
					walkAnim = -1;
			}
		}
		
		private function drawArms():void
		{
			//draw the arm
			var weaponAdd:uint = 0;
			if (!weaponSwing && (attackAnim > ATTACKPOWPOINT || (attackAnim == -1 && attackCooldown > 0)))
				weaponAdd = 1;
			drawFeatureRot(weaponPiece, weaponColor, weaponAdd);
			if (raceArms != Database.NONE)
			{
				drawFeatureRot(raceArms, skinColor);
				drawFeatureRot(raceArms + 1, skinColor);
			}
		}
		
		public function renderUI():void
		{
			//ui cover
			FP.buffer.fillRect(new Rectangle(0, FP.height - UICOVERHEIGHT, FP.width, UICOVERHEIGHT), UICOVERCOLOR);
			
			//health bar
			FP.buffer.fillRect(new Rectangle(BARMARGIN,
											FP.height - BARHEIGHT - BARMARGIN - BARBORDER * 2,
											BARWIDTH + BARBORDER * 2,
											BARHEIGHT + BARBORDER * 2), BARBORDERCOLOR);
			FP.buffer.fillRect(new Rectangle(BARMARGIN + BARBORDER,
											FP.height - BARHEIGHT - BARMARGIN - BARBORDER,
											BARWIDTH,
											BARHEIGHT), BARBACKCOLOR);
			FP.buffer.fillRect(new Rectangle(BARMARGIN + BARBORDER,
											FP.height - BARHEIGHT - BARMARGIN - BARBORDER,
											BARWIDTH * health / maxHealth,
											BARHEIGHT), BARHEALTHCOLOR);
		}
		
		protected function drawAmmo(x:Number, y:Number, type:uint, amount:uint = 99):Number
		{
			if (type != 0 && Main.data.items[type][1] == 2)
			{
				//check to see if any weapon uses this ammo type
				if (weaponAmmoType != type)
				{
					var uses:Boolean = false;
					if (altWeapon != Database.NONE)
					{
						tempSwitch();
						uses = weaponAmmoType == type;
						tempSwitch();
					}
					if (!uses)
						return x; //nope, you don't use that ammo type
				}
			}
			
			x += UIAMMOOFF;
			Level.drawItem(new Point(x + FP.camera.x, y + FP.camera.y), type);
			x += UIAMMOOFF;
			y -= UIAMMOOFF;
			
			var lead:String = "";
			if (ammo[type] < 10 && Main.data.items[type][2] >= 10)
				lead = "0";
			if (amount == 99)
				amount = ammo[type];
			var txt:Text = new Text(lead + amount);
			txt.color = UITEXTCOLOR;
			txt.render(FP.buffer, new Point(x, y), new Point(0, 0));
			x += txt.width;
			
			return x;
		}
		
		private function drawPoof():void
		{
			if (_poof != Database.NONE)
			{
				//draw a cloud of smoke
				var smokeS:uint = Main.data.dialogueTypes[6][1];
				var smokeN:uint = Main.data.dialogueTypes[6][2];
				var smokeSpr:Spritemap = Main.data.spriteSheets[smokeS];
				smokeSpr.color = _poof;
				smokeSpr.frame = smokeN;
				smokeSpr.centerOrigin();
				
				for (var i:uint = 0; i < _poofAr.length / 2; i++)
				{
					smokeSpr.scaleX = _poofAr[i * 2 + 1] * POOFSCALEEND + (1 - _poofAr[i * 2 + 1]);
					smokeSpr.scaleY = smokeSpr.scaleX;
					smokeSpr.render(FP.buffer, _poofAr[i * 2], FP.camera);
				}
			}
		}
		
		public function render():void
		{
			if (_poof != Database.NONE && deathAnim >= POOFLENGTH)
			{
				drawPoof();
				return;
			}
			if (!targetPoint)
				targetPoint = new Point(position.x + 100, position.y);
			
			var back:Boolean = targetPoint.y < position.y;
			var side:Boolean = targetPoint.x < position.x;
			
			if (back)
				drawArms();
				
			//draw the legs
			var legAdd:uint = 0;
			if (walkAnim < 0.5 && walkAnim != -1)
				legAdd = 1;
			if (back)
				legAdd += 2;
			drawFeature(position, raceLegs + gender, skinColor, deathRotation, legAdd, side);
			if (footArmor != Database.NONE)
				drawFeature(position, Main.data.armors[footArmor][4 + gender], Main.data.armors[footArmor][6], deathRotation, legAdd, side);
			if (legArmor != Database.NONE)
				drawFeature(position, Main.data.armors[legArmor][4 + gender], Main.data.armors[legArmor][6], deathRotation, legAdd, side);
			
			//draw the body
			var bodyAdd:uint = 0;
			if (back)
				bodyAdd += 1;
			drawFeature(position, raceBody + gender, skinColor, deathRotation, bodyAdd, side);
			if (chestArmor != Database.NONE)
				drawFeature(position, Main.data.armors[chestArmor][4 + gender], Main.data.armors[chestArmor][6], deathRotation, bodyAdd, side);
				
			if (!back)
			{
				//draw the eyes
				drawFeature(position, raceEyes, 0xFFFFFF, deathRotation, 0, side);
				drawFeature(position, racePupils, eyeColor, deathRotation, 0, side);
			}
				
			if (hairStyle != Database.NONE)
			{
				var hairAdd:uint = 0;
				if (back)
					hairAdd += 1;
				drawFeature(position, hairStyle, hairColor, deathRotation, hairAdd, side);
			}
			if (faceArmor != Database.NONE)
				drawFeature(position, Main.data.armors[faceArmor][4], Main.data.armors[faceArmor][6], deathRotation, bodyAdd, side);
			
			if (!back)
				drawArms();
				
			drawPoof();
		}
		
	}

}