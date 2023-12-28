package;

import flixel.FlxGame;
import openfl.display.FPS;
import openfl.display.Sprite;
import flixel.FlxG;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, TitleState, 60, 60, true));

		#if !mobile
		addChild(new FPS(3, 3, 0xFFFFFF));
		#end
	}
}
