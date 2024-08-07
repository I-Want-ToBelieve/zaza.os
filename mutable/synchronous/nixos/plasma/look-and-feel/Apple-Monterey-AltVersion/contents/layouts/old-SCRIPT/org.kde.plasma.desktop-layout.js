/*******Panel Top*********/
paneltop = new Panel
paneltop.hiding = "none"
paneltop.location = "top"
paneltop.height = 24
paneltop.offset = 0
const width = screenGeometry(paneltop.screen).width
/*kapple*/
if (width <= 900){
  paneltop.addWidget("org.kde.plasma.marginsseparator")
     } else {
  paneltop.addWidget("org.kde.plasma.marginsseparator")
  paneltop.addWidget("org.kde.plasma.marginsseparator")}
  paneltop.addWidget("org.kpple.kppleMenu")
paneltop_napp = paneltop.addWidget("org.kde.activeApplication")
 paneltop_napp.currentConfigGroup = ["Appearance"]
  paneltop_napp.writeConfig("noWindowText", "Desktop")
paneltop.addWidget("org.kde.plasma.appmenu")
 paneltop.addWidget("org.kde.plasma.panelspacer")
paneltop_Battery = paneltop.addWidget("org.kde.plasma.bigSur-inlineBattery")
 paneltop_Battery.currentConfigGroup = ["General"]
  paneltop_Battery.writeConfig("fontSize", "13")
   paneltop_Battery.writeConfig("iconHeight", "12")
    paneltop_Battery.writeConfig("iconWidth", "23")
     paneltop_Battery.writeConfig("padding", "4")
      paneltop_Battery.writeConfig("showPercentage", "false")
  if (width <= 900){
  if (width <= 720){
  paneltop.addWidget("org.kde.plasma.networkmanagement")
  paneltop.addWidget("org.kde.plasma.volume")
  paneltop.addWidget("org.kde.plasma.notifications")
  paneltop.addWidget("com.github.prayag2.controlcentre")
  paneltop.addWidget("org.kde.milou")
} else
{
  paneltop.addWidget("org.kde.plasma.marginsseparator")
  paneltop.addWidget("org.kde.plasma.networkmanagement")
  paneltop.addWidget("org.kde.plasma.marginsseparator")
  paneltop.addWidget("org.kde.plasma.volume")
  paneltop.addWidget("org.kde.plasma.marginsseparator")
  paneltop.addWidget("org.kde.plasma.notifications")
  paneltop.addWidget("org.kde.plasma.marginsseparator")
  paneltop.addWidget("com.github.prayag2.controlcentre")
  paneltop.addWidget("org.kde.plasma.marginsseparator")
  paneltop.addWidget("org.kde.milou")
  paneltop.addWidget("org.kde.plasma.marginsseparator")
   }
     } else {
  paneltop.addWidget("org.kde.plasma.marginsseparator")
  paneltop.addWidget("org.kde.plasma.marginsseparator")
  paneltop.addWidget("org.kde.plasma.networkmanagement")
  paneltop.addWidget("org.kde.plasma.marginsseparator")
  paneltop.addWidget("org.kde.plasma.marginsseparator")
  paneltop.addWidget("org.kde.plasma.volume")
  paneltop.addWidget("org.kde.plasma.marginsseparator")
  paneltop.addWidget("org.kde.plasma.marginsseparator")
  paneltop.addWidget("org.kde.plasma.notifications")
  paneltop.addWidget("org.kde.plasma.marginsseparator")
  paneltop.addWidget("org.kde.plasma.marginsseparator")
  paneltop.addWidget("com.github.prayag2.controlcentre")
  paneltop.addWidget("org.kde.plasma.marginsseparator")
  paneltop.addWidget("org.kde.plasma.marginsseparator")
  paneltop.addWidget("org.kde.milou")
  paneltop.addWidget("org.kde.plasma.marginsseparator")
  paneltop.addWidget("org.kde.plasma.marginsseparator")
}
      paneltop_clock = paneltop.addWidget("com.marcinorlowski.htmlclock")
       paneltop_clock.currentConfigGroup = ["Appearance"];
        paneltop_clock.writeConfig("useUserLayout", "true")
         paneltop_clock.currentConfigGroup = ["Configuration/Appearance"];
          paneltop_clock.writeConfig("layout", '<html><body><center><span style="font-weight:500;">{DD:u} {h}:{ii}</span></center></body></html>');
if (width <= 900){
  paneltop.addWidget("org.kde.plasma.marginsseparator")
     } else {
  paneltop.addWidget("org.kde.plasma.marginsseparator")
  paneltop.addWidget("org.kde.plasma.marginsseparator")
}
            /****************************/
panelbottom = new Panel
 panelbottom.location = "bottom"
  panelbottom.height = 66
   panelbottom.offset = 0
    panelbottom.alignment = "center"
     panelbottom.panelVisibility = "2"
      if (width === 1920){
      panelbottom.maximumLength = 1728
       } else
     {
       if (width === 900){
      panelbottom.maximumLength = 810
       } else
     {
       if (width === 720){
      panelbottom.maximumLength = 648
       } else
     {
       panelbottom.maximumLength = (width)*(.90)
    }
    }
    }
    panelbottom.minimumLength = 100
        panelbottom.hiding = "windowscover"
         panelbottom.addWidget("org.kde.plasma.marginsseparator")
          panelbottom_start = panelbottom.addWidget("P-Connor.PlasmaDrawer")
           panelbottom_start.currentConfigGroup = ["General"]
            panelbottom_start.writeConfig("customButtonImage", "launcher")
             panelbottom_start.writeConfig("useCustomButtonImage", "true")
panelbottom.addWidget("org.kde.plasma.icontasks")
    /*Trash*/
    panelbottom.addWidget("org.kde.latte.separator")
          var folderDONW = `${userDataPath("downloads")}`
    if (applicationExists(`${folderDONW}`))
       {
        panelbottom_fld = panelbottom.addWidget("org.kde.plasma.folder")
        panelbottom_fld.currentConfigGroup = ["General"];
        panelbottom_fld.writeConfig("url", `${folderDONW}`)
       }
       else
        {
        panelbottom.addWidget("org.kde.plasma.folder")
        }
    panelbottom.addWidget("org.kde.plasma.trash")
     /*separator*/
    panelbottom.addWidget("org.kde.plasma.marginsseparator")
     /*separator /*/

let TexPanel = "Panel"+" "+panelbottom.id
/*cambiando config*/
const config = ConfigFile('plasmashellrc')
config.group = 'PlasmaViews'
const config2 = ConfigFile(config, TexPanel)
config2.writeEntry('floating', 1)
panelbottom.reloadConfig()
plasma.loadSerializedLayout(layout);
