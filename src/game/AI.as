package game 
{
	import flash.geom.Point;
	import net.flashpunk.FP;
	
	public class AI extends Creature
	{
		public var activation:Number;
		public var aiPackage:uint;
		//normal enemy variables
		private var rotateDir:int;
		private var rotateDirTimer:Number;
		private static const ACTIVATIONRATE:Number = 1.5;
		private static const SMALLROTATEDIRTIMERSPEED:Number = 3.5;
		//boss variables
		private var bossTimer:Number;
		private var attackTimer:Number;
		private var toSummon:uint;
		private var bossGoal:Point;
		private static const BOSSGOALDIS:uint = 200;
		private var summoned:Array;
		private var bossAttack:uint;
		private static const MAXSUMMON:uint = 7;
		
		public function setOG(oG:uint):void
		{
			if (isNPC && raceHasGender)
				gender = oG;
		}
		
		public function AI(startPosition:Point = null, cClass:uint = 0, healthMult:Number = 1)
		{
			rotateDir = 0;
			rotateDirTimer = 1;
			bossTimer = 0;
			bossAttack = 0;
			attackTimer = -1;
			bossGoal = null;
			toSummon = Database.NONE;
			summoned = null;
			super(startPosition, cClass, false);
			health *= healthMult;
			maxHealth *= healthMult;
			if (startPosition)
			{
				aiPackage = Main.data.classes[cClass][11];
				if (isNPC)
					activation = 1;
				else
					activation = -1;
			}
		}
		
		public function get isBoss():Boolean
		{
			return !isNPC && !aiMoveShoot && Main.data.aiPackages[aiPackage][3] == Database.NONE;
		}
		
		private function get aiMaxRange():uint
		{
			if (!weaponSwing)
				return Main.data.aiPackages[aiPackage][7];
			else
				return weaponProjectile;
		}
		
		private function get aiMinRange():uint
		{
			if (!weaponSwing)
				return Main.data.aiPackages[aiPackage][8];
			else
				return 0;
		}
		
		public override function takeHit(amount:uint, knockDir:Point):void
		{
			var oldH:uint = health;
			super.takeHit(amount, knockDir);
			if (isBoss)
			{
				var interV:uint = Main.data.aiPackages[aiPackage][4] * 0.01 * maxHealth;
				var oldSum:uint = (maxHealth - oldH) / interV;
				var newSum:uint = (maxHealth - health) / interV;
				
				if (oldSum < newSum)
				{
					if (health > maxHealth / 2)
						toSummon = Main.data.aiPackages[aiPackage][5];
					else
						toSummon = Main.data.aiPackages[aiPackage][6];
				}
			}
		}
		
		private function get aiMoveShoot():Boolean { return Main.data.aiPackages[aiPackage][2]; }
		
		private function getVectorStrength(far:uint, near:uint, dis:Number):Number
		{
			var disF:Number = (dis - aiMinRange) / (aiMaxRange - aiMinRange);
			if (disF < 0)
				disF = 0;
			else if (disF > 1)
				disF = 1;
				
			return (Main.data.aiPackages[aiPackage][far] * disF + Main.data.aiPackages[aiPackage][near] * (1 - disF)) * 0.01;
		}
		
		private function bossAI():void
		{
			if (!summoned)
				summoned = new Array();
			
			var l:Level = FP.world as Level;
				
			if (toSummon != Database.NONE && summoned.length < MAXSUMMON)
			{
				var sum:Creature = l.trySummon(toSummon);
				if (sum)
				{
					summoned.push(sum);
					toSummon = Database.NONE;
				}
			}
			
			var newSum:Array = new Array();
			for (var i:uint = 0; i < summoned.length; i++)
				if (!(summoned[i] as Creature).dying)
					newSum.push(summoned[i]);
			summoned = newSum;
			
			if (attackTimer == -1)
			{
				bossTimer += FP.elapsed;
				
				if (bossTimer >= Main.data.aiPackages[aiPackage][7] * 0.01)
				{
					bossTimer = 0;
					attackTimer = 0;
					bossGoal = null;
					altWeapon = Main.data.aiPackages[aiPackage][8 + bossAttack * 4];
					perfectSwitch();
				}
				else
				{
					//move around also
					if (!bossGoal)
					{
						bossGoal = Point.polar(BOSSGOALDIS, 2 * Math.PI * Math.random());
						var cX:uint = position.x / Level.ROOMWIDTH;
						var cY:uint = position.y / Level.ROOMHEIGHT;
						bossGoal.x += (cX + 0.5) * Level.ROOMWIDTH;
						bossGoal.y += (cY + 0.5) * Level.ROOMHEIGHT;
					}
					var dif:Point = new Point(bossGoal.x - position.x, bossGoal.y - position.y);
					targetPoint = new Point(position.x, position.y);
					if (dif.x > 0)
						targetPoint.x += 100;
					else
						targetPoint.x -= 100;
					if (dif.length < speed * FP.elapsed || !move(dif))
						bossGoal = null;
				}
			}
			else
			{
				//attack variables
				var charge:Number = Main.data.aiPackages[aiPackage][9 + bossAttack * 4] * 0.01;
				var length:Number = Main.data.aiPackages[aiPackage][10 + bossAttack * 4] * 0.01;
				var track:Boolean = Main.data.aiPackages[aiPackage][11 + bossAttack * 4];
				
				attackTimer += FP.elapsed;
				
				if ((attackTimer < charge || track) && attackAnim == -1)
					targetPoint = new Point(l.player.position.x, l.player.position.y);
				
				if (attackTimer >= charge)
					attack();
				
				if (attackTimer > charge + length)
				{
					perfectSwitch();
					attackTimer = -1;
					if (bossAttack * 4 + 9 + 4 >= Main.data.aiPackages[aiPackage].length)
						bossAttack = 0;
					else
						bossAttack += 1;
				}
			}
		}
		
		private function approachPlayerVector(moveDirection:Point):Boolean
		{
			var dif:Point = new Point(targetPoint.x - position.x, targetPoint.y - position.y);
			var dis:Number = dif.length;
			var str:Number = getVectorStrength(3, 4, dis);
			
			if (dis <= aiMinRange)
			{
				//move further away
				moveDirection.x -= dif.x * str;
				moveDirection.y -= dif.y * str;
			}
			else if (dis <= aiMaxRange) //if you are in range to attack
				return true; //so you can attack
			else
			{
				//move in closer
				moveDirection.x += dif.x * str;
				moveDirection.y += dif.y * str;
			}
			
			return false;
		}
		
		private function rotatePlayerVector(moveDirection:Point):void
		{
			rotateDirTimer -= FP.elapsed * SMALLROTATEDIRTIMERSPEED;
			if (rotateDirTimer <= 0)
			{
				rotateDirTimer += 1;
				rotateDir = Math.random() * 3;
				rotateDir -= 1;
			}
				
			if (rotateDir != 0)
			{
				//move perpendicular to the difference
				var dif:Point = new Point(targetPoint.x - position.x, targetPoint.y - position.y);
				var dis:Number = dif.length;
				var str:Number = getVectorStrength(5, 6, dis);
				var ang:Number = Math.atan2(dif.y, dif.x);
				var per:Point = Point.polar(dis, ang + Math.PI * rotateDir / 2);
				moveDirection.x += per.x * str;
				moveDirection.y += per.y * str;
			}
		}
		
		private function weaponCheck():void
		{
			if (canSwitch)
			{
				var dis:Number = (new Point(targetPoint.x - position.x, targetPoint.y - position.y)).length;
				
				var curValid:Boolean = (dis > aiMinRange && dis <= aiMaxRange);
				var curClose:Number = Math.abs((aiMaxRange + aiMinRange) * 0.5 - dis);
				
				tempSwitch();
				
				var altValid:Boolean = (dis > aiMinRange && dis <= aiMaxRange);
				var altClose:Number = Math.abs((aiMaxRange + aiMinRange) * 0.5 - dis);
				
				tempSwitch();
				
				if ((!curValid && altValid) ||
					(!curValid && !altValid && altClose < curClose))
					switchWeapon();
			}
		}
		
		public override function get vulnerable():Boolean { return !isNPC && activation == 1; }
		
		public function get dialoguePackage():Number
		{
			return Main.data.aiPackages[aiPackage][1];
		}
		public override function get isNPC():Boolean
		{
			return dialoguePackage != Database.NONE;
		}
		
		public override function render():void
		{
			if (activation == -1)
				return;
			
			var actUp:Number = 0;
			if (activation < 1)
			{
				actUp = (1 - activation) * FP.height;
				targetPoint = new Point(position.x, position.y + 100);
			}
			
			position.y -= actUp;
			super.render();
			position.y += actUp;
		}
		
		public override function update():void
		{
			var l:Level = FP.world as Level;
			
			if (dying || l.player.dying)
			{
				super.update();
				return;
			}
			
			if (activation < 1)
			{
				if (activation != -1)
					activation += ACTIVATIONRATE * FP.elapsed;
				if (activation > 1)
					activation = 1;
				super.update();
				return;
			}
			
			if (isNPC)
			{
				if (chestArmor != Database.NONE)
				{
					//forward target point
					var xTP:int;
					if (l.player.position.x > position.x)
						xTP = FP.width;
					else
						xTP = -FP.width;
					var yTP:int;
					if (l.player.position.y > position.y)
						yTP = 1;
					else
						yTP = -1;
					targetPoint = new Point(position.x + xTP, position.y + yTP);
				}
				else
					targetPoint = new Point(position.x + 10, position.y + 1); //naked people can't turn because they are anvils
				
				super.update();
				return;
			}
			
			if (isBoss)
			{
				bossAI();
				super.update();
				return;
			}
			
			targetPoint = new Point(l.player.position.x, l.player.position.y);
			
			//weapon switching
			weaponCheck();
			
			var moveDirection:Point = new Point(0, 0);
		
			if (canAttack || aiMoveShoot)
			{
				//don't move if you are reloading
				
				if (approachPlayerVector(moveDirection))
					attack();
				
				rotatePlayerVector(moveDirection);
			}
			
			if (moveDirection.x != 0 || moveDirection.y != 0)
				move(moveDirection);
			
			super.update();
		}
	}

}