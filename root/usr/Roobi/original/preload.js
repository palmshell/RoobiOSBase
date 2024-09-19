const { contextBridge, ipcRenderer } = require('electron/renderer')

contextBridge.exposeInMainWorld('electronAPI', {
  switch: (id) => ipcRenderer.send('switch', id)
})