---
title: Remuxing with mkvtoolnix
tags: [video, media, mkv]
---

### View track information

```sh
mkvinfo input.mkv
```

### Mux separate tracks into an MKV container

```sh
mkvmerge video.mp4 audio.ac3 audio.mp3 subtitle.srt -o output.mkv
```


### Set track information

* List all property names with `mkvpropedit -l`
* Language property supports [ISO 639-2 Codes](https://en.wikipedia.org/wiki/List_of_ISO_639-2_codes)

_Update Subtitle (language / default / forced flags) and Audio (language) flags:_

```sh
mkvpropedit movie.mkv \
    --edit track:a1 --set language=eng \
    --edit track:a2 --set language=spa \
    --edit track:s1 --set language=eng --set flag-default=1 --set name "English" \
    --edit track:s2 --set language=eng --set flag-default=0 --set name "English (Forced)" --set flag-forced=1 \
    --edit track:s3 --set language=jpn --set flag-default=0 --set name "Japanese"
```

