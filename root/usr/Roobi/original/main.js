const { app, BrowserWindow, screen } = require('electron')
const createWindow = () => {

  const mainScreen = screen.getPrimaryDisplay();
  const { width, height } = mainScreen.size;
  const initialZoomFactor = calculateInitialZoomFactor(width, height);
  const win = new BrowserWindow({
    frame:false,
    // fullscreen:true,
    webPreferences: {
      hardwareAcceleration: true,
      zoomFactor:initialZoomFactor
    },
  })
  win.setSize(width, height);
  win.setPosition(0,0)
  win.setFullScreen(true)
  win.loadURL("http://127.0.0.1")
  function calculateInitialZoomFactor(screenWidth, screenHeight) {
    const baseWidth = 1920;
    const baseHeight = 1080;
    const scaleWidth = screenWidth / baseWidth;
    const scaleHeight = screenHeight / baseHeight;
    return Math.min(scaleWidth, scaleHeight);
  }

}
app.whenReady().then(() => {
  createWindow()
})