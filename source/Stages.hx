package;

// UNUSED CODE SHIT

import flixel.system.FlxSound;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.frames.FlxAtlasFrames;
import handlers.ClientPrefs;
import flixel.FlxSprite;
import flixel.FlxBasic;

class Stages extends FlxSprite
{
    public var curStage:String = 'stage';

    var halloweenBG:FlxSprite;
    var phillyCityLights:FlxTypedGroup<FlxSprite>;
	var phillyTrain:FlxSprite;
    var trainSound:FlxSound;

    public function new(?stage:String = 'stage')
        {
            super();

            PlayState.curStage = stage;

            switch (curStage)
                {  
                    case 'stage':
                        var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(AssetPaths.stageback__png);
                        bg.antialiasing = true;
                        bg.scrollFactor.set(0.9, 0.9);
                        bg.active = false;
                        //add(bg);

                        var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(AssetPaths.stagefront__png);
                        stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
                        stageFront.updateHitbox();
                        stageFront.antialiasing = true;
                        stageFront.scrollFactor.set(0.9, 0.9);
                        stageFront.active = false;
                        //add(stageFront);

                        if (ClientPrefs.getOption('performancePlus') == false){
                            var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(AssetPaths.stagecurtains__png);
                            stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
                            stageCurtains.updateHitbox();
                            stageCurtains.antialiasing = true;
                            stageCurtains.scrollFactor.set(1.3, 1.3);
                            stageCurtains.active = false;
                            //add(stageCurtains);
                        }

                    case 'spooky':
                        var hallowTex = FlxAtlasFrames.fromSparrow(AssetPaths.halloween_bg__png, AssetPaths.halloween_bg__xml);
            
                        halloweenBG = new FlxSprite(-200, -100);
                        halloweenBG.frames = hallowTex;
                        halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
                        halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
                        halloweenBG.animation.play('idle');
                        halloweenBG.antialiasing = true;
                        //add(halloweenBG);
                    case 'philly':
                        var bg:FlxSprite = new FlxSprite(-100).loadGraphic('assets/images/stages/philly/sky.png');
                        bg.scrollFactor.set(0.1, 0.1);
                        //add(bg);
                
                        var city:FlxSprite = new FlxSprite(-10).loadGraphic('assets/images/stages/philly/city.png');
                        city.scrollFactor.set(0.3, 0.3);
                        city.setGraphicSize(Std.int(city.width * 0.85));
                        city.updateHitbox();
                        //add(city);
                
                        phillyCityLights = new FlxTypedGroup<FlxSprite>();
                        //add(phillyCityLights);
                
                        for (i in 0...5)
                        {
                            var light:FlxSprite = new FlxSprite(city.x).loadGraphic('assets/images/stages/philly/win' + i + '.png');
                            light.scrollFactor.set(0.3, 0.3);
                            light.visible = false;
                            light.setGraphicSize(Std.int(light.width * 0.85));
                            light.updateHitbox();
                            light.antialiasing = true;
                            phillyCityLights.add(light);
                        }
                        var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic('assets/images/stages/philly/behindTrain.png');
                        //add(streetBehind);
                
                        phillyTrain = new FlxSprite(2000, 360).loadGraphic('assets/images/stages/philly/train.png');
                        //add(phillyTrain);
                
                        trainSound = new FlxSound().loadEmbedded('assets/sounds/train_passes' + TitleState.soundExt);
                        FlxG.sound.list.add(trainSound);
                
                        var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic('assets/images/stages/philly/street.png');
                        //add(street);
                }
        }
}