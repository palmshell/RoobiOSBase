const { app, BrowserWindow, screen, globalShortcut, Menu, ipcMain  } = require('electron')
const { exec, spawn  } = require('child_process');
const {promisify} = require("util");
const _exec = promisify(require('node:child_process').exec);
const {join} = require("path");
const {fs} = require('fs')
const readline = require('readline');

let mainWindow
const displayList = []
let current = 1

Menu.setApplicationMenu(null)
function Equal(obj1, obj2) {
  if (obj1 === obj2) {
    return true;
  }

  if (typeof obj1 !== 'object' || obj1 === null ||
    typeof obj2 !== 'object' || obj2 === null) {
    return false;
  }

  const keys1 = Object.keys(obj1);
  const keys2 = Object.keys(obj2);

  if (keys1.length !== keys2.length) {
    return false;
  }

  for (let key of keys1) {
    if (!keys2.includes(key) || !Equal(obj1[key], obj2[key])) {
      return false;
    }
  }
  return true;
}

function calculateInitialZoomFactor(screenWidth, screenHeight) {
  const baseWidth = 1920;
  const baseHeight = 1080;
  const scaleWidth = screenWidth / baseWidth;
  const scaleHeight = screenHeight / baseHeight;
  return Math.min(scaleWidth, scaleHeight);
}

const createWindow = () => {

  const mainScreen = screen.getPrimaryDisplay();

  const { width, height } = mainScreen.size;
  mainWindow = new BrowserWindow({
    frame:false,
    resizable: false,
    webPreferences: {
      hardwareAcceleration: true,
    },
  })
  mainWindow.loadURL("http://127.0.0.1")
}

const createOtherWindow = (bounds, id) => {
  const initialZoomFactor = calculateInitialZoomFactor(bounds.width, bounds.height);
  const win = new BrowserWindow({
    frame:false,
    resizable: false,
    webPreferences: {
      preload: join(__dirname, 'preload.js')
    },
  })
  win.webContents.on('did-finish-load', () => {
    const renderProcess = win.webContents;
    renderProcess.setZoomFactor(calculateInitialZoomFactor(bounds.width, bounds.height))
  });
  win.setBounds(bounds)
  let blank_url = join(__dirname, 'blank.html');
  blank_url = "file://" + blank_url + "?id=" + id
  win.loadURL(blank_url)
  return win
}

const setWindow = (bounds, instance) => {
  instance.webContents.on('did-finish-load', () => {
    const renderProcess = instance.webContents;
    renderProcess.setZoomFactor(calculateInitialZoomFactor(bounds.width, bounds.height))
  });
  const renderProcess = instance.webContents;
  renderProcess.setZoomFactor(calculateInitialZoomFactor(bounds.width, bounds.height))
  instance.setBounds(bounds)
}

const processDisplay = () =>{
  let isShow = false
  let displays = screen.getAllDisplays();
  for(let i = displays.length; i < displayList.length; i++){
    displayList[i].instance.close()
    displayList[i] = null
    globalShortcut.unregister('CommandOrControl+' + (i + 1));
  }
  for (let i = displayList.length - 1; i >= 0; i--) {
    if (displayList[i] === null) {
      displayList.splice(i, 1);
    }
  }


  for(let i in displays){
    i = Number(i)
    const bounds = displays[i].bounds
    if (displayList[i]) {
      if(!Equal(displayList[i].bounds, bounds)){
        displayList[i].instance.close()
        displayList[i] = {
          instance: createOtherWindow(bounds, i + 1),
          bounds
        }

      }
    }else{
      displayList[i] = {
        instance: createOtherWindow(bounds, i + 1),
        bounds
      }
      globalShortcut.register('CommandOrControl+' + (i + 1), () => {
        current = i + 1
        processDisplay()
      });
    }
    if (current - 1 === i) {
      isShow = true
      displayList[i].instance.hide()
      setWindow(bounds, mainWindow)
      exec('/usr/Roobi/xdotool mousemove ' +(bounds.x + bounds.width / 2) + ' ' + (bounds.y + bounds.height / 2), (error, stdout, stderr) => {})
    }else {
      displayList[i].instance.show()
      setWindow(bounds, displayList[i].instance)
    }
  }
  if(!isShow){
    current = 1
    processDisplay()
  }
}

let timeout
function screenChange() {
  clearTimeout(timeout)
  timeout = setTimeout(processDisplay, 200)
}

let hide = false
app.whenReady().then(() => {
  console.log("start")
  const child = spawn('udevadm monitor -k -s drm', {shell:true})
  let screen_timeout
  child.stdout.on('data', data=>{
    clearTimeout(screen_timeout)
    screen_timeout = setTimeout(async ()=>{
      const { stdout, stderr } = await _exec("xrandr | awk '/ connected/{print $1}'")
      const screens = stdout.trim().split('\n')
      let cmd = "xrandr "
      if(screens.length > 0){
        cmd += "--output " + screens[0] + " --auto"
      }
      if(screens.length > 1){
        for(let i = 1; i < screens.length; i++){
          cmd += " --output " + screens[i] + " --auto " + "--right-of " + screens[i - 1]
        }
      }
      console.log(cmd)
      exec(cmd, (exception, stdout) => {
        console.log(stdout)
      })
    }, 100)
  })

  ipcMain.on('switch', (event, _id) => {
    current = Number(_id)
    processDisplay()
  })

  createWindow()
  processDisplay()
  globalShortcut.register('CommandOrControl+Q', () => {
    app.quit()
  });


  screen.on('display-added', screenChange)

  screen.on('display-removed', screenChange)

  screen.on('display-metrics-changed', screenChange)
})