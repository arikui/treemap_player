var PLAYLIST_NAME = " "; // set your playlist name
/////////////////////////////////////////////////////
WSH.Timeout = 100;
var File = WSH.CreateObject("Scripting.FileSystemObject");
var iTunes = WSH.CreateObject("iTunes.Application");

var $scriptDir = (function(){
	var path = WSH.ScriptFullName.split("\\");
	path.pop();
	return path.join("/");
})();

var artist = WSH.Arguments(0);
var album = WSH.Arguments(1);

// search tracks
var playlist = iTunes.Sources.ItemByName("\u30E9\u30A4\u30D6\u30E9\u30EA").Playlists.ItemByName(PLAYLIST_NAME);
var matches = playlist.Search(artist + " " + album, 0);

// get songs
var songs = {};
var got_artwork = {};
for(var i = 1, l = matches.Count; i <= l; ++i){
	var track = matches.Item(i);
	var name = track.Name;

	if(track.Artist != artist || track.Album != album) continue;
	if(name in songs) continue;

	// add
	songs[name] = track.Duration;
}

// to json
var json = [];
for(var x in songs){
	json.push('"' + x.replace(/"/g, '\\"') + '":' + songs[x] + "");
}

// puts
WSH.Echo("{" + json.join(",") + "}");




function imgFormat(n){
	switch(n){
		case 1:  return "jpg";
		case 2:  return "png";
		case 3:  return "bmp";
		default: return null;
	}
}
