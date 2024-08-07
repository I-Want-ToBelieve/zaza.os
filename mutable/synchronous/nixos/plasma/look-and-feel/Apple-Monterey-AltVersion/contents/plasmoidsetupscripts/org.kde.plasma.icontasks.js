const allDesktops = desktops()
const NumIconsMax = ((screenGeometry(allDesktops).width)*(.90))/(64)-7
   /*Tasks*/
    /*added icons apps*/
     /*filemanager*/
      if (applicationExists("org.kde.dolphin.desktop"))
          {
           var apps01 = "applications:org.kde.dolphin.desktop";
          }
      else{
           var apps01 = "";
          }
      /*web browser*/
function BrowserApp(){
 let ListBrowser = {
  1 : "firefox.desktop",
  2 : "firefox_firefox.desktop",
  3 : "org.mozilla.firefox.desktop",
  4 : "chrome.desktop",
  5 : "com.google.Chrome.desktop",
  6 : "applications:com.google.Chrome.desktop",
  7 : "falkon.desktop",
  8 : "org.kde.falkon.desktop",
  9 : "applications:librewolf.desktop",
  10 : "io.gitlab.librewolf-community.desktop",
  11 : userDataPath(),
      }
function BalLisBrowser(x){
if (applicationExists(ListBrowser[x]))
{    return 1
} else {  return 0
}
}
for (a = 1;  BalLisBrowser(a) < 1; a++) {
}
if (ListBrowser[a] === userDataPath()){
    return "0"
} else {
return "applications:"+ListBrowser[a]}
}

if (defaultApplication("browser")) {
var prevbrowser = defaultApplication("browser")
if (prevbrowser.includes("/")){
var browser = BrowserApp()
} else {
if (prevbrowser.includes(".desktop")){
  var browser = `applications:${defaultApplication("browser")}`
  } else {
var browser = BrowserApp()
  }
}
}
else
{
var browser = BrowserApp()
}
/*end web browser*/
function FindApps(y){
 let FullApps = {
  1 : "org.kde.discover.desktop",
  2 : "org.kde.gwenview.desktop",
  3 : "org.kde.konsole.desktop",
  4 : "systemsettings.desktop",
  5 : "okularApplication_comicbook.desktop",
  6 : "spotify.desktop",
  7 : "org.inkscape.Inkscape.desktop",
  8 : "libreoffice-writer.desktop",
  9 : "libreoffice_writer.desktop",
  10 : "libreoffice-calc.desktop",
  11 : "libreoffice_calc.desktop",
  12 : "file:///var/lib/flatpak/exports/share/applications/com.wps.Office.wps.desktop",
  13 : "gimp.desktop",
  14 : "org.telegram.desktop.desktop",
  15 : "org.telegram.desktop",
  16 : "vlc.desktop",
  17 : "geany.desktop",
  18 : "in.srev.guiscrcpy.desktop",
  19 : "com.visualstudio.code.desktop",
  20 : "com.obsproject.Studio.desktop",
  21 : "com.rafaelmardojai.Blanket.desktop",
  22 : "io.github.jliljebl.Flowblade.desktop",
  23: "com.play0ad.zeroad.desktop"
       }
       let MusicPLayer = {
  1 : "org.kde.elisa.desktop",
  2 : "audacious.desktop",
  3 : "file:///var/lib/flatpak/exports/share/applications/org.atheme.audacious.desktop",
  4 : "clementine.desktop",
  5 : "org.gnome.Lollypop.desktop",
  6 : "com.github.neithern.g4music.desktop",
      }
      let TextEditor = {
  1 : "org.kde.kwrite.desktop",
  2 : "org.kde.kate.desktop",
      }
let result = '';
for (a = 1;  a < 23; a++) {
if (applicationExists(FullApps[a]))  {
    result += 'applications:'+FullApps[a] + ', ';  }
}
let resultMusic = '';
for (a = 1;  a < 6; a++) {
if (applicationExists(MusicPLayer[a]))  {
    resultMusic += 'applications:'+MusicPLayer[a] + ', ';  }
}
let resultEditor = '';
for (a = 1;  a < 6; a++) {
if (applicationExists(TextEditor[a]))  {
    resultEditor += 'applications:'+TextEditor[a] + ', ';  }
}
var AppsPrev = (result+resultMusic.split(' ')[0]+' '+resultEditor.split(' ')[0]).replace(/ /g,'')
var AppsFinal = AppsPrev.substring(0, AppsPrev.length - 1)
return AppsFinal.split(',',y)
}

var apps = FindApps(8)
           /*icons dock /*/
  /*dock*/
applet.currentConfigGroup = [];
applet.writeConfig("launchers", "")
applet.currentConfigGroup = ["General"];
applet.writeConfig("indicateAudioStreams", "false")
applet.writeConfig("iconSpacing", "0")
if (`${browser}` === "0")
           {
applet.writeConfig("launchers", `${apps01},${apps}`)
           }
else {
applet.writeConfig("launchers", `${apps01},${browser},${apps}`)
          }
applet.writeConfig("maxStripes", "1")
