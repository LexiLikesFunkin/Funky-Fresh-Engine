package handlers;

import flixel.FlxG;

class ClientPrefs
{
	public static var options:Map<String, Dynamic> = new Map();

	public static function getOption(option:String)
		return options.get(option);

	public static function setOption(optionName:String, optionValue:Dynamic){
		options.set(optionName, optionValue);
	
		FlxG.save.data.options = options;
		FlxG.save.flush();
	}

	public static function initOptions(){
		if (FlxG.save.data.options != null)
			options = FlxG.save.data.options;

		if (ClientPrefs.getOption('endlessMode') == null)
			ClientPrefs.setOption('endlessMode', false); //No worky :( - Lexi		
		if (ClientPrefs.getOption('newHoldNotes') == null)
			ClientPrefs.setOption('newHoldNotes', true);
		if (ClientPrefs.getOption('performancePlus') == null)
			ClientPrefs.setOption('performancePlus', false);
		if (ClientPrefs.getOption('traditionalFunkin') == null)
			ClientPrefs.setOption('traditionalFunkin', false);
		if (ClientPrefs.getOption('downscroll') == null)
			ClientPrefs.setOption('downscroll', false);
		if (ClientPrefs.getOption('framerate') == null)
			ClientPrefs.setOption('framerate', 60);
	}
}