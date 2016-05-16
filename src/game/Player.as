package game 
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	import net.flashpunk.FP;
	
	public class Player extends Creature
	{
		//misc inventory
		public var coins:uint;
		public var ingots:uint;
		private var forceWalk:Point;
		private var bombTimer:Number;
		
		//npc dialogue history
		public var talkedTo:Array;
		
		//npc dialogue
		private var talkingTo:AI;
		private var dialogue:uint;
		private var lineOn:uint;
		private var lineTime:Number;
		private var optionOn:uint;
		private var boughtSomething:Boolean;
		
		private static const BOMBCOOLDOWN:Number = 0.35;
		private static const BOMBDAMAGE:uint = 400;
		public static const BOMBAOE:uint = 100;
		public static const BOMBFUSESPEED:Number = 0.5;
		private static const FORCEWALKMARGIN:uint = 40;
		private static const MINLINEADVANCE:uint = 30;
		private static const LINESPEED:Number = 120;
		private static const HALFFADE1:Number = 10;
		private static const HALFFADE2:Number = 75;
		private static const FADEHOLD:Number = 100;
		private static const TALKDISTANCE:uint = 80;
		private static const PICKUPDISTANCE:uint = 50;
		private static const AUTOPICKUPDISTANCE:uint = 25;
		public static const WEAPONDROPHEIGHT:uint = 5;
		private static const TEXTWIDTH:uint = 700;
		private static const TEXTHEIGHT:uint = 200;
		private static const TEXTBORDER:uint = 10;
		private static const TEXTBACKCOLOR:uint = 0x333366;
		
		public function Player(startPosition:Point = null, difficulty:uint = 0) 
		{
			super(startPosition, 0, true);
			
			coins = Main.data.difficulties[difficulty][1];
			ingots = Main.data.difficulties[difficulty][2];
			talkingTo = null;
			lineTime = 0;
			bombTimer = 0;
			
			forceWalk = null;
			
			talkedTo = new Array();
			for (var i:uint = 0; i < Main.data.dialoguePackages.length; i++)
				talkedTo.push(false);
		}
		
		public function playIntro(crime:uint):void
		{
			talkingTo = new AI();
			startDialogue(Main.data.dialoguePackages[0][1 + Main.data.crimes[crime][3]]);
		}
		
		public function playOutro():void
		{
			talkingTo = new AI();
			startDialogue(Main.data.dialoguePackages[0][4]);
		}
		
		public function get canSave():Boolean
		{
			return !talkingTo && !forceWalk && !(FP.world as Level).isActiveEnemy;
		}
		
		private function findCorr(type:uint, corrTo:uint):uint
		{
			for (var i:uint = 0; i < Main.data.items.length; i++)
				if (Main.data.items[i][1] == type && Main.data.items[i][4] == corrTo)
					return i;
			return Database.NONE;
		}
		
		private function pickUp(item:uint, canDrop:Boolean = true, autoPick:Boolean = false):Boolean
		{
			var num:uint = Main.data.items[item][2];
			var max:uint = Main.data.items[item][3];
			var type:uint = Main.data.items[item][1];
			
			if (!Main.data.itemTypes[type][1] && autoPick)
				return false; //can't auto-pick up weapons, armor, etc
			
			var current:uint = 0;
			switch(type)
			{
			case 0:
				current = coins;
				break;
			case 1:
				current = ingots;
				break;
			case 2:
				current = ammo[item];
				break;
			case 3:
				if (!canSwitch && altWeapon != Database.NONE)
					return false; //can't pick up a weapon when you can't switch your weapon
				break;
			case 5:
				if (health == maxHealth)
					return false; //don't pick up health-ups if you are at full health
			}
			
			if (current == max)
				return false;
			
			if (current + num > max)
				num = max - current;
				
			switch(type)
			{
			case 0:
				coins += num;
				break;
			case 1:
				ingots += num;
				break;
			case 2:
				ammo[item] += num;
				break;
			case 3:
				//equip the weapon
				if (altWeapon == Database.NONE)
				{
					//you dont have an alt weapon, so put this there
					altWeapon = Main.data.items[item][4];
					switchWeapon();
					switchWeapon();
				}
				else
				{
					switchWeapon();
					var toDrop:uint = altWeapon;
					altWeapon = Main.data.items[item][4];
					unloadAlt();
					switchWeapon();
					
					if (canDrop)
					{
						//drop the old one
						
						//first, find the item that corresponds to your old weapon
						var corr:uint = findCorr(3, toDrop);
						if (corr != Database.NONE)
						{
							//drop that item
							var its:Array = (FP.world as Level).itemsArray;
							its.push(new Point(position.x, position.y - WEAPONDROPHEIGHT));
							its.push(corr);
							its.push(false); //it's temporary
						}
					}
				}
				break;
			case 4: //equip the armor
				var arCor:uint = Main.data.items[item][4];
				toDrop = Database.NONE;
				switch(Main.data.armors[arCor][1])
				{
				case 0: //chest
					if (chestArmor == arCor)
						return false; //already have it on
					toDrop = chestArmor;
					chestArmor = arCor;
					break;
				case 1: //leg
					if (legArmor == arCor)
						return false; //already have it on
					toDrop = legArmor;
					legArmor = arCor;
					break;
				case 2: //foot
					if (footArmor == arCor)
						return false; //already have it on
					toDrop = footArmor;
					footArmor = arCor;
					break;
				}
				
				if (canDrop)
				{
					//drop the old one
					corr = findCorr(4, toDrop);
					if (corr != Database.NONE)
					{
						its = (FP.world as Level).itemsArray;
						its.push(new Point(position.x, position.y - WEAPONDROPHEIGHT));
						its.push(corr);
						its.push(false); //it's temporary
					}
				}
				break;
			case 5:
				//heal
				health += (maxHealth / 2);
				if (health > maxHealth)
					health = maxHealth;
				break;
			}
			
			return true;
		}
		
		private function canAfford(op:uint):Boolean
		{
			var cost:uint = options[op * 2 + 2];
			var type:uint = Main.data.dialogues[dialogue][lineOn * 2 + 1];
			if (type % 2 == 0)
				return coins >= cost;
			else
				return ingots >= cost;
		}
		
		private function npcDialogueControl():void
		{
			targetPoint = talkingTo.position;
			
			if (dialogue == Database.NONE)
			{
				//pick a dialogue to start with
				if (talkedTo[talkingTo.dialoguePackage])
				{
					//get a normal talk line
					var dpck:Array = Main.data.dialoguePackages[talkingTo.dialoguePackage];
					var pick:uint = 4 + ((dpck.length - 4) * Math.random());
					startDialogue(dpck[pick]);
				}
				else
				{
					talkedTo[talkingTo.dialoguePackage] = true;
					startDialogue(Main.data.dialoguePackages[talkingTo.dialoguePackage][1]);
				}
			}
			
			if (options)
			{
				var opA:int = 0;
				if (Input.pressed(Key.W))
					opA -= 1;
				if (Input.pressed(Key.S))
					opA += 1;
					
				if (opA == -1 && optionOn == 0)
					optionOn = (options.length - 1) / 2;
				else if (opA == 1 && optionOn >= (options.length - 1) / 2)
					optionOn = 0;
				else
					optionOn += opA;
			}
			
			var type:uint = Main.data.dialogues[dialogue][lineOn * 2 + 1];
			if (type == 6 || //it's a poof
				((Input.pressed(Key.E) || type == 1 || ((type == 4 || type == 5) && boughtSomething)) && lineTime >= MINLINEADVANCE && fade == 0))
			{
				if (type == 7)
					(FP.engine as Main).gameOver();
				else if (type == 6)
					talkingTo.poof(Main.data.dialogues[dialogue][lineOn * 2 + 2]);
				if (options && optionOn != (options.length - 1) / 2 && (type < 4 || !boughtSomething))
				{
					//attempt to purchase something!
					var it:uint = options[optionOn * 2 + 1];
					var cost:uint = options[optionOn * 2 + 2];
					if ((type == 2 || type == 3) && canAfford(optionOn) && pickUp(it, false))
					{
						if (type == 2)
							coins -= cost;
						else
							ingots -= cost;
							
						boughtSomething = true;
					}
					else if (type == 4 && canAfford(optionOn))
					{
						coins -= cost;
						maxHealth += it;
						health = maxHealth;
						boughtSomething = true;
					}
					else if (type == 5 && canAfford(optionOn))
					{
						ingots -= cost;
						rawSpeed += it;
						boughtSomething = true;
					}
				}
				else
				{
					var goToAfterBuy:Boolean = options != null;
					
					var str:String = dialogueLine;
					if (str && lineTime < str.length)
						lineTime = str.length;
					else
					{				
						//advance dialogue
						lineOn += 1;
						lineTime = 0;
						
						if (lineOn >= ((Main.data.dialogues[dialogue] as Array).length - 1) / 2)
						{
							//dialogue is over
							if (goToAfterBuy)
							{
								//get the after-purchase dialogue right now
								if (boughtSomething)
									startDialogue(Main.data.dialoguePackages[talkingTo.dialoguePackage][2]);
								else
									startDialogue(Main.data.dialoguePackages[talkingTo.dialoguePackage][3]);
							}
							else
								talkingTo = null;
							return;
						}
					}
				}
			}
		}
		
		private function get dialogueLine():String
		{
			var type:uint = Main.data.dialogues[dialogue][lineOn * 2 + 1];
			var data:uint = Main.data.dialogues[dialogue][lineOn * 2 + 2];
			
			if (type != 0)
				return null;
			else
			{
				var line:String = Main.data.lines[data];
				
				//format it
				var formatted:String = "";
				for (var i:uint = 0; i < line.length; )
				{
					var char:String = line.charAt(i);
					if (char == "[") //gender-specific pattern
					{
						var maleString:String = "";
						var femaleString:String = "";
						
						for (i += 1;; i++)
						{
							var mC:String = line.charAt(i);
							if (mC == "/")
								break; //done
							else
								maleString += mC;
						}
						for (i += 1;; i++)
						{
							var fC:String = line.charAt(i);
							if (fC == "]")
								break; //done
							else
								femaleString += fC;
						}
						
						if (talkingTo.gender == 0)
							formatted += maleString;
						else
							formatted += femaleString;
						i += 1;
					}
					else if (char == "*") //special pattern
					{
						var code:String = line.charAt(i + 1);
						if (code == "n")
							formatted += "\n\n";
						i += 3;
					}
					else
					{
						//normal character
						formatted += char;
						i++;
					}
				}
				
				return formatted;
			}
		}
		
		private function get options():Array
		{
			var type:uint = Main.data.dialogues[dialogue][lineOn * 2 + 1];
			var data:uint = Main.data.dialogues[dialogue][lineOn * 2 + 2];
			switch(type)
			{
			case 2:
			case 3:
			case 4:
			case 5:
				return Main.data.inventories[data];
			default:
				return null;
			}
			
		}
		
		public function get fade():Number
		{
			if (dialogue == Database.NONE)
				return 0;
			var type:uint = Main.data.dialogues[dialogue][lineOn * 2 + 1];
			if (type == 1)
			{
				if (lineTime < HALFFADE1)
					return lineTime / HALFFADE1;
				else if (lineTime < HALFFADE1 + FADEHOLD)
					return 1;
				else if (lineTime < HALFFADE2 + HALFFADE1 + FADEHOLD)
					return 1 - ((lineTime - HALFFADE1 - FADEHOLD) / HALFFADE2);
				else
					return 0;
			}
			else
				return 0;
		}
		
		public function get fadeColor():uint
		{
			return Main.data.dialogues[dialogue][lineOn * 2 + 2];
		}
		
		private function startDialogue(dia:uint):void
		{
			dialogue = dia;
			lineOn = 0;
			lineTime = 0;
			optionOn = 0;
			boughtSomething = false;
		}
		
		public function get forceWalking():Boolean { return forceWalk != null; }
		
		override public function update():void 
		{
			if (dying)
			{
				super.update();
				return;
			}
			
			lineTime += LINESPEED * FP.elapsed;
			bombTimer -= FP.elapsed;
			
			if (talkingTo)
			{
				npcDialogueControl();
				super.update();
				return;
			}
			
			var xR:uint = position.x / Level.ROOMWIDTH;
			var yR:uint = position.y / Level.ROOMHEIGHT;
			xR *= Level.ROOMWIDTH;
			yR *= Level.ROOMHEIGHT;
			if (!forceWalk)
			{
				if (position.x < xR + Level.TILESIZE)
					forceWalk = new Point(-1, 0);
				else if (position.x > xR + Level.ROOMWIDTH - Level.TILESIZE)
					forceWalk = new Point(1, 0);
				else if (position.y < yR + Level.TILESIZE)
					forceWalk = new Point(0, -1);
				else if (position.y > yR + Level.ROOMHEIGHT - Level.TILESIZE)
					forceWalk = new Point(0, 1);
			}
			
			if (position.x > xR + Level.TILESIZE + FORCEWALKMARGIN &&
				position.x < xR + Level.ROOMWIDTH - Level.TILESIZE - FORCEWALKMARGIN &&
				position.y > yR + Level.TILESIZE + FORCEWALKMARGIN &&
				position.y < yR + Level.ROOMHEIGHT - Level.TILESIZE - FORCEWALKMARGIN) //you are too far in to forcewalk
				forceWalk = null;
			
			if (forceWalk)
			{
				//face that direction temporarily
				targetPoint = new Point(forceWalk.x, forceWalk.y);
				targetPoint.normalize(100);
				targetPoint.x += position.x;
				targetPoint.y += position.y;
				
				//walk that direction too
				if (!move(forceWalk))
					forceWalk = null; //you were blocked, so stop
				super.update();
				return;
			}
			
			targetPoint = new Point(Input.mouseX + FP.camera.x, Input.mouseY + FP.camera.y);
			
			var xA:int = 0;
			var yA:int = 0;
			if (Input.check(Key.W))
				yA -= 1;
			if (Input.check(Key.S))
				yA += 1;
			if (Input.check(Key.A))
				xA -= 1;
			if (Input.check(Key.D))
				xA += 1;
			if (xA != 0 || yA != 0)
				move(new Point(xA, yA));
			
			if (Input.mouseDown && (FP.world as Level).isActiveEnemy)
				attack();
			
			if (Input.pressed(Key.Q))
				switchWeapon();
			else if (Input.pressed(Key.DIGIT_1) && canSave)
			{
				//save game
				(FP.engine as Main).save();
			}
			else if (ammo[0] > 0 && Input.pressed(Key.B) && attackAnim == -1 && bombTimer <= 0 && (FP.world as Level).isActiveEnemy)
			{
				ammo[0] -= 1;
				bombTimer = BOMBCOOLDOWN;
				(FP.world as Level).addProjectile(new Projectile(BOMBDAMAGE, 0, new Point(position.x, position.y - WEAPONDROPHEIGHT), null, false));
			}
			else
			{
				var autoPick:Boolean = !Input.pressed(Key.E);
				if (!pickUpOuter(autoPick) && !autoPick)
				{
					//try to talk to NPCs
					var crs:Array = (FP.world as Level).getCreaturesAround(position);
					for (var i:uint = 0; i < crs.length; i++)
					{
						var cr:Creature = crs[i];
						if (cr != this)
						{
							var ai:AI = cr as AI;
							if (ai.isNPC && (new Point(ai.position.x - position.x, ai.position.y - position.y)).length <= TALKDISTANCE)
							{
								talkingTo = ai;
								dialogue = Database.NONE;
								break;
							}
						}
					}
				}
			}
			
			super.update();
		}
		
		private function get endShopName():String
		{
			if (boughtSomething && Main.data.dialogues[dialogue][lineOn * 2 + 1] < 4)
				return "Done";
			else
				return "Nevermind";
		}
		
		private function get textBoxHeight():uint
		{
			if (options)
				return (((options.length - 1) / 2) + 2) * 2 * UIAMMOOFF;
			else
				return TEXTHEIGHT;
		}
		
		public function getItemDrop(table:uint):uint
		{
			var tbl:Array = Main.data.inventories[table];
			
			//tally up the tickets
			var tTickets:uint = 0;
			var tickets:Array = new Array();
			for (var i:uint = 0; i < (tbl.length - 1) / 2; i++)
			{
				var it:uint = tbl[i * 2 + 1];
				//check the type
				var type:uint = Main.data.items[it][1];
				if ((type != 2 || //it's not ammo
					(ammoNotFull(it) && //you aren't full on that ammo type
					hasWeaponThatUses(it))) && //you have a use for that type
					!alreadyEquipped(it)) //you don't have one on already
				{
					var tic:uint = tbl[i * 2 + 2];
					tickets.push(tic);
					tTickets += tic;
				}
				else
					tickets.push(0); //no tickets for this
			}
			
			var pick:uint = Math.random() * tTickets;
			for (i = 0; i < tickets.length; i++)
			{
				tic = tickets[i];
				if (pick <= tic && tic > 0)
					return tbl[i * 2 + 1];
				pick -= tic;
			}
			
			trace("Drop pick malfunction.");
			return Database.NONE; //there was a malfunction?
		}
		
		private function alreadyEquipped(item:uint):Boolean
		{
			var type:uint = Main.data.items[item][1];
			var cor:uint = Main.data.items[item][4];
			if (type == 3)
			{
				if (altWeapon == cor)
					return true; //is it your alt weapon?
				tempSwitch();
				var mainCor:Boolean = altWeapon == cor;
				tempSwitch();
				return mainCor; //is it your main weapon?
			}
			else if (type == 4)
				return chestArmor == cor || legArmor == cor || footArmor == cor || faceArmor == cor;
			else
				return false; //it's not an equipment item
		}
		
		public function ammoNotFull(ammoType:uint):Boolean
		{
			return ammo[ammoType] + Main.data.items[ammoType][2] <= Main.data.items[ammoType][3];
		}
		
		public function hasWeaponThatUses(ammoType:uint):Boolean
		{
			if (ammoType == 0)
				return true; //you can always use bombs
			if (weaponAmmoType == ammoType)
				return true;
			var oUses:Boolean = false;
			if (altWeapon != Database.NONE)
			{
				tempSwitch();
				oUses = weaponAmmoType == ammoType;
				tempSwitch();
			}
			return oUses;
		}
		
		public override function renderUI():void
		{
			super.renderUI();
			
			var x:Number = BARWIDTH + BARMARGIN * 2 + BARBORDER * 2;
			var y:Number = FP.height - UIAMMOOFF - BARMARGIN;
			for (var i:uint = 1; i < ammo.length; i++)
				x = drawAmmo(x, y, i);
			x = drawAmmo(x, y, 0);
			x = drawAmmo(x, y, 3, coins);
			drawAmmo(x, y, 4, ingots);
			
			if (talkingTo && dialogue != Database.NONE && fade == 0)
			{
				var type:uint = Main.data.dialogues[dialogue][lineOn * 2 + 1];
				//draw the dialogue box
				FP.buffer.fillRect(new Rectangle(FP.halfWidth - TEXTWIDTH / 2 - TEXTBORDER, FP.halfHeight - textBoxHeight / 2 - TEXTBORDER,
												TEXTWIDTH + 2 * TEXTBORDER, textBoxHeight + 2 * TEXTBORDER), BARBORDERCOLOR);
				FP.buffer.fillRect(new Rectangle(FP.halfWidth - TEXTWIDTH / 2, FP.halfHeight - textBoxHeight / 2,
												TEXTWIDTH, textBoxHeight), TEXTBACKCOLOR);
				
				switch(type)
				{
				case 0:
					//write the dialogue line
					var str:String = dialogueLine;
					if (str.length > lineTime)
						str = str.substr(0, lineTime);
					var txt:Text = new Text(str);
					txt.wordWrap = true;
					txt.width = TEXTWIDTH;
					txt.height = textBoxHeight;
					txt.color = UITEXTCOLOR;
					txt.render(FP.buffer, new Point(FP.halfWidth - TEXTWIDTH / 2, FP.halfHeight - textBoxHeight / 2), new Point(0, 0));
					break;
				case 2:
				case 3:
				case 4:
				case 5:
					//show the shop items
					var shX:Number = FP.halfWidth - TEXTWIDTH / 2 + UIAMMOOFF;
					var chX:Number = FP.halfWidth + TEXTWIDTH / 2 - UIAMMOOFF;
					var shY:Number = FP.halfHeight - textBoxHeight / 2;
					for (i = 0; i < (options.length - 1) / 2; i++)
					{
						var it:uint = options[i * 2 + 1];
						if (type == 2 || type == 3)
							txt = new Text(Main.data.lines[Main.data.items[it][8]]);
						else if (type == 4)
							txt = new Text("Max Health +" + Math.floor(it * 100 / maxHealth) + "%");
						else
							txt = new Text("Speed +" + Math.floor(it * 100 / rawSpeed) + "%");
						if (i == optionOn)
							txt.color = UITEXTCOLORSELECTED;
						else
							txt.color = UITEXTCOLOR;
						txt.render(FP.buffer, new Point(shX + UIAMMOOFF, shY), new Point(0, 0));
						if (type == 2 || type == 3)
							Level.drawItem(new Point(shX, shY + UIAMMOOFF), it);
						
						//draw cost
						var cost:uint = options[i * 2 + 2];
						var cAdd:String = "";
						if (cost < 10)
							cAdd = "0";
						txt = new Text("costs " + cAdd + cost);
						if (!canAfford(i))
							txt.color = UITEXTCOLORBAD;
						else if (i == optionOn)
							txt.color = UITEXTCOLORSELECTED;
						else
							txt.color = UITEXTCOLOR;
						txt.render(FP.buffer, new Point(chX - UIAMMOOFF - txt.width, shY), new Point(0, 0));
						if (type % 2 == 0)
							Level.drawItem(new Point(chX, shY + UIAMMOOFF), 3);
						else
							Level.drawItem(new Point(chX, shY + UIAMMOOFF), 4);
						
						shY += 2 * UIAMMOOFF;
					}
					txt = new Text(endShopName);
					if (optionOn == (options.length - 1) / 2)
						txt.color = UITEXTCOLORSELECTED;
					else
						txt.color = UITEXTCOLOR;
					txt.render(FP.buffer, new Point(shX + UIAMMOOFF, shY), new Point(0, 0));
					
					shY += 2 * UIAMMOOFF;
					
					//draw money total
					var amount:uint;
					if (type % 2 == 0)
						amount = coins;
					else
						amount = ingots;
					cAdd = "";
					if (amount < 10)
						cAdd = "00";
					else if (amount < 100)
						cAdd = "0";
					txt = new Text("have " + cAdd + amount);
					txt.color = UITEXTCOLOR;
					txt.render(FP.buffer, new Point(chX - UIAMMOOFF - txt.width, shY), new Point(0, 0));
					if (type % 2 == 0)
						Level.drawItem(new Point(chX, shY + UIAMMOOFF), 3);
					else
						Level.drawItem(new Point(chX, shY + UIAMMOOFF), 4);
					
					break;
				}
			}
		}
		
		private function pickUpOuter(autoPick:Boolean):Boolean
		{
			//pick up item
			var its:Array = (FP.world as Level).itemsArray;
			var pickDis:uint = PICKUPDISTANCE;
			if (autoPick)
				pickDis = AUTOPICKUPDISTANCE;
			for (var i:uint = 0; i < its.length / 3; i++)
			{
				var pos:Point = its[i * 3];
				var dif:Point = new Point(pos.x - position.x, pos.y - position.y);
				if (dif.length <= pickDis)
				{
					if (pickUp(its[i * 3 + 1], true, autoPick))
					{
						//you picked it up, so remove it
						for (; i < its.length / 3 - 1; i++)
						{
							its[i * 3] = its[i * 3 + 3];
							its[i * 3 + 1] = its[i * 3 + 4];
							its[i * 3 + 2] = its[i * 3 + 5];
						}
						its.pop();
						its.pop();
						its.pop();
						return true;
					}
				}
			}
			
			return false;
		}
	}

}