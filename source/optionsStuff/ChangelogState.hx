package optionsStuff;

import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

class ChangelogState extends MusicBeatState
{
    var text:FlxText;
	override function create()
	{
		super.create();

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.menuDesat__png);
		menuBG.color = 0xff210325;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

        text = new FlxText(0, 0, 0, "", 20);
		text.setFormat("assets/fonts/vcr.ttf", 18, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.scrollFactor.set();
		add(text);
		text.screenCenter(X);
		text.screenCenter(Y);
	}

	override function update(elapsed:Float)
	{
		if (controls.BACK)
			FlxG.switchState(new MainMenuState());
		super.update(elapsed);
        text.text = "Added:                                               
		 - Weeks 3-5                                     
		 - Small mod support (character overrides, songs)
		 - Stages are now set in the chart file          
		 - Week Rankings   
		 - This changelog menu is unfinished,
			Maybe it'll be fixed in 0.1...
			Who knows! :3                              
		 
		 Thank you for using Funky Fresh Engine!";       
	}
}
