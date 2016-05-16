package game
{
	import net.flashpunk.graphics.Spritemap;
	import net.flashpunk.Sfx;
	public class Database 
	{
		//sprites
		[Embed(source = "sprites/bodySheet.png")] private static const SPR1:Class;
		[Embed(source = "sprites/armSheet.png")] private static const SPR2:Class;
		[Embed(source = "sprites/weaponSheet.png")] private static const SPR3:Class;
		[Embed(source = "sprites/legSheet.png")] private static const SPR4:Class;
		[Embed(source = "sprites/headSheet.png")] private static const SPR5:Class;
		[Embed(source = "sprites/projectileSheet.png")] private static const SPR6:Class;
		[Embed(source = "sprites/itemSheet.png")] private static const SPR7:Class;
		[Embed(source = "sprites/specialSheet.png")] private static const SPR8:Class;
		[Embed(source = "sprites/tileSheet.png")] private static const SPR9:Class;
		[Embed(source = "sprites/giantBodySheet.png")] private static const SPR10:Class;
		[Embed(source = "sprites/giantLegSheet.png")] private static const SPR11:Class;
		[Embed(source = "sprites/giantArmSheet.png")] private static const SPR12:Class;
		[Embed(source = "sprites/giantHeadSheet.png")] private static const SPR13:Class;
		[Embed(source = "sprites/giantWeaponSheet.png")] private static const SPR14:Class;
		[Embed(source = "sprites/giantProjectileSheet.png")] private static const SPR15:Class;
		
		//sound effects
		[Embed(source = "sounds/209399__samulis__bow-release.mp3")] private static const SND1:Class;
		[Embed(source = "sounds/219002__yap-audio-production__weaponswipe01.mp3")] private static const SND2:Class;
		[Embed(source = "sounds/219004__yap-audio-production__weaponswipe02.mp3")] private static const SND3:Class;
		[Embed(source = "sounds/219005__yap-audio-production__weaponswipe03.mp3")] private static const SND4:Class;
		[Embed(source = "sounds/155235__zangrutz__bomb-small.mp3")] private static const SND5:Class;
		[Embed(source = "sounds/167274__hoscalegeek__fuse-igniting-and-burning-imitated.mp3")] private static const SND6:Class;
		[Embed(source = "sounds/223611__ctcollab__fire-ball-release.mp3")] private static const SND7:Class;
		[Embed(source = "sounds/119451__lmbubec__golf-ball-putt.mp3")] private static const SND8:Class;
		[Embed(source = "sounds/218463__yap-audio-production__arrowhit02.mp3")] private static const SND9:Class;
		[Embed(source = "sounds/218464__yap-audio-production__arrowhit01.mp3")] private static const SND10:Class;
		[Embed(source = "sounds/90782__kmoon__bullet-flyby-2.mp3")] private static const SND11:Class;
		[Embed(source = "sounds/90783__kmoon__bullet-flyby-3.mp3")] private static const SND12:Class;
		[Embed(source = "sounds/90784__kmoon__bullet-flyby-4.mp3")] private static const SND13:Class;
		[Embed(source = "sounds/195952__minian89__swing-blood-splatter.mp3")] private static const SND14:Class;
		[Embed(source = "sounds/159655__lolamadeus__watermelon-splat1.mp3")] private static const SND15:Class;
		[Embed(source = "sounds/55234__slykmrbyches__splattt.mp3")] private static const SND16:Class;
		[Embed(source = "sounds/13863__adcbicycle__11.mp3")] private static const SND17:Class;
		
		//files
		[Embed(source = "data/data.txt", mimeType = "application/octet-stream")] private static const DATA:Class;
		[Embed(source="data/lines.txt", mimeType = "application/octet-stream")] private static const LINES:Class;
		
		public static const NONE:uint = 999999999;
		public var lines:Array = new Array();
		public var spriteSheets:Array = new Array();
		public var soundEffects:Array = new Array();
		private var sheets:Array = new Array();
		private var sounds:Array = new Array();
		
		//other lists
		public var weapons:Array = new Array();
		public var features:Array = new Array();
		public var pieces:Array = new Array();
		public var featureLists:Array = new Array();
		public var races:Array = new Array();
		public var tiles:Array = new Array();
		public var projectiles:Array = new Array();
		public var crimes:Array = new Array();
		public var armors:Array = new Array();
		public var dialogues:Array = new Array();
		public var dialogueTypes:Array = new Array();
		public var dialoguePackages:Array = new Array();
		public var soundPacks:Array = new Array();
		public var inventories:Array = new Array();
		public var armorSlots:Array = new Array();
		public var tilesets:Array = new Array();
		public var aiPackages:Array = new Array();
		public var difficulties:Array = new Array();
		public var items:Array = new Array();
		public var lengthSettings:Array = new Array();
		public var encounters:Array = new Array();
		public var itemTypes:Array = new Array();
		public var progressions:Array = new Array();
		public var classes:Array = new Array();
		
		public function Database() 
		{
			//read lines
			var lineNames:Array = new Array();
			var data:Array = new LINES().toString().split("\n");
			for (var i:uint = 0; i < data.length - 1; i++)
			{
				var line:String = data[i];
				if (line.charAt(0) != "/")
				{
					var lineName:String = "";
					var lineContent:String = "";
					var onName:Boolean = true;
					for (var j:uint = 0; j < line.length - 1; j++)
					{
						if (onName && line.charAt(j) == " ")
							onName = false;
						else if (onName)
							lineName += line.charAt(j);
						else
							lineContent += line.charAt(j);
					}
					lineNames.push(lineName);
					lines.push(lineContent);
				}
			}
			
			//read data
			
			data = new DATA().toString().split("\n");
			
			//analyze data
			var allArrays:Array = new Array();
			//remember to push each data array into allarrays
			//if you don't put something into allArrays, it won't be linked with anything
			
			allArrays.push(sheets);
			allArrays.push(sounds);
			//other lists
			allArrays.push(weapons);
			allArrays.push(features);
			allArrays.push(pieces);
			allArrays.push(inventories);
			allArrays.push(tilesets);
			allArrays.push(encounters);
			allArrays.push(tiles);
			allArrays.push(lengthSettings);
			allArrays.push(dialogues);
			allArrays.push(aiPackages);
			allArrays.push(progressions);
			allArrays.push(dialoguePackages);
			allArrays.push(dialogueTypes);
			allArrays.push(armors);
			allArrays.push(armorSlots);
			allArrays.push(crimes);
			allArrays.push(projectiles);
			allArrays.push(featureLists);
			allArrays.push(races);
			allArrays.push(classes);
			allArrays.push(itemTypes);
			allArrays.push(items);
			allArrays.push(soundPacks);
			allArrays.push(difficulties);
			
			var arrayOn:Array;
			for (i = 0; i < data.length; i++)
			{
				line = data[i];
				line = line.substr(0, line.length - 1);
				if (line.charAt(0) != "/")
				{
					switch(line)
					{
					case "SHEET:":
						arrayOn = sheets;
						break;
					case "ARMOR:":
						arrayOn = armors;
						break;
					case "ENCOUNTER:":
						arrayOn = encounters;
						break;
					case "ARMORSLOT:":
						arrayOn = armorSlots;
						break;
					case "WEAPON:":
						arrayOn = weapons;
						break;
					case "SOUNDPACK:":
						arrayOn = soundPacks;
						break;
					case "SOUND:":
						arrayOn = sounds;
						break;
					case "DIFFICULTY:":
						arrayOn = difficulties;
						break;
					case "CLASS:":
						arrayOn = classes;
						break;
					case "ITEMTYPE:":
						arrayOn = itemTypes;
						break;
					case "TILESET:":
						arrayOn = tilesets;
						break;
					case "TILE:":
						arrayOn = tiles;
						break;
					case "CRIME:":
						arrayOn = crimes;
						break;
					case "ITEM:":
						arrayOn = items;
						break;
					case "INVENTORY:":
						arrayOn = inventories;
						break;
					case "LENGTHSETTING:":
						arrayOn = lengthSettings;
						break;
					case "PROJECTILE:":
						arrayOn = projectiles;
						break;
					case "PROGRESSION:":
						arrayOn = progressions;
						break;
					case "FEATURELIST:":
						arrayOn = featureLists;
						break;
					case "AIPACKAGE:":
						arrayOn = aiPackages;
						break;
					case "DIALOGUE:":
						arrayOn = dialogues;
						break;
					case "DIALOGUEPACKAGE:":
						arrayOn = dialoguePackages;
						break;
					case "DIALOGUETYPE:":
						arrayOn = dialogueTypes;
						break;
					case "RACE:":
						arrayOn = races;
						break;
					case "PIECE:":
						arrayOn = pieces;
						break;
					case "FEATURE:":
						arrayOn = features;
						break;
					case "FILLERDATA:":
						arrayOn = new Array();
						break;
					default:
						//tbis is a data line
						var ar:Array = line.split(" ");
						var newEntry:Array = new Array();
						for (j = 0; j < ar.length; j++)
						{
							//see if it's a string or a number
							if (j == 0)
								newEntry.push(ar[j]); //it's the name
							else if (ar[j] == "none") //it's an empty reference
								newEntry.push(NONE);
							else if (ar[j] == "true")
								newEntry.push(1);
							else if (ar[j] == "false")
								newEntry.push(0);
							else if (isNaN(ar[j]))
							{
								var st:String = ar[j] as String;
								if (st.charAt(0) == "@") //it's a line!
								{
									if (ar[j] == "@none") //it's an empty line
										newEntry.push(NONE);
									else
									{
										//find the line
										var foundLine:Boolean = false;
										for (var k:uint = 0; k < lineNames.length; k++)
											if ("@" + lineNames[k] == ar[j])
											{
												foundLine = true;
												newEntry.push(k);
												break;
											}
										if (!foundLine)
										{
											trace("Unable to find line " + ar[j]);
											newEntry.push(NONE);
										}
									}
								}
								else
									newEntry.push(st);
							}
							else
								newEntry.push((int) (ar[j]));
						}
						//push the finished list
						arrayOn.push(newEntry);
						break;
					}
				}
			}
			
			//link them
			link(allArrays);
			
			//link up sound effects
			for (i = 0; i < sounds.length; i++)
			{
				var SRC:Class;
				switch(i)
				{
				case 0:
					SRC = SND1;
					break;
				case 1:
					SRC = SND2;
					break;
				case 2:
					SRC = SND3;
					break;
				case 3:
					SRC = SND4;
					break;
				case 4:
					SRC = SND5;
					break;
				case 5:
					SRC = SND6;
					break;
				case 6:
					SRC = SND7;
					break;
				case 7:
					SRC = SND8;
					break;
				case 8:
					SRC = SND9;
					break;
				case 9:
					SRC = SND10;
					break;
				case 10:
					SRC = SND11;
					break;
				case 11:
					SRC = SND12;
					break;
				case 12:
					SRC = SND13;
					break;
				case 13:
					SRC = SND14;
					break;
				case 14:
					SRC = SND15;
					break;
				case 15:
					SRC = SND16;
					break;
				case 16:
					SRC = SND17;
					break;
				}
				
				var snd:Sfx = new Sfx(SRC);
				soundEffects.push(snd);
			}
			
			//load up spritesheets
			for (i = 0; i < sheets.length; i++)
			{
				switch(i)
				{
				case 0:
					SRC = SPR1;
					break;
				case 1:
					SRC = SPR2;
					break;
				case 2:
					SRC = SPR3;
					break;
				case 3:
					SRC = SPR4;
					break;
				case 4:
					SRC = SPR5;
					break;
				case 5:
					SRC = SPR6;
					break;
				case 6:
					SRC = SPR7;
					break;
				case 7:
					SRC = SPR8;
					break;
				case 8:
					SRC = SPR9;
					break;
				case 9:
					SRC = SPR10;
					break;
				case 10:
					SRC = SPR11;
					break;
				case 11:
					SRC = SPR12;
					break;
				case 12:
					SRC = SPR13;
					break;
				case 13:
					SRC = SPR14;
					break;
				case 14:
					SRC = SPR15;
					break;
				}
				
				var spr:Spritemap = new Spritemap(SRC, sheets[i][1], sheets[i][2]);
				spriteSheets.push(spr);
			}
		}
		
		private function link(allArrays:Array):void
		{
			for (var i:uint = 0; i < allArrays.length; i++)
			{
				var arrayOn:Array = allArrays[i];
				
				for (var j:uint = 0; j < arrayOn.length; j++)
				{
					var entry:Array = arrayOn[j];
					
					for (var k:uint = 1; k < entry.length; k++)
					{
						if (isNaN(entry[k]))
						{
							var st:String = entry[k] as String;
							if (st.charAt(0) == "#") //it's a literal word
							{
								var newSt:String = "";
								for (var l:uint = 1; l < st.length; l++)
								{
									if (st.charAt(l) == "#")
										newSt += " ";
									else
										newSt += st.charAt(l);
								}
								entry[k] = newSt;
							}
							else
							{
								//link it somewhere
								
								var found:Boolean = false;
								for (l = 0; l < allArrays.length && !found; l++)
								{
									var arrayCheck:Array = allArrays[l];
									
									for (var m:uint = 0; m < arrayCheck.length; m++)
									{
										if (arrayCheck[m][0] == st)
										{
											entry[k] = m;
											found = true;
											break;
										}
									}
								}
								
								if (!found)
									trace("Unable to find " + entry[k]);
							}
						}
					}
				}
			}
		}
	}

}