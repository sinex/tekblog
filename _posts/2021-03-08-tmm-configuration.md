---
title: tinyMediaManager configuration
tags: [media, configuration]
---

## Movie Rename format:

```
${title} ${- ,edition,} (${year}) ${(,mediaSource,) }[${videoCodec} ${videoFormat}${if movie.mediaInfoVideoFormat = "2160p"}${ ,hdr,}${end}, ${audioCodec} ${audioChannels}]

${title} ${- ,edition,} (${year}) ${(,mediaSource,) }[${videoCodec} ${videoFormat}${if movie.mediaInfoVideoFormat = "2160p"}${if movie.mediaInfoVideoBitDepth = "10"}${ ,videoBitDepth,}bit${ ,hdr,}${end}${end}, ${audioCodec} ${audioChannels}]
```

```
$set(year,$if2(%originalyear%,%year%))
$set(mediaType,
$if($eq(%media%,Digital Media),Digital,
$if($eq(%media%,12" Vinyl),12in Vinyl,
$if($eq(%media%,7" Vinyl),7in Vinyl,
$if($eq(%media%,Enhanced CD),ECD,
$if($eq(%media%,DVD-Video),DVD,
%media%
))))))

$set(discsubtitle,$if2(
$if($startswith(%discsubtitle%,Outtakes and Previously Unreleased Music From: Star Wars),
	Outtakes and Unreleased
),
%discsubtitle%
))

$set(_primaryreleasetype,
$if($eq(%_primaryreleasetype%,ep),EP,
$title(%_primaryreleasetype%))/
/)

$set(releaseType,$title(%_primaryreleasetype%)/)
$set(mediaType,$if(%mediaType%,$lower(%mediaType%)))

$set(catalogNumber,$if(%catalognumber%,$if($eq(%catalognumber%,[none]),,%catalognumber%)))


$set(releaseDetail,[%mediaType%\,%releasetype%] [%releasecountry%$if(%catalogNumber%,\,%catalogNumber%)])

$set(isMultiDisc,$gt(%totaldiscs%,1))

$set(discName,
$if($rsearch(%discsubtitle%,^Disc \\d),%discsubtitle%,
$if(%discsubtitle%,Disc %discnumber% - %discsubtitle%,
Disc %discnumber%
)))

$set(discFolder,$if(%isMultiDisc%,%discName%))
$set(trackNum,$if(%isMultiDisc%,%discnumber%-,)$if($ne(%albumartist%,),$num(%tracknumber%,2),))
$set(trackartist,$if(%_multiartist%,%artist%))

$set(albumFolder,%year%. %album% %releaseDetail% )
$set(albumartist,$if2(%albumartist%,%artist%))

$set(isSoundtrack,$in(%releasetype%,soundtrack))
$set(soundtrackFolder,%album%$if(%year%, \(%year%\)))

$if(%isSoundtrack%,
	Soundtracks/%soundtrackFolder%/%discFolder%/%trackNum% %artist% - %title%,
	%albumartist%/%releaseType%/%albumFolder%/%discFolder%/%trackNum% $if(%trackartist%,%trackartist% - )%title%
)
```