package;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;
import Controls.Control;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.util.FlxColor;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> =[
		'Resume Song',
		'Restart Song',
		'Change Difficulty',
		'Toggle Practice Mode',
		'Return to Menu'
	];
	
	var difficultyChoices:Array<String> = [
		'EASY', 
		'NORMAL',
		'HARD', 
		'BACK'
	];

	var curSelected:Int = 0;

	var pauseMusic:FlxSound;

	var practiceText:FlxText;

	public function new(x:Float, y:Float)
	{
		super();

		pauseMusic = new FlxSound().loadEmbedded('assets/music/breakfast' + TitleState.soundExt, true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		bg.scrollFactor.set();
		add(bg);

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		regenMenu();

		changeSelection();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		var levelInfo:FlxText = new FlxText(20, 15, 0, "", 32);
		levelInfo.text += PlayState.SONG.song;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat("assets/fonts/vcr.ttf", 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text += PlayState.songDifficulty;
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat("assets/fonts/vcr.ttf", 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		var deathCounter:FlxText = new FlxText(20, 15 + 64, 0, "", 32);
		deathCounter.text = "Blue balled: " + PlayState.deathCounter;
		deathCounter.scrollFactor.set();
		deathCounter.setFormat("assets/fonts/vcr.ttf", 32);
		deathCounter.updateHitbox();
		add(deathCounter);

		practiceText = new FlxText(20, 15 + 64 + 32, 0, "PRACTICE MODE", 32);
		practiceText.scrollFactor.set();
		practiceText.setFormat("assets/fonts/vcr.ttf", 32);
		practiceText.updateHitbox();
		practiceText.x = FlxG.width - (practiceText.width + 20);
		practiceText.visible = PlayState.practiceMode;
		add(practiceText);

		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;
		deathCounter.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		deathCounter.x = FlxG.width - (deathCounter.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(deathCounter, {alpha: 1, y: deathCounter.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});
	}

	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		if (accepted)
		{
			var daSelected:String = menuItems[curSelected];

			switch (daSelected)
			{
				case "Resume Song":
					close();
					
				case "Restart Song":
					FlxG.resetState();

				case 'Change Difficulty':
					menuItems = difficultyChoices;
					regenMenu();

				case 'Toggle Practice Mode':
					PlayState.practiceMode = !PlayState.practiceMode;
					practiceText.visible = PlayState.practiceMode;

				case "Return to Menu":
					if (PlayState.isStoryMode)
						FlxG.switchState(new StoryMenuState());
					else
						FlxG.switchState(new FreeplayState());

				case "EASY" | 'NORMAL' | "HARD":
					PlayState.SONG = Song.loadFromJson(Highscore.formatSong(PlayState.SONG.song.toLowerCase(), curSelected),
					PlayState.SONG.song.toLowerCase());
		
					PlayState.storyDifficulty = curSelected;
					PlayState.songDiffInt = curSelected;
		
					FlxG.resetState();

				case 'BACK':
					//menuItems = menuItems;
					regenMenu();
			}
		}
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}
	}

	private function regenMenu():Void
		{
			while (grpMenuShit.members.length > 0)
			{
				grpMenuShit.remove(grpMenuShit.members[0], true);
			}
	
			for (i in 0...menuItems.length)
			{
				var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
				songText.isMenuItem = true;
				songText.targetY = i;
				grpMenuShit.add(songText);
			}
	
			curSelected = 0;
			changeSelection();
		}
}
