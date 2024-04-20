package;

import openfl.filters.ShaderFilter;
import handlers.Files;
import handlers.ClientPrefs;
import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;

#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end

import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import flixel.math.FlxRect;
import NoteSplash;

import flixel.util.FlxGradient;

using StringTools;

class PlayState extends MusicBeatState
{
	var scoreTxt:FlxText;
	public static var songDifficulty:String = '';//:Int;
	public static var songDiffInt:Int;
	public static var practiceMode:Bool = false; 

	var buildNumber = BuildNumber.getBuildNumber();

	var debugTxt:FlxText; //shit for when i need to debug stuff
	var songInfo:FlxText;

	var sickTracker:Int = 0;
	var goodTracker:Int = 0;
	var badTracker:Int = 0;
	var shitTracker:Int = 0;

	var gameControls:Controls;

	public static var songAccuracy:Float = 0;

	public var coolNoteFloat:Float = 0;

	private var allNotes:Int = 0;
	private var misses:Int = 0;
	private var combo:Int = 0;

	public var ratingTxt:String;
	public var ratingColor:FlxColor;

	private var iconP1:HealthIcon;
	private var iconP2:HealthIcon;

	public static var curLevel:String = 'Tutorial';
	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int;
	public static var deathCounter:Int = 0;

	var halloweenLevel:Bool = false;
	var grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();

	private var vocals:FlxSound;

	private var dad:Character;
	private var gf:Character;
	private var boyfriend:Boyfriend;

	private var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];

	private var strumLine:FlxSprite;
	private var curSection:Int = 0;

	private var camFollow:FlxObject;
	private var strumLineNotes:FlxTypedGroup<FlxSprite>;
	private var playerStrums:FlxTypedGroup<FlxSprite>;
	private var cpuStrums:FlxTypedGroup<FlxSprite>;

	var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	private var camZooming:Bool = false;
	private var curSong:String = "";

	private var gfSpeed:Int = 1;
	private var health:Float = 1;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];

	//var halloweenBG:FlxSprite;
	var isHalloween:Bool = false;

	var talking:Bool = true;
	var songScore:Int = 0;

	public static var campaignScore:Int = 0;

	public var overlay = new FlxSprite();

	var trainSound:FlxSound;

	var defaultCamZoom:Float = 1.05;

	override public function create()
	{
		FlxG.camera.zoom = defaultCamZoom;
		overlay.makeGraphic(1280, 720, FlxColor.BLACK);
		overlay.visible == false;
		if (ClientPrefs.getOption('traditionalFunkin') == true){
			add(overlay);
			overlay.visible == false;}

		FlxG.mouse.visible = false;
		#if desktop
		DiscordClient.changePresence('Playing ' + SONG.song, '');
		#end

		gameControls.bindKeys;
		recalculateAccuracy();
		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);

		FlxCamera.defaultCameras = [camGame];

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson(curLevel);

		Conductor.changeBPM(SONG.bpm);

		switch (SONG.song.toLowerCase())
		{
			case 'tutorial':
				dialogue = ["Hey you're pretty cute.", 'Use the arrow keys to keep up \nwith me singing.'];
			case 'bopeebo':
				dialogue = [
					'HEY!',
					"You think you can just sing\nwith my daughter like that?",
					"If you want to date her...",
					"You're going to have to go \nthrough ME first!"
				];
			case 'fresh':
				dialogue = ["Not too shabby boy.", ""];
			case 'dadbattle':
				dialogue = [
					"gah you think you're hot stuff?",
					"If you can beat me here...",
					"Only then I will even CONSIDER letting you\ndate my daughter!"
				];
		}
		
		var theStage = switch (SONG.song.toLowerCase())
		{
			case "tutorial" | "bopeebo" | "fresh" | "dadbattle": "stage";
			case "spookeez" | "south" | "monster": "spooky";
			case "pico" | "philly nice" | "blammed": "philly";
			default: "stage";
		}
		theStage = (SONG.stage);
		loadStage(theStage);

		gf = new Character(400, 130, SONG.player3);
		gf.scrollFactor.set(0.95, 0.95);
		gf.antialiasing = true;
		add(gf);

		if (curStage == 'limo')
			add(limo);

		dad = new Character(100, 100, SONG.player2);
		add(dad);

		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		switch (SONG.player2)
		{
			case 'gf':
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				if (isStoryMode)
				{
					camPos.x += 600;
					tweenCamIn();
				}

			case "spooky":
				dad.y += 200;
			case "monster":
				dad.y += 100;
			case 'dad':
				camPos.x += 400;
			case 'pico':
				dad.y += 300;
			case 'parents-christmas':
				dad.x -= 500;
			case 'monster-christmas':
				dad.y += 130;
		}

		boyfriend = new Boyfriend(770, 450, SONG.player1);
		add(boyfriend);

		// Repositioning per stage
		switch (curStage)
		{
			case 'limo':
				boyfriend.y -= 220;
				boyfriend.x += 260;

				resetFastCar();
				add(fastCar);
			case 'mall':
				boyfriend.x += 200;
			case 'mallEvil':
				boyfriend.x += 320;
				//dad.y -= 80;
		}

		var doof:DialogueBox = new DialogueBox(false, dialogue);
		doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		if (ClientPrefs.getOption('downscroll') == true)
			strumLine.y = FlxG.height - 165;

		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<FlxSprite>();
		cpuStrums = new FlxTypedGroup<FlxSprite>();

		startingSong = true;

		generateSong(SONG.song);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		add(camFollow);
		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		FlxG.camera.zoom = 1.05;

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic('assets/images/healthBar.png');
		if (ClientPrefs.getOption('downscroll') == true)
			healthBarBG.y = 50;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();

		var healthC1:FlxColor = 0xFFFF0000;
		var healthC2:FlxColor = 0xFF66FF33;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(healthC1, healthC2);

		iconP1 = new HealthIcon(SONG.player1, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);

		iconP2 = new HealthIcon(SONG.player2, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);

		if (!ClientPrefs.getOption('traditionalFunkin') == true){
			add(healthBarBG);
			add(healthBar);
			add(iconP1);
			add(iconP2);}

		if (isStoryMode)
		{
			//startCountdown();
			switch (curSong.toLowerCase())
			{
				case "winter horrorland":
					var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;

					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						remove(blackScreen);
						FlxG.sound.play('assets/sounds/Lights_Turn_On' + TitleState.soundExt);
						camFollow.y = -2050;
						camFollow.x += 200;
						FlxG.camera.focusOn(camFollow.getPosition());
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(0.8, function(tmr:FlxTimer)
						{
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									startCountdown();
								}
							});
						});
					});

				default:
					startCountdown();
			}
		}
		else
			startCountdown();

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		var noteSplash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(noteSplash);
		noteSplash.alpha = 0.1;

		add(grpNoteSplashes);

		scoreTxt = new FlxText(healthBarBG.x + healthBarBG.width - 600, healthBarBG.y + 45, 0, "", 20);
		scoreTxt.setFormat("assets/fonts/vcr.ttf", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		add(scoreTxt);

		debugTxt = new FlxText(1, 680, 0, "", 20); 
		debugTxt.setFormat("assets/fonts/vcr.ttf", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		debugTxt.scrollFactor.set();
		debugTxt.cameras = [camHUD];
		add(debugTxt);

		songInfo = new FlxText(1, 698, 0, "", 20);
		songInfo.setFormat("assets/fonts/vcr.ttf", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		songInfo.scrollFactor.set();
		songInfo.cameras = [camHUD];
		add(songInfo);

		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		doof.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		overlay.cameras = [camHUD];

		super.create();
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	function startCountdown():Void
	{
		generateStaticArrows(0);
		generateStaticArrows(1);

		talking = false;
		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			dad.dance();
			gf.dance();
			boyfriend.playAnim('idle');

			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play('assets/sounds/intro3' + TitleState.soundExt, 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic('assets/images/ready.png');
					ready.scrollFactor.set();
					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play('assets/sounds/intro2' + TitleState.soundExt, 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic('assets/images/set.png');
					set.scrollFactor.set();
					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play('assets/sounds/intro1' + TitleState.soundExt, 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic('assets/images/go.png');
					go.scrollFactor.set();
					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play('assets/sounds/introGo' + TitleState.soundExt, 0.6);
				case 4:
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		startingSong = false;
		FlxG.sound.playMusic("assets/songs/" + SONG.song.toLowerCase() + "/Inst" + TitleState.soundExt, 1, false);
		FlxG.sound.music.onComplete = endSong;
		vocals.play();
	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded("assets/songs/" + SONG.song.toLowerCase() + "/Voices" + TitleState.soundExt);
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		for (section in noteData)
		{
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
					{
						sustainNote.x += FlxG.width / 2; // general offset
					}
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else
				{
				}
			}
			daBeats += 1;
		}

		#if debug
		trace(unspawnNotes.length);
		#end
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function generateStaticArrows(player:Int):Void
	{
		if (ClientPrefs.getOption('traditionalFunkin') == true)
			{
				overlay.visible == true;
			}

		for (i in 0...4)
		{
			FlxG.log.add(i);
			var babyArrow:FlxSprite = new FlxSprite(0, strumLine.y);
			var arrTex = FlxAtlasFrames.fromSparrow(AssetPaths.NOTE_assets__png, AssetPaths.NOTE_assets__xml);
			babyArrow.frames = arrTex;
			babyArrow.animation.addByPrefix('green', 'arrowUP');
			babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
			babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
			babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

			babyArrow.scrollFactor.set();
			babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));
			babyArrow.updateHitbox();
			babyArrow.antialiasing = true;

			babyArrow.y -= 10;
			babyArrow.alpha = 0;
			FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});

			babyArrow.ID = i;

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				cpuStrums.add(babyArrow);

				babyArrow.animation.finishCallback = function(anim)
				{
					babyArrow.animation.play("static");
					babyArrow.offset.set(0, 0);
					babyArrow.centerOffsets();
				}
			}

			switch (Math.abs(i))
			{
				case 2:
					babyArrow.x += Note.swagWidth * 2;
					babyArrow.animation.addByPrefix('static', 'arrowUP');
					babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
					babyArrow.animation.addByPrefix('sustain', 'up sustain', 6, false);
				case 3:
					babyArrow.x += Note.swagWidth * 3;
					babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
					babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
					babyArrow.animation.addByPrefix('sustain', 'right sustain', 6, false);
				case 1:
					babyArrow.x += Note.swagWidth * 1;
					babyArrow.animation.addByPrefix('static', 'arrowDOWN');
					babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
					babyArrow.animation.addByPrefix('sustain', 'down sustain', 6, false);
				case 0:
					babyArrow.x += Note.swagWidth * 0;
					babyArrow.animation.addByPrefix('static', 'arrowLEFT');
					babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
					babyArrow.animation.addByPrefix('sustain', 'left sustain', 6, false);
			}

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				vocals.time = Conductor.songPosition;

				FlxG.sound.music.play();
				vocals.play();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			paused = false;
		}

		super.closeSubState();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		recalculateAccuracy();

		var rankingTracker:String = '';
		var discordTracker:String = '';
		discordTracker = 'Score: ' + songScore + ', ' + 'Accuracy: ' + songAccuracy + '%, ' + 'Misses: ' + misses;

		FlxG.mouse.visible = false;
		#if desktop
		DiscordClient.changePresence('Playing ' + SONG.song + ' - ' + songDifficulty, discordTracker);
		#end

		if (sickTracker == 0 && goodTracker == 0 && badTracker == 0 && shitTracker == 0 && misses == 0) //Default value, like for when a song starts and no notes have been hit.
			rankingTracker = 'Unranked';
		if (sickTracker >= 1 && goodTracker == 0 && badTracker == 0 && shitTracker == 0 && misses == 0)
			rankingTracker = 'MFC!!';
		if (goodTracker >= 1 && badTracker == 0 && shitTracker == 0 && misses == 0)
			rankingTracker = 'GFC!';
		if (badTracker >= 1 || shitTracker >= 1 && misses == 0)
			rankingTracker = 'FC';
		if (misses >= 1 && misses <= 10)
			rankingTracker = 'SDCB';
		if (misses >= 10)
			rankingTracker = 'Clear';
		
		if (songDiffInt == 0)
			songDifficulty = 'Easy';
		if (songDiffInt == 1)
			songDifficulty = 'Normal';
		if (songDiffInt == 2)
			songDifficulty = 'Hard';
		
		scoreTxt.text = "Score: " + songScore + " || " + "Accuracy: " + songAccuracy + "%" + ' - ' + rankingTracker + ' || ' + "Rating: " + ratingTxt + " || " + "Misses: " + misses;
		debugTxt.text = 'Build #$buildNumber';
		songInfo.text = 'Song: $curSong' + ' - ' + songDifficulty;
		discordTracker = songScore + ' || ' + songAccuracy + ' || ' + misses;

		var ratingArray:Array<Dynamic> = [
			[99.95, "S++", 0xFFFFD700],
			[99.5, "S+", 0xFF8D3D8D], 
			[99, "S", 0xFF00FFFF], 
			[95, "A+", 0xFF31CD31], 
			[90, "A", 0xFF00FF00],
			[85, "B+", 0xFFFBC898],    
			[80, "B", 0xFFFF8000], 
			[75, "C+", 0xFFFA5D5D],  
			[70, "C", 0xFFFFFFFF],  
			[0, "D", 0xFFFFFFFF],
		];

		for (thing in ratingArray)
		{
			if (songAccuracy >= thing[0])
			{
				ratingTxt = thing[1];
				ratingColor = thing[2];
				break;
			}
		}

		switch (curStage)
				{
					case 'philly':
						if (trainMoving)
						{
							trainFrameTiming += elapsed;
		
							if (trainFrameTiming >= 1 / 24)
							{
								updateTrainPos();
								trainFrameTiming = 0;
							}
						}
				}

		// trace("SONG POS: " + Conductor.songPosition);
		// FlxG.sound.music.pitch = 2;

		if (FlxG.keys.justPressed.ENTER && startedCountdown)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			FlxG.switchState(new ChartingState());
		}

		if (FlxG.keys.justPressed.R)
			{
				health -= 2;
				trace('Death by suicide - pressed reset');
			}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		iconP1.scale.set(FlxMath.lerp(iconP1.scale.x, 1, elapsed * 9), FlxMath.lerp(iconP1.scale.y, 1, elapsed * 9));
		iconP2.scale.set(FlxMath.lerp(iconP2.scale.x, 1, elapsed * 9), FlxMath.lerp(iconP2.scale.y, 1, elapsed * 9));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		#if debug
		if (FlxG.keys.justPressed.EIGHT)
			FlxG.switchState(new AnimationDebug(SONG.player1));

		if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(new AnimationDebug(SONG.player2));
		#end

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}
			}
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
		{
			if (curBeat % 4 == 0)
			{
				// trace(PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection);
			}

			if (camFollow.x != dad.getMidpoint().x + 150 && !PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
			{
				camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
				vocals.volume = 1;

				if (SONG.song.toLowerCase() == 'tutorial')
				{
					tweenCamIn();
				}
			}

			if (PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && camFollow.x != boyfriend.getMidpoint().x - 100)
			{
				camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

				switch (curStage)
				{
					case 'limo':
						camFollow.x = boyfriend.getMidpoint().x - 300;
					case 'mall' | 'mallEvil':
						camFollow.y = boyfriend.getMidpoint().y - 180;
				}

				if (SONG.song.toLowerCase() == 'tutorial')
				{
					FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
				}
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", totalBeats);

		if (curSong == 'Fresh')
		{
			switch (totalBeats)
			{
				case 16:
					camZooming = true;
					gfSpeed = 2;
				case 48:
					gfSpeed = 1;
				case 80:
					gfSpeed = 2;
				case 112:
					gfSpeed = 1;
				case 163:
					// FlxG.sound.music.stop();
					// curLevel = 'Bopeebo';
					// FlxG.switchState(new TitleState());
			}
		}

		if (curSong == 'Bopeebo')
		{
			switch (totalBeats)
			{
				case 127:
					// FlxG.sound.music.stop();
					// curLevel = 'Fresh';
					// FlxG.switchState(new PlayState());
			}
		}
		// better streaming of shit

		if (health <= 0 && !practiceMode)
		{
			boyfriend.stunned = true;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			deathCounter += 1;

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			// FlxG.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 1500)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}
		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (((ClientPrefs.getOption('downscroll') == true) && daNote.y < -daNote.height)
					|| ((ClientPrefs.getOption('downscroll') == false) && daNote.y > FlxG.height))
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				/*daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2)));

				// i am so fucking sorry for this if condition
				if (daNote.isSustainNote
					&& daNote.y + daNote.offset.y <= strumLine.y + Note.swagWidth / 2
					&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					var swagRect = new FlxRect(0, strumLine.y + Note.swagWidth / 2 - daNote.y, daNote.width * 2, daNote.height * 2);
					swagRect.y /= daNote.scale.y;
					swagRect.height -= swagRect.y;

					daNote.clipRect = swagRect;
				}*/

				var strumLineMid = strumLine.y + Note.swagWidth / 2;

				if ((ClientPrefs.getOption('downscroll') == true))
				{
					daNote.y = (strumLine.y + (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2)));

					if (daNote.isSustainNote)
					{
						if (daNote.animation.curAnim.name.endsWith("end") && daNote.prevNote != null)
							daNote.y += daNote.prevNote.height;
						else
							daNote.y += daNote.height / 2;

						if ((!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))
							&& daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= strumLineMid)
						{
							// clipRect is applied to graphic itself so use frame Heights
							var swagRect:FlxRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);

							swagRect.height = (strumLineMid - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;
							daNote.clipRect = swagRect;
						}
					}
				}
				else
				{
					daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2)));

					if (daNote.isSustainNote
						&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))
						&& daNote.y + daNote.offset.y * daNote.scale.y <= strumLineMid)
					{
						var swagRect:FlxRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);

						swagRect.y = (strumLineMid - daNote.y) / daNote.scale.y;
						swagRect.height -= swagRect.y;
						daNote.clipRect = swagRect;
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit)
				{
					if (SONG.song != 'Tutorial')
						camZooming = true;

					var altAnim:String = "";

					if (SONG.notes[Math.floor(curStep / 16)] != null)
					{
						if (SONG.notes[Math.floor(curStep / 16)].altAnim)
							altAnim = '-alt';
					}

					switch (Math.abs(daNote.noteData))
					{
						case 0:
							dad.playAnim('singLEFT' + altAnim, true);
						case 1:
							dad.playAnim('singDOWN' + altAnim, true);
						case 2:
							dad.playAnim('singUP' + altAnim, true);
						case 3:
							dad.playAnim('singRIGHT' + altAnim, true);
					}

					if (ClientPrefs.getOption('newHoldNotes') == false){					
						if (!daNote.isSustainNote)
							cpuStrums.members[daNote.noteData].animation.play('confirm', true, false);
						else
							cpuStrums.members[daNote.noteData].animation.play('sustain', true, false);}

					else if (ClientPrefs.getOption('newHoldNotes') == true){
						cpuStrums.members[daNote.noteData].animation.play('confirm', true, false);}
					
					cpuStrums.members[daNote.noteData].offset.set(50, 50);
						
					dad.holdTimer = 0;

					if (SONG.needsVoices)
						vocals.volume = 1;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * PlayState.SONG.speed));

				if (daNote.isSustainNote && daNote.wasGoodHit)
					{
						if (((ClientPrefs.getOption('downscroll') == true) && daNote.y < -daNote.height)
							|| ((ClientPrefs.getOption('downscroll') == true) && daNote.y > FlxG.height))
						{
							daNote.active = false;
							daNote.visible = false;
	
							daNote.kill();
							notes.remove(daNote, true);
							daNote.destroy();
						}
					}
					else if (daNote.tooLate || daNote.wasGoodHit)
					{
						if (daNote.tooLate)
						{
							health -= 0.0475;
							vocals.volume = 0;
							misses += 1;
							allNotes++;
							combo = 0;
						}
	
						daNote.active = false;
						daNote.visible = false;
	
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});
			}

		keyShit();
	}

	function endSong():Void
	{
		trace('SONG DONE, in story mode: ' + isStoryMode);
		
		deathCounter = 0;

		Highscore.saveScore(SONG.song, songScore, storyDifficulty);

		if (isStoryMode)
		{
			campaignScore += songScore;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic('assets/music/freakyMenu' + TitleState.soundExt);

				FlxG.switchState(new StoryMenuState());

				//StoryMenuState.weekUnlocked[1] = true;

				Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);

				//FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
				//FlxG.save.flush();
			}
			else
			{
				var difficulty:String = "";

				if (storyDifficulty == 0)
					difficulty = '-easy';

				if (storyDifficulty == 2)
					difficulty == '-hard';

				if (SONG.song.toLowerCase() == 'eggnog')
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom, -FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;
	
						FlxG.sound.play('assets/sounds/Lights_Shut_off' + TitleState.soundExt);
					}
				
				PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
				FlxG.switchState(new PlayState());
			}
		}
		else
		{
			/*if (ClientPrefs.getOption('endlessMode') == true){
					Conductor.songPosition = 0;
					startSong();}
				else */
			FlxG.switchState(new FreeplayState());
		}
	}

	var endingSong:Bool = false;

	private function popUpScore(strumtime:Float, daNote:Note):Void
	{
		var noteDiff:Float = Math.abs(strumtime - Conductor.songPosition);
		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;
		var ratingMod:Float = 1;
		var isSick:Bool = true;

		var daRating:String = "sick";

		if (noteDiff > Conductor.safeZoneOffset * 0.9)
		{
			daRating = 'shit';
			score = 50;
			ratingMod = 0.1;
			isSick = false;
			shitTracker += 1;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.75)
		{
			daRating = 'bad';
			score = 100;
			ratingMod = 0.4;
			isSick = false;
			badTracker += 1;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.45)
		{
			daRating = 'good';
			score = 200;
			ratingMod = 0.75;
			isSick = false;
			goodTracker += 1;
		}

		if (isSick)			
			{
				sickTracker += 1;
				var noteSplash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
				noteSplash.setupNoteSplash(daNote.x, daNote.y, daNote.noteData);
				// new NoteSplash(note.x, daNote.y, daNote.noteData);
				if (ClientPrefs.getOption('notesplashes') == true)
					grpNoteSplashes.add(noteSplash);
			}

		coolNoteFloat += ratingMod;
		if (!practiceMode)
			songScore += score;

		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */
		rating.loadGraphic('assets/images/' + daRating + ".png");
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.updateHitbox();
		rating.antialiasing = true;
		rating.velocity.x -= FlxG.random.int(0, 10);

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.combo__png);
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.antialiasing = true;
		comboSpr.velocity.y -= 150;
		comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		comboSpr.updateHitbox();
		comboSpr.velocity.x += FlxG.random.int(1, 10);
		// add(comboSpr);
		add(rating);

		var seperatedScore:Array<Int> = [];

		seperatedScore.push(Math.floor(combo / 100));
		seperatedScore.push(Math.floor((combo - (seperatedScore[0] * 100)) / 10));
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic('assets/images/num' + Std.int(i) + '.png');
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;
			numScore.antialiasing = true;
			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			numScore.updateHitbox();
			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			if (combo >= 10 || combo == 0)
				add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		curSection += 1;
	}

	private function keyShit():Void
	{
		// HOLDING
		/*var up = gameControls.UP;
			var right = gameControls.RIGHT;
			var down = gameControls.DOWN;
			var left = gameControls.LEFT;

			var upP = gameControls.UP_P;
			var rightP = gameControls.RIGHT_P;
			var downP = gameControls.DOWN_P;
			var leftP = gameControls.LEFT_P;

			var upR = gameControls.UP_R;
			var rightR = gameControls.RIGHT_R;
			var downR = gameControls.DOWN_R;
			var leftR = gameControls.LEFT_R; */

		var up = controls.UP;
		var right = controls.RIGHT;
		var down = controls.DOWN;
		var left = controls.LEFT;

		var upP = controls.UP_P;
		var rightP = controls.RIGHT_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;

		var upR = controls.UP_R;
		var rightR = controls.RIGHT_R;
		var downR = controls.DOWN_R;
		var leftR = controls.LEFT_R;

		var heldControlArray:Array<Bool> = [left, down, up, right];
		var controlArray:Array<Bool> = [leftP, downP, upP, rightP];

		if (heldControlArray.indexOf(true) != -1 && generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && heldControlArray[daNote.noteData])
				{
					goodNoteHit(daNote);
				}
			});
		};

		if (controlArray.indexOf(true) != -1 && generatedMusic)
		{
			boyfriend.holdTimer = 0;

			var pressedNotes:Array<Note> = [];
			var noteDatas:Array<Int> = [];
			var epicNotes:Array<Note> = [];
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
				{
					if (noteDatas.indexOf(daNote.noteData) != -1)
					{
						for (i in 0...pressedNotes.length)
						{
							var note:Note = pressedNotes[i];
							if (note.noteData == daNote.noteData && Math.abs(daNote.strumTime - note.strumTime) < 10)
							{
								epicNotes.push(daNote);
								break;
							}
							else if (note.noteData == daNote.noteData && note.strumTime > daNote.strumTime)
							{
								pressedNotes.remove(note);
								pressedNotes.push(daNote);
								break;
							}
						}
					}
					else
					{
						pressedNotes.push(daNote);
						noteDatas.push(daNote.noteData);
					}
				}
			});
			for (i in 0...epicNotes.length)
			{
				var note:Note = epicNotes[i];
				note.kill();
				notes.remove(note);
				note.destroy();
			}

			if (pressedNotes.length > 0)
				pressedNotes.sort(sortByShit);

			if (perfectMode)
			{
				goodNoteHit(pressedNotes[0]);
			}
			else if (pressedNotes.length > 0)
			{
				for (i in 0...controlArray.length)
				{
					if (controlArray[i] && noteDatas.indexOf(i) == -1)
					{
						badNoteCheck();
					}
				}
				for (i in 0...pressedNotes.length)
				{
					var note:Note = pressedNotes[i];
					if (controlArray[note.noteData])
					{
						goodNoteHit(note);
					}
				}
			}
			else
			{
				badNoteCheck(); // turn this back to BadNoteHit if no work
			}
		};

		if (boyfriend.holdTimer > 0.004 * Conductor.stepCrochet && heldControlArray.indexOf(true) == -1)
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.playAnim('idle');
			}
		}

		playerStrums.forEach(function(spr:FlxSprite)
		{
			switch (spr.ID)
			{
				case 0:
					if (leftP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (leftR)
						spr.animation.play('static');
				case 1:
					if (downP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (downR)
						spr.animation.play('static');
				case 2:
					if (upP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (upR)
						spr.animation.play('static');
				case 3:
					if (rightP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (rightR)
						spr.animation.play('static');
			}

			if (spr.animation.curAnim.name == 'confirm') // && !curStage.startsWith('school'))
			{
				spr.centerOffsets();
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			}
			else
				spr.centerOffsets();
		});
	}

	function noteMiss(direction:Int = 1):Void
	{
		if (!boyfriend.stunned)
		{
			health -= 0.03; //Made it less punishing to attempt the note and fail, this value was 0.6 before!!
			if (combo > 5)
			{
				gf.playAnim('sad');
			}
			combo = 0;
			misses += 1;
			if (!practiceMode)
				songScore -= 10;
			allNotes++;

			FlxG.sound.play('assets/sounds/missnote' + FlxG.random.int(1, 3) + TitleState.soundExt, FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play('assets/sounds/missnote1' + TitleState.soundExt, 1, false);
			// FlxG.log.add('played imss note');

			boyfriend.stunned = true;

			// get stunned for 5 seconds
			new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});

			switch (direction)
			{
				case 2:
					boyfriend.playAnim('singUPmiss', true);
				case 3:
					boyfriend.playAnim('singRIGHTmiss', true);
				case 1:
					boyfriend.playAnim('singDOWNmiss', true);
				case 0:
					boyfriend.playAnim('singLEFTmiss', true);
			}
		}
	}

	function badNoteCheck()
	{
		// just double pasting this shit cuz fuk u
		// REDO THIS SYSTEM!
		var upP = controls.UP_P;
		var rightP = controls.RIGHT_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;

		var gamepad = FlxG.gamepads.lastActive;
		if (gamepad != null)
		{
			if (gamepad.anyJustPressed(["DPAD_LEFT", "LEFT_STICK_DIGITAL_LEFT", X]))
			{
				leftP = true;
			}

			if (gamepad.anyJustPressed(["DPAD_RIGHT", "LEFT_STICK_DIGITAL_RIGHT", B]))
			{
				rightP = true;
			}

			if (gamepad.anyJustPressed(['DPAD_UP', "LEFT_STICK_DIGITAL_UP", Y]))
			{
				upP = true;
			}

			if (gamepad.anyJustPressed(["DPAD_DOWN", "LEFT_STICK_DIGITAL_DOWN", A]))
			{
				downP = true;
			}
		}

		if (leftP)
			noteMiss(0);
		if (upP)
			noteMiss(2);
		if (rightP)
			noteMiss(3);
		if (downP)
			noteMiss(1);
	}

	function noteCheck(keyP:Bool, note:Note):Void
	{
		trace(note.noteData + ' note check here ' + keyP);
		if (keyP)
			goodNoteHit(note);
		else
			badNoteCheck();
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				combo += 1;
				allNotes++;
				popUpScore(note.strumTime, note);
			}

			if (note.noteData >= 0)
				health += 0.023;
			else
				health += 0.004;

			switch (note.noteData)
			{
				case 0:
					boyfriend.playAnim('singLEFT', true);
				case 1:
					boyfriend.playAnim('singDOWN', true);
				case 2:
					boyfriend.playAnim('singUP', true);
				case 3:
					boyfriend.playAnim('singRIGHT', true);
			}

			playerStrums.forEach(function(spr:FlxSprite)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
					if (note.isSustainNote)
						if (ClientPrefs.getOption('newHoldNotes') == true)
							spr.animation.play('confirm', true);

					if (!note.isSustainNote)
						spr.animation.play('confirm', true);
				}
			});

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play('assets/sounds/thunder_' + FlxG.random.int(1, 2) + TitleState.soundExt);
		halloweenBG.animation.play('lightning');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		boyfriend.playAnim('scared', true);
		gf.playAnim('scared', true);
	}

	override function stepHit()
	{
		if (SONG.needsVoices)
		{
			if (vocals.time > Conductor.songPosition + Conductor.stepCrochet
				|| vocals.time < Conductor.songPosition - Conductor.stepCrochet)
			{
				vocals.pause();
				vocals.time = Conductor.songPosition;
				vocals.play();
			}
		}
		super.stepHit();
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	override function beatHit()
	{
		super.beatHit();

		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
		{
			resyncVocals();
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ((ClientPrefs.getOption('downscroll') == true) ? FlxSort.ASCENDING : FlxSort.DESCENDING));
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			else
				Conductor.changeBPM(SONG.bpm);

			// Dad doesnt interupt his own notes
			if (SONG.notes[Math.floor(curStep / 16)].mustHitSection)
				dad.dance();
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (curSong.toLowerCase() == 'dadbattle')
		{
			if (curBeat >= 142 && curBeat < 152 && camZooming && FlxG.camera.zoom < 1.35 && totalBeats % 2 == 0)
			{
				FlxG.camera.zoom += 0.015;
				camHUD.zoom += 0.03;
			}
			if (curBeat >= 152 && curBeat < 160 && camZooming && FlxG.camera.zoom < 1.6)
			{
				FlxG.camera.zoom += 0.03;
				camHUD.zoom += 0.045;
			}
			if (curBeat >= 160 && curBeat < 224 && camZooming && FlxG.camera.zoom < 1.35 && totalBeats % 2 == 0)
			{
				FlxG.camera.zoom += 0.015;
				camHUD.zoom += 0.03;
			}
			if (curBeat == 258){
				FlxG.sound.play('assets/sounds/hey' + TitleState.soundExt, 1);
				gf.playAnim('cheer', true);
				boyfriend.playAnim('hey', true);
				FlxG.camera.fade(0x000000, 2.5, false, null, true);}
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && totalBeats % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (totalBeats % gfSpeed == 0)
			{
				gf.dance();
			}

		if (!boyfriend.animation.curAnim.name.startsWith("sing") && curBeat % 2 == 0)
			boyfriend.playAnim('idle');

		if (totalBeats % 8 == 7 && curSong.toLowerCase() == 'bopeebo')
		{
			boyfriend.playAnim('hey', true);

			if (SONG.song == 'Tutorial' && dad.curCharacter == 'gf')
			{
				dad.playAnim('cheer', true);
			}
		}

		switch (curStage)
		{
			case "philly":
				if (SONG.song.toLowerCase() == 'pico' || SONG.song.toLowerCase() == 'philly nice' || SONG.song.toLowerCase() == 'blammed')
				{
					if (!trainMoving)
						trainCooldown += 1;

					if (curBeat % 4 == 0)
					{
						var colors:Array<FlxColor> = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
						curLight = FlxG.random.int(0, colors.length - 1);
						phillyCityLights.color = colors[curLight];
					}

					if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
					{
						trainCooldown = FlxG.random.int(-4, 0);
						trainStart();
					}
				}

				case 'limo':
						grpLimoDancers.forEach(function(dancer:BackgroundDancer)
						{
							dancer.dance();
						});

						if (FlxG.random.bool(10) && fastCarCanDrive)
							fastCarDrive();
				case 'mall':
					upperBoppers.animation.play('bop', true);
					bottomBoppers.animation.play('bop', true);
					santa.animation.play('idle', true);
		}

		if (isHalloween && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
	}

	function resyncVocals():Void
	{
		if (_exiting)
			return;

		vocals.pause();
		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		// if (vocalsFinished)
		// return;

		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	var curLight:Int = 0;
	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
		{
			if (SONG.song.toLowerCase() == 'pico' || SONG.song.toLowerCase() == 'philly nice' || SONG.song.toLowerCase() == 'blammed')
			{
				trainMoving = true;
				if (!trainSound.playing)
					trainSound.play(true);
			}
		}

	var startedMoving:Bool = false;
	public static var gfCanDance:Bool = true;

	function updateTrainPos():Void
		{
			if (SONG.song.toLowerCase() == 'pico' || SONG.song.toLowerCase() == 'philly nice' || SONG.song.toLowerCase() == 'blammed')
			{
				if (trainSound.time >= 4700)
				{
					startedMoving = true;
					gf.playAnim('hairBlow');
					gfCanDance = false;
				}
		
				if (startedMoving)
				{
					phillyTrain.x -= 400;
		
					if (phillyTrain.x < -2000 && !trainFinishing)
					{
						phillyTrain.x = -1150;
						trainCars -= 1;
		
						if (trainCars <= 0)
							trainFinishing = true;
					}
		
					if (phillyTrain.x < -4000 && trainFinishing)
						trainReset();
				}
			}
		}

	function trainReset():Void
		{
			if (SONG.song.toLowerCase() == 'pico' || SONG.song.toLowerCase() == 'philly nice' || SONG.song.toLowerCase() == 'blammed')
			{
				gf.playAnim('hairFall');
				phillyTrain.x = FlxG.width + 200;
				trainMoving = false;
				trainCars = 8;
				trainFinishing = false;
				startedMoving = false;
				var timer:FlxTimer = new FlxTimer().start(0.46, resetGFAnim);
			}
		}

	function resetGFAnim(timer:FlxTimer):Void
		{
			if (SONG.song.toLowerCase() == 'pico' || SONG.song.toLowerCase() == 'philly nice' || SONG.song.toLowerCase() == 'blammed')
			{				
					gfCanDance = true;
			}
		}

	function recalculateAccuracy(miss:Bool = false) // Thank you Mackery
	{
		if (miss)
			coolNoteFloat -= 1;

		if (allNotes == 0){
			songAccuracy = 100;}
		else
			songAccuracy = FlxMath.roundDecimal(Math.max(0, coolNoteFloat / allNotes * 100), 2);
	}


	var stageObjects:Map<String, FlxSprite> = [];

	var halloweenBG(get, set):FlxSprite;
	inline function get_halloweenBG() {return stageObjects["bg"];}
	inline function set_halloweenBG(spr) {return stageObjects["bg"] = spr;}

	var phillyCityLights(get, set):FlxSprite;
	inline function get_phillyCityLights() {return stageObjects["lights"];}
	inline function set_phillyCityLights(spr) {return stageObjects["lights"] = spr;}

	var phillyTrain(get, set):FlxSprite;
	inline function get_phillyTrain() {return stageObjects["train"];}
	inline function set_phillyTrain(spr) {return stageObjects["train"] = spr;}

	var limo(get, set):FlxSprite;
	inline function get_limo() {return stageObjects["limo"];}
	inline function set_limo(spr) {return stageObjects["limo"] = spr;}

	var fastCar(get, set):FlxSprite;
	inline function get_fastCar() {return stageObjects["fastCar"];}
	inline function set_fastCar(spr) {return stageObjects["fastCar"] = spr;}

	var upperBoppers(get, set):FlxSprite;
	inline function get_upperBoppers() {return stageObjects["upperBoppers"];}
	inline function set_upperBoppers(spr) {return stageObjects["upperBoppers"] = spr;}

	var bottomBoppers(get, set):FlxSprite;
	inline function get_bottomBoppers() {return stageObjects["bottomBoppers"];}
	inline function set_bottomBoppers(spr) {return stageObjects["bottomBoppers"] = spr;}

	var santa(get, set):FlxSprite;
	inline function get_santa() {return stageObjects["santa"];}
	inline function set_santa(spr) {return stageObjects["santa"] = spr;}

	function loadStage(name:String) {
		for (obj in stageObjects.iterator()) {
			remove(obj);
			obj.destroy();
		}
		remove(boyfriend, true);
		remove(dad, true);
		remove(gf, true);
		stageObjects.clear();

		switch (curStage) {
			case "philly":
				FlxG.sound.list.remove(trainSound, true);
				//trainSound.destroy();
		}

		curStage = name;
		switch(curStage) {
			case 'mall':
				curStage = 'mall';
				defaultCamZoom = 0.80;

				var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic('assets/images/stages/mall/bgWalls.png');
				bg.antialiasing = true;
				bg.scrollFactor.set(0.2, 0.2);
				bg.active = false;
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				upperBoppers = new FlxSprite(-240, -90);
				stageObjects["upperBoppers"] = upperBoppers;
				upperBoppers.frames = FlxAtlasFrames.fromSparrow('assets/images/stages/mall/upperBop.png', 'assets/images/stages/mall/upperBop.xml');
				upperBoppers.animation.addByPrefix('bop', "Upper Crowd Bob", 24, false);
				upperBoppers.antialiasing = true;
				upperBoppers.scrollFactor.set(0.33, 0.33);
				upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
				upperBoppers.updateHitbox();
				add(upperBoppers);				

				var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic('assets/images/stages/mall/bgEscalator.png');
				bgEscalator.antialiasing = true;
				bgEscalator.scrollFactor.set(0.3, 0.3);
				bgEscalator.active = false;
				bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
				bgEscalator.updateHitbox();
				add(bgEscalator);

				var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic('assets/images/stages/mall/christmasTree.png');
				tree.antialiasing = true;
				tree.scrollFactor.set(0.40, 0.40);
				add(tree);

				var bottomBoppers = new FlxSprite(-300, 140);
				stageObjects["bottomBoppers"] = bottomBoppers;
				bottomBoppers.frames = FlxAtlasFrames.fromSparrow('assets/images/stages/mall/bottomBop.png', 'assets/images/stages/mall/bottomBop.xml');
				bottomBoppers.animation.addByPrefix('bop', 'Bottom Level Boppers', 24, false);
				bottomBoppers.antialiasing = true;
				bottomBoppers.scrollFactor.set(0.9, 0.9);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic('assets/images/stages/mall/fgSnow.png');
				fgSnow.active = false;
				fgSnow.antialiasing = true;
				add(fgSnow);

				var santa = new FlxSprite(-840, 150);
				stageObjects["santa"] = santa;
				santa.frames = FlxAtlasFrames.fromSparrow('assets/images/stages/mall/santa.png', 'assets/images/stages/mall/santa.xml');
				santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
				santa.antialiasing = true;
				add(santa);

			case 'mallEvil':
				curStage = 'mallEvil';
				var bg:FlxSprite = new FlxSprite(-400, -500).loadGraphic('assets/images/stages/mall/evilBG.png');
				bg.antialiasing = true;
				bg.scrollFactor.set(0.2, 0.2);
				bg.active = false;
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:FlxSprite = new FlxSprite(300, -300).loadGraphic('assets/images/stages/mall/evilTree.png');
				evilTree.antialiasing = true;
				evilTree.scrollFactor.set(0.2, 0.2);
				add(evilTree);

				var evilSnow:FlxSprite = new FlxSprite(-200, 700).loadGraphic("assets/images/stages/mall/evilSnow.png");
				evilSnow.antialiasing = true;
				add(evilSnow);

			case "limo":
				curStage = 'limo';
				defaultCamZoom = 0.90;

				var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic('assets/images/stages/limo/limoSunset.png');
				skyBG.scrollFactor.set(0.1, 0.1);
				add(skyBG);

				var bgLimo:FlxSprite = new FlxSprite(-200, 480);
				bgLimo.frames = FlxAtlasFrames.fromSparrow('assets/images/stages/limo/bgLimo.png', 'assets/images/stages/limo/bgLimo.xml');
				bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
				bgLimo.animation.play('drive');
				bgLimo.scrollFactor.set(0.4, 0.4);
				add(bgLimo);

				add(grpLimoDancers);

				for (i in 0...5)
				{
					var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
					dancer.scrollFactor.set(0.4, 0.4);
					grpLimoDancers.add(dancer);
				}

				var overlayShit:FlxSprite = new FlxSprite(-500, -600).loadGraphic('assets/images/stages/limo/limoOverlay.png');
				overlayShit.alpha = 0.5;

				limo = new FlxSprite(-120, 550);
				limo.frames = FlxAtlasFrames.fromSparrow('assets/images/stages/limo/limoDrive.png', 'assets/images/stages/limo/limoDrive.xml');
				limo.animation.addByPrefix('drive', "Limo stage", 24);
				limo.animation.play('drive');
				stageObjects["limo"] = limo;
				limo.antialiasing = true;

				fastCar = new FlxSprite(-300, 160).loadGraphic('assets/images/stages/limo/fastCarLol.png');
				stageObjects["fastCar"] = fastCar;

			case "philly":
				var bg:FlxSprite = new FlxSprite(-100).loadGraphic('assets/images/stages/philly/sky.png');
				bg.scrollFactor.set(0.1, 0.1);
				stageObjects["bg"] = bg;
				add(bg);
		
				var city:FlxSprite = new FlxSprite(-10).loadGraphic('assets/images/stages/philly/city.png');
				city.scrollFactor.set(0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				stageObjects["city"] = city;
				add(city);
		
				phillyCityLights = new FlxSprite(city.x).loadGraphic('assets/images/stages/philly/win.png');
				phillyCityLights.scrollFactor.set(0.3, 0.3);
				phillyCityLights.color = 0xFF000000;
				phillyCityLights.setGraphicSize(Std.int(phillyCityLights.width * 0.85));
				phillyCityLights.updateHitbox();
				phillyCityLights.antialiasing = true;
				add(phillyCityLights);

				var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic('assets/images/stages/philly/behindTrain.png');
				stageObjects["streetBehind"] = streetBehind;
				add(streetBehind);
		
				phillyTrain = new FlxSprite(2000, 360).loadGraphic('assets/images/stages/philly/train.png');
				add(phillyTrain);
		
				trainSound = new FlxSound().loadEmbedded('assets/sounds/train_passes' + TitleState.soundExt);
				FlxG.sound.list.add(trainSound);
		
				var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic('assets/images/stages/philly/street.png');
				stageObjects["street"] = street;
				add(street);

			case "spooky":
				var hallowTex = FlxAtlasFrames.fromSparrow(AssetPaths.halloween_bg__png, AssetPaths.halloween_bg__xml);

				halloweenBG = new FlxSprite(-200, -100);
				halloweenBG.frames = hallowTex;
				halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
				halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
				halloweenBG.animation.play('idle');
				halloweenBG.antialiasing = true;
				add(halloweenBG);

			default:
				curStage = "stage";
				defaultCamZoom = 0.9;
				var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(AssetPaths.stageback__png);
				// bg.setGraphicSize(Std.int(bg.width * 2.5));
				// bg.updateHitbox();
				bg.antialiasing = true;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				add(bg);
	
				var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(AssetPaths.stagefront__png);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				stageFront.antialiasing = true;
				stageFront.scrollFactor.set(0.9, 0.9);
				stageFront.active = false;
				add(stageFront);
	
				if (ClientPrefs.getOption('performancePlus') == false){
					var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(AssetPaths.stagecurtains__png);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					stageCurtains.antialiasing = true;
					stageCurtains.scrollFactor.set(1.3, 1.3);
					stageCurtains.active = false;
					add(stageCurtains);
				}
		}

		add(gf);
		add(dad);
		add(boyfriend);
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function fastCarDrive()
	{
		FlxG.sound.play('assets/sounds/carPass' + FlxG.random.int(0, 1) + TitleState.soundExt, 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
		});
	}
}
