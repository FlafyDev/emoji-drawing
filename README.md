# Emoji Drawing

An app I quickly made to help me gather handmade emoji drawings for my ML project.

Server and website are running on different ports. Use Nginx or something to combine them.  
I wanted to make a Dart backend instead of using Next.JS. Not sure how smart it's to do that but I like Dart so I don't mind.  

## Nix

Server package uses IFD instead of generating json pubspec lock.

```nix
## Add inputs
inputs = {
  emoji-drawing.url = "path:/home/flafy/repos/flafydev/emoji-drawing-website";
};
## Add Nixpkgs module (osModules is a Combined Manager feature)
osModules = [inputs.emoji-drawing.nixosModules.default];
## Setup service
services.emojiDrawing = cfg;
```
