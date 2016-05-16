package game
{
	import flash.geom.Point;
	import net.flashpunk.Engine;
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.Sfx;
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	import flash.net.SharedObject;
	import net.flashpunk.World;
	
	public class Main extends Engine
	{
		public static const data:Database = new Database();
		private var profile:SharedObject;
		
		//menu data
		private var menuOn:uint;
		private var menuItemOn:uint;
		private var menuData:Array;
		private var canLoad:Boolean;
		private var lvl:Level;
		
		public function Main():void 
		{
			super (Level.ROOMWIDTH, Level.ROOMHEIGHT);
			
			reload();
		}
		
		public static function playSound(pack:uint):void
		{
			if (pack == Database.NONE)
				return;
			
			var pck:Array = Main.data.soundPacks[pack];
			var vol:uint = pck[1];
			var pick:uint = (pck.length - 2) * Math.random() + 2;
			(Main.data.soundEffects[pck[pick]] as Sfx).play(vol * 0.01);
		}
		
		private function reload():void
		{
			menuOn = 0; //main menu
			menuItemOn = 0;
			lvl = null;
			menuData = null;
			
			loadProfile("savefile");
			canLoad = profile.data.contents.length > 0;
			closeProfile();
		}
		
		private function get menuLength():uint
		{
			switch(menuOn)
			{
			case 0: //main menu
				if (canLoad)
					return 2;
				return 1;
			case 1: //difficulty setting
				return 3;
			case 2: //character creation
				return 9;
			default:
				return 0;
			}
		}
		
		public override function update():void
		{
			if (menuLength > 0)
			{
				var iAdd:int = 0;
				if (Input.pressed(Key.W))
					iAdd -= 1;
				if (Input.pressed(Key.S))
					iAdd += 1;
				if (iAdd == 1 && menuItemOn == menuLength - 1)
					menuItemOn = 0;
				else if (iAdd == -1 && menuItemOn == 0)
					menuItemOn = menuLength - 1;
				else
					menuItemOn += iAdd;
					
				if (itemMax > 0)
				{
					var tAdd:int = 0;
					if (Input.pressed(Key.A))
						tAdd -= 1;
					if (Input.pressed(Key.D))
						tAdd += 1;
					if (tAdd == 1 && menuData[menuItemOn] == itemMax - 1)
						menuData[menuItemOn] = 0;
					else if (tAdd == -1 && menuData[menuItemOn] == 0)
						menuData[menuItemOn] = itemMax - 1;
					else
						menuData[menuItemOn] += tAdd;
					if (tAdd != 0 && menuOn == 2)
						reloadPlayer();
				}
					
				if (Input.pressed(Key.E))
					switch(menuOn)
					{
					case 0:
						if (menuItemOn == 0 && canLoad)
						{
							//load game
							menuOn = 3;
							loadProfile("savefile");
							lvl = new Level();
							lvl.loadLevel(profile.data.contents, 0);
							FP.world = lvl;
							//wipe save
							profile.data.contents = new Array();
							closeProfile();
						}
						else
						{
							//new game
							menuOn = 1;
							menuItemOn = 0;
							menuData = new Array();
							menuData.push(1);
							menuData.push(1);
						}
						break;
					case 1:
						if (menuItemOn == 2)
						{
							//actually generate the level
							lvl = new Level(menuData[1], menuData[0]);
							menuOn = 2;
							menuItemOn = 0;
							menuData = new Array();
							loadProfile("lastChar");
							if (profile.data.contents.length > 0)
								for (var i:uint = 0; i < profile.data.contents.length; i++)
									menuData.push(profile.data.contents[i]);
							else
							{
								menuData.push(0);
								menuData.push(0);
								menuData.push(0);
								menuData.push(0);
								menuData.push(0);
								menuData.push(0);
								menuData.push(0);
								menuData.push(0);
							}
							closeProfile();
							reloadPlayer();
						}
						break;
					case 2:
						if (menuItemOn == 8)
						{
							//save this char choice
							loadProfile("lastChar");
							profile.data.contents = new Array();
							for (i = 0; i < menuData.length; i++)
								profile.data.contents.push(menuData[i]);
							closeProfile();
							
							//null save
							if (canLoad)
							{
								loadProfile("savefile");
								profile.data.contents = new Array();
								closeProfile();
							}
							
							//start the level
							lvl.setOG();
							FP.world = lvl;
							menuOn = 3;
							menuData = null;
							lvl.playIntro();
						}
						break;
					}
			}
			
			super.update();
		}
		
		public function gameOver():void
		{
			FP.world = new World();
			
			reload();
		}
		
		private function reloadPlayer():void
		{
			lvl.player.setAppearance(menuData[0], menuData[1], menuData[2], menuData[3], menuData[4], menuData[5]);
			lvl.crime = menuData[7];
		}
		
		private function get itemMax():uint
		{
			switch(menuOn)
			{
			case 1:
				switch(menuItemOn)
				{
				case 0:
					return Main.data.difficulties.length;
				case 1:
					return Main.data.lengthSettings.length;
				}
				break;
			case 2:
				switch(menuItemOn)
				{
				case 0:
					return 2;
				case 1:
					return Main.data.featureLists[lvl.player.raceHairList].length - 1;
				case 2:
					return Main.data.featureLists[lvl.player.raceHairColorList].length - 1;
				case 3:
					return Main.data.featureLists[lvl.player.raceSkinColorList].length - 1;
				case 4:
					return Main.data.featureLists[lvl.player.raceEyeColorList].length - 1;
				case 5:
					return Main.data.featureLists[0].length - 1;
				case 6:
					return 5;
				case 7:
					return Main.data.crimes.length;
				}
				break;
			}
			return 0;
		}
		
		private function itemName(i:uint):String
		{
			switch (menuOn)
			{
			case 0:
				if (canLoad && i == 0)
					return "Continue";
				return "New Game";
			case 1:
				switch(i)
				{
				case 0:
					return "Difficulty: " + Main.data.lines[Main.data.difficulties[menuData[i]][3]];
				case 1:
					return "Map Size: " + Main.data.lines[Main.data.lengthSettings[menuData[i]][4]];
				case 2:
					return "Generate";
				}
				break;
			case 2:
				switch(i)
				{
				case 0:
					if (menuData[0] == 0)
						return "Gender: Male";
					else
						return "Gender: Female";
				case 1:
					return "Hair: " + (menuData[i] + 1);
				case 2:
					switch(menuData[i])
					{
					case 0:
						return "Hair Color: Red";
					case 1:
						return "Hair Color: Brown";
					case 2:
						return "Hair Color: Dark Brown";
					case 3:
						return "Hair Color: Black";
					}
					return "Hair Color: " + (menuData[i] + 1);
				case 3:
					return "Skin Color: " + (menuData[i] + 1);
				case 4:
					switch(menuData[i])
					{
					case 0:
						return "Eye Color: Red";
					case 1:
						return "Eye Color: Green";
					case 2:
						return "Eye Color: Blue";
					case 3:
						return "Eye Color: Orange";
					}
				case 5:
					var ht:uint = Main.data.featureLists[0][menuData[i] + 1];
					if (ht == Database.NONE)
						return "Hat: None";
					return "Hat: " + Main.data.lines[Main.data.armors[ht][7]];
				case 6:
					switch(menuData[i])
					{
					case 0:
						return "Favorite Color: Cerulean";
					case 1:
						return "Favorite Color: Periwinkle";
					case 2:
						return "Favorite Color: Powder";
					case 3:
						return "Favorite Color: Ultramarine";
					case 4:
						return "Favorite Color: Turquoise";
					}
				case 7:
					return "Crime: " + Main.data.lines[Main.data.crimes[menuData[i]][1]];
				case 8:
					return "Start Game";
				}
			}
			return "";
		}
		
		public override function render():void
		{
			super.render();
			
			if (menuOn == 2)
			{
				var oldP:Point = new Point(lvl.player.position.x, lvl.player.position.y);
				lvl.player.position.x = 50;
				lvl.player.position.y = FP.halfHeight;
				lvl.player.render();
				lvl.player.position.x = oldP.x;
				lvl.player.position.y = oldP.y;
			}
			for (var i:uint = 0; i < menuLength; i++)
			{
				var txt:Text = new Text(itemName(i));
				var hi:Number = 1 / (menuLength + 2);
				var yC:Number = FP.halfHeight * hi + FP.height * (1 + i) * hi;
				
				if (i == menuItemOn)
					txt.color = Creature.UITEXTCOLORSELECTED;
				else
					txt.color = Creature.UITEXTCOLOR;
				
				txt.render(FP.buffer, new Point(FP.halfWidth - txt.width / 2, yC - txt.height / 2), FP.zero);
			}
		}
		
		private function loadProfile(name:String):void
		{
			profile = SharedObject.getLocal(name);
			if (!profile.data.valid)
			{
				//wipe everything
				trace("Wiping save");
				
				profile.data.contents = new Array();
			}
			profile.data.valid = false;
		}
		
		private function closeProfile():void
		{
			profile.data.valid = true;
			profile.close();
			profile = null;
		}
		
		public function save():void
		{
			loadProfile("savefile");
			trace("Saving");
			(FP.world as Level).saveLevel(profile.data.contents);
			closeProfile();
			
			//close the game
			gameOver();
		}
	}
	
}