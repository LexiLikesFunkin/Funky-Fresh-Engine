package optionsStuff;

import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

class ExtrasOptionsState extends MusicBeatState
{
	var menuItems:Array<String> = ['Changelog'];
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var curSelected:Int = 0;
	var gtText:FlxText;
	
	override function create()
	{
		super.create();

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.menuDesat__png);
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		for (i in 0...menuItems.length)
			{
				var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
				songText.screenCenter(X);
				songText.isMenuItem = true;
				songText.targetY = i;
				grpMenuShit.add(songText);
			}
		changeSelection();

		gtText = new FlxText(5, FlxG.height - 18, 0, "", 12);
		gtText.scrollFactor.set();
		gtText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(gtText);
		gtText.text = "";

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		if (controls.UP_P)
			changeSelection(-1);
		if (controls.DOWN_P)
			changeSelection(1);
		if (controls.BACK)
			FlxG.switchState(new OptionsMenu());
			var daSelected:String = menuItems[curSelected];

		switch (daSelected) {
            case 'Changelog':
				FlxG.switchState(new ChangelogState());
		}
		super.update(elapsed);
	}
	
	function changeSelection(change:Int = 0):Void
        {
            curSelected = FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);
        
            for (i in 0...grpMenuShit.length)
            {
                var item = grpMenuShit.members[i];
                item.targetY = i - curSelected;
                item.alpha = item.targetY == 0 ? 1 : 0.6;
            }
        }
}
