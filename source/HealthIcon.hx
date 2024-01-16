package;

import openfl.Assets;
import flixel.FlxSprite;
import handlers.Files;

using StringTools;

class HealthIcon extends FlxSprite {
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	public var char:String;
	public var isPlayer:Bool = false;

	public function new(char:String = 'bf', isPlayer:Bool = false) {
		super();
		this.isPlayer = isPlayer;
		changeIcon(char);
		antialiasing = true;
		scrollFactor.set();
	}

	public function changeIcon(char:String) {
		if (char != this.char) {
			if (!Assets.exists(Files.image('characters/$char/icon-$char')) || char == null)
				loadGraphic(Files.image('icons/icon-face'), true, 150, 150);
			else
				loadGraphic(Files.image('characters/$char/icon-$char'), true, 150, 150);

			animation.add(char, [0, 1], 0, false, isPlayer);
		}
		animation.play(char);
		this.char = char;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
