package;

import flixel.FlxGame;
import openfl.display.FPS;
import openfl.display.Sprite;
import flixel.FlxG;
import handlers.LogHandler;

class Main extends Sprite
{
	static public var log:LogHandler;
	
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, TitleState, 60, 60, true));

		addChild(log = new LogHandler());

		#if !mobile
		addChild(new FPS(3, 3, 0xFFFFFF));
		#end
	}
}
