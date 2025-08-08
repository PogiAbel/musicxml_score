# musicxml_score

This package tries to render MusicXML files into a canvas, creating a score.

The elements in the score will be limited to my use cases, but I wanted to create a modular system that is easy to expand.

This is in heavy development and not ready to use yet.

The files in the generated folder are from [music_notes](https://github.com/ghost23/music_notes)

The starting point of this project is my Bsc thesis, which you can find [here](http://193.6.1.94:9080/jadox/portal/displayImage.psml?offset=1&docID=49183&secID=48299&libraryId=-1&limit=10&pageSet=newLine&resultType=0&schemaId=null&action=browse&site=search&type=advanced&orderBy=0) (in hungarian)

Next steps:
- ~~create a SMuFL parser, font manager~~ (I gave up on this one)
- Rewrite distance calculation, anchor managment
- Correct beam generation 