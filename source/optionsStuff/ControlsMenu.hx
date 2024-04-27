package optionsStuff;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxColor;

class ControlsMenu extends MusicBeatState
{
    var controlsList:FlxText;

    override function create()
    {
        super.create();

        var menuBG:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.menuDesat__png);
        menuBG.color = 0xff7173fd;
        menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
        menuBG.updateHitbox();
        menuBG.screenCenter();
        menuBG.antialiasing = true;
        add(menuBG);

        controlsList = new FlxText(5, FlxG.height - 18, 0, '', 12);
        controlsList.scrollFactor.set();
        controlsList.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(controlsList);
    }
}

inline function get_controls()
    return PlayerSettings.player1.controls;