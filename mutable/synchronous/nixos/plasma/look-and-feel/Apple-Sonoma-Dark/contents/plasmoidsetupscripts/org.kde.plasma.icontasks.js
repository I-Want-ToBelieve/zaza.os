const allDesktops = desktops();
const NumIconsMax = ((screenGeometry(allDesktops).width) * 0.90) / 64 - 7;

// Added icons apps
let apps01 = applicationExists("org.kde.dolphin.desktop") ? "applications:org.kde.dolphin.desktop" : "";

// Web browser
function getBrowserApp() {
    const ListBrowser = [
        "firefox.desktop",
        "firefox_firefox.desktop",
        "org.mozilla.firefox.desktop",
        "chrome.desktop",
        "com.google.Chrome.desktop",
        "applications:com.google.Chrome.desktop",
        "falkon.desktop",
        "org.kde.falkon.desktop",
        "applications:librewolf.desktop",
        "io.gitlab.librewolf-community.desktop",
        userDataPath(),
    ];

    for (let i = 0; i < ListBrowser.length; i++) {
        if (applicationExists(ListBrowser[i])) {
            return ListBrowser[i] === userDataPath() ? "0" : `applications:${ListBrowser[i]}`;
        }
    }
    return "0";
}

const defaultBrowser = defaultApplication("browser");
const browser = defaultBrowser.includes("/") ? getBrowserApp() : `applications:${defaultBrowser}` || getBrowserApp();

// Other apps
function findApps(limit) {
    const FullApps = [
        "kitty.desktop",
        "org.kde.discover.desktop",
        "org.kde.gwenview.desktop",
        "systemsettings.desktop",
        "okularApplication_comicbook.desktop",
        "spotify.desktop",
        "org.inkscape.Inkscape.desktop",
        "libreoffice-writer.desktop",
        "libreoffice_writer.desktop",
        "libreoffice-calc.desktop",
        "libreoffice_calc.desktop",
        "file:///var/lib/flatpak/exports/share/applications/com.wps.Office.wps.desktop",
        "gimp.desktop",
        "org.telegram.desktop.desktop",
        "org.telegram.desktop",
        "vlc.desktop",
        "geany.desktop",
        "in.srev.guiscrcpy.desktop",
        "com.visualstudio.code.desktop",
        "com.obsproject.Studio.desktop",
        "com.rafaelmardojai.Blanket.desktop",
        "io.github.jliljebl.Flowblade.desktop",
        "com.play0ad.zeroad.desktop"
    ]

    const MusicPlayer = [
        "org.kde.elisa.desktop",
        "audacious.desktop",
        "file:///var/lib/flatpak/exports/share/applications/org.atheme.audacious.desktop",
        "clementine.desktop",
        "org.gnome.Lollypop.desktop",
        "com.github.neithern.g4music.desktop"
    ]

    const TextEditor = [
        "org.kde.kwrite.desktop",
        "org.kde.kate.desktop",
        "wps-office-wps.desktop",
        "code.desktop",
    ]

    const appsList = FullApps.concat(MusicPlayer, TextEditor)
        .filter(app => applicationExists(app))
        .slice(0, limit)
        .map(app => `applications:${app}`)
        .join(",");

    return appsList;
}

const apps = findApps(8);

print(apps)

// Configure dock
applet.currentConfigGroup = [];
applet.writeConfig("launchers", "")
applet.currentConfigGroup = ["General"];
applet.writeConfig("indicateAudioStreams", "false");
applet.writeConfig("iconSpacing", "0");
applet.writeConfig("launchers", `${apps01},${browser},${apps}`);
applet.writeConfig("maxStripes", "1");





