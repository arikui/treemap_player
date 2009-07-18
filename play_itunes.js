var PLAYLIST_NAME = " "; // set your playlist name
/////////////////////////////////////////////////////
WSH.Timeout = 100;
var artist = WSH.Arguments(0);
var album = WSH.Arguments(1);
var name = WSH.Arguments(2);

var iTunes = WSH.CreateObject("iTunes.Application");
var playlist = iTunes.Sources.ItemByName("\u30E9\u30A4\u30D6\u30E9\u30EA").Playlists.ItemByName(PLAYLIST_NAME);
var matches = playlist.Search(artist + " " + album, 0);

for(var i = 1, l = matches.Count; i <= l; ++i){
	var track = matches.Item(i);

	if(track.Artist == artist && track.Album == album && track.Name == name){
		track.Play();
		break;
	}
}
