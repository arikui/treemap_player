/*
>> cscript data_by_itunes.js > artist_data.json
*/

var PLAYLIST_NAME = " "; // set your playlist name

/////////////////////////////////////////////////////
var File = WSH.CreateObject("Scripting.FileSystemObject");

var $scriptDir = (function(){
	var path = WSH.ScriptFullName.split("\\");
	path.pop();
	return path.join("\\");
})();

if(!File.FolderExists($scriptDir + "\\data\\artwork")){
	File.CreateFolder($scriptDir + "\\data\\artwork");
}

var artists = {};

var Artist = function(name){
	this.name = name;
	this.size = 0;
	this.albums = {};
};

Artist.prototype = {
	add: function(track){
		var size = track.Duration
		var album = track.Album;

		this.size += size;

		if(album in this.albums)
			this.albums[track.Album] += size;
		else
			this.albums[track.Album]  = size;
	},

	toJSON: function(){
		var children = [];

		for(var album in this.albums)
			children.push('"' + album + '":' + this.albums[album] + "");

		children = "{" + children.join(",") + "}";

		return '"' + this.name + '":{"size":' + this.size + ',"albums":' + children + "}";
	}
};

var iTunes = WSH.CreateObject("iTunes.Application");
var playlist = iTunes.Sources.ItemByName("\u30E9\u30A4\u30D6\u30E9\u30EA").Playlists.ItemByName(PLAYLIST_NAME);
var tracks = playlist.Tracks;

var got_artwork = {};
var total_size = 0;
for(i = 1, l = tracks.Count; i <= l; ++i){
	var track  = tracks.Item(i);
	var artist = track.Artist;
	var album  = track.Album;

	if((artist + album).match(/[\u3041-\u9ED1"]/))
		continue;

	if(!(artist in artists))
		artists[artist] = new Artist(artist);

	// save artwork
	var artwork = track.Artwork;
	var fileName = artist + "_" + album;

	if(!(fileName in got_artwork) && artwork.Count){
		artwork = artwork.Item(1);
		var ext = imgFormat(artwork.Format);

		if(ext){
			var savePath = $scriptDir + "\\data\\artwork\\" + fileName + "." + ext;
			// save
			if(!File.FileExists(savePath)){
				try{
					artwork.SaveArtworkToFile(savePath);
				}
				catch(e){
					//WSH.Echo(savePath);
				}
			}

			got_artwork[fileName] = true;
		}
	}

	artists[artist].add(track);
	total_size += track.Duration;
};

var artistsToJSON = function(){
	var s = ['{"size":' + total_size + ',"artists":{'];

	var children = [];
	for(var x in artists)
		children.push(artists[x].toJSON());

	s.push(children.join(","));
	s.push("}}");

	return s.join("");
};

WSH.Echo(artistsToJSON());



function imgFormat(n){
	switch(n){
		case 1:  return "jpg";
		case 2:  return "png";
		case 3:  return "bmp";
		default: return null;
	}
}
