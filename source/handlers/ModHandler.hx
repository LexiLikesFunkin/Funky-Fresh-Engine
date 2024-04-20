package handlers;
#if sys
import polymod.Polymod;
#end

using StringTools;

class ModHandler
{
    public static function loadMods()
        {  
            #if sys
            polymod.Polymod.init({
                modRoot: "mods",
                dirs: sys.FileSystem.readDirectory('./mods'),
                errorCallback: (e) ->
                {
                    trace(e.message);
                },
                frameworkParams: {
                    assetLibraryPaths: [
                        "songs" => "assets/songs",
                        "images" => "assets/images",
                        "data" => "assets/data",
                        "fonts" => "assets/fonts",
                        "sounds" => "assets/sounds",
                        "music" => "assets/music",
                        "characters" => "characters",
                        "icons" => "images/icons",
                    ]
                }
            });
            #end
        }
} 