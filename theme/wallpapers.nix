# Curated from AngelJumbo/gruvbox-wallpapers; pinned by commit and hash, fetched at build time rather than vendored.
{ fetchurl }:
let
  rev = "6aa74cbd65973e1a2a8695e83a58ce3ea634dd5e";
  wallpaper =
    {
      name,
      path,
      hash,
    }:
    {
      inherit name;
      path = fetchurl {
        inherit name hash;
        url = "https://raw.githubusercontent.com/AngelJumbo/gruvbox-wallpapers/${rev}/${
          builtins.replaceStrings [ " " "@" ] [ "%20" "%40" ] path
        }";
      };
    };
in
map wallpaper [
  {
    name = "pixel-watermill.png";
    path = "wallpapers/pixelart/dock.png";
    hash = "sha256-t+leCHSupUwK8q/bGXb3OJpf0SuEkFxX27tlFo8Gxv8=";
  }
  {
    name = "pixel-castle.png";
    path = "wallpapers/pixelart/gruvbox_image40.png";
    hash = "sha256-hCo7ogKzdfqVqmP+gCNRIiHdKIzbFkYy8pnoO8EnHoQ=";
  }
  {
    name = "pixel-village.png";
    path = "wallpapers/pixelart/light/jmw327@x.com-2020_11_04-store_front.png";
    hash = "sha256-41EXn5ayc6n1Zb1DCUAWxZSwWXWrJGeoQ8Q/AqMqSq4=";
  }
  {
    name = "pixel-waterfall.png";
    path = "wallpapers/pixelart/secluded-grove-pixel.png";
    hash = "sha256-x0S/gHRVjzsDMA/Jx6ESZ3TXpy6AbhXrNeG2Z2Sc5bo=";
  }
  {
    name = "pixel-city.jpg";
    path = "wallpapers/pixelart/brown_city_planet_w.jpg";
    hash = "sha256-tkxERnTqxHRYHnroMUh09+VdXRpOZse/Ualot76XEFc=";
  }
  {
    name = "painting-landscape.jpg";
    path = "wallpapers/painting/idyllic-procession.jpg";
    hash = "sha256-vgrnMmOl62lBb7E1R4JqYIBoWaoxuwMQU6/HPeYKVcU=";
  }
  {
    name = "painting-flowers.jpg";
    path = "wallpapers/painting/flower-basket.jpg";
    hash = "sha256-5hiPxQmzM28fIuCXMowpveYE52yWUJLeaaWGH6NYdZg=";
  }
  {
    name = "painting-cat.png";
    path = "wallpapers/painting/Cat_at_Play.png";
    hash = "sha256-pFFYagvEGPGDMu+avQHCor7khf63lyeCKTnRkRxR1w0=";
  }
  {
    name = "minimal-moon.png";
    path = "wallpapers/minimalistic/moon.png";
    hash = "sha256-ABLA7IjkroM29nRD0J6LiBSoKJ6ebrs4L5gAlnog9vc=";
  }
  {
    name = "minimal-rocket.png";
    path = "wallpapers/minimalistic/rocket.png";
    hash = "sha256-26dqbsQZTcnyQCHSoWZaXkY9Dhko1UugqpYewvNvrd4=";
  }
  {
    name = "photo-autumn-canopy.jpg";
    path = "wallpapers/photography/clay-banks-Jya99orvzSE.jpg";
    hash = "sha256-6Vz6RmR0tQTCXcrgZaGzlpU2qBl7/AqLdo1EdiiUhIY=";
  }
  {
    name = "photo-moss-forest.png";
    path = "wallpapers/photography/forest-moss.png";
    hash = "sha256-ukaVOWQhHVK+RqiaPXqVpHB4fkGVqb++ecsgKDGW/go=";
  }
  {
    name = "photo-foggy-road.jpg";
    path = "wallpapers/photography/road-3.jpg";
    hash = "sha256-RbcFIEdLqrUZOp2Qz2o9x4Qfu68tMBSyvHB39L3tFKo=";
  }
  {
    name = "photo-rocky-coast.jpg";
    path = "wallpapers/photography/sea.jpg";
    hash = "sha256-UdQAUsG12XaZvP3CxfvjW20Xfna7GUqu1+SKZufGqik=";
  }
  {
    name = "render-steampunk-tower.jpg";
    path = "wallpapers/mix/future-town.jpg";
    hash = "sha256-hFE7SVkYHsukkyA2i3a92h2vifh+2Se5MMayUQd+CWU=";
  }
  {
    name = "painting-chrysanthemum.jpg";
    path = "wallpapers/mix/flower.jpg";
    hash = "sha256-OZQtlt28JfWFCyEPnRhbMTl7CKMGJ+yepRaUgKJN2xg=";
  }
  {
    name = "photo-sparrow.jpg";
    path = "wallpapers/photography/kateryna-sheliuk-efMADvDQvEg.jpg";
    hash = "sha256-W+yVpOfjbDyn3otoeVzVBBLfUBPSd/G4gxfagdLrKNk=";
  }
  {
    name = "pixel-pacman.png";
    path = "wallpapers/pixelart/gruvbox-pacman-full.png";
    hash = "sha256-Tl5PpQbXc0Kp2nfjR2xwgxY3qF6svvw5rUBW9A3vboo=";
  }
  {
    name = "pixel-pacman-ghosts.png";
    path = "wallpapers/pixelart/gruvbox-pacman-ghosts.png";
    hash = "sha256-JlLVPXGZkEe2VkZ0yhAUk86OXvWgqWFBqtENd1QC7G0=";
  }
  {
    name = "pixel-temple.png";
    path = "wallpapers/pixelart/gruvbox_image44.png";
    hash = "sha256-oehwYwa0oGZmvc7zZ5vEju2F/swRITuAO6CzrP89jgY=";
  }
  {
    name = "pixel-night-falls.png";
    path = "wallpapers/pixelart/gruvbox_image55.png";
    hash = "sha256-lgZbAAWTimybsBD+2ZsS/jwKtyPbQ1QCgt/82RDIHug=";
  }
  {
    name = "pixel-grove.png";
    path = "wallpapers/pixelart/secluded-grove-pixel.png";
    hash = "sha256-x0S/gHRVjzsDMA/Jx6ESZ3TXpy6AbhXrNeG2Z2Sc5bo=";
  }
]
