const { app, BrowserWindow, shell } = require('electron');

const DELUXE_URL = 'https://zacharyceiley-jpg.github.io/secretunblockeddeluxe/';

function createWindow() {
  const win = new BrowserWindow({
    width: 1440,
    height: 900,
    minWidth: 900,
    minHeight: 620,
    title: 'Secret Unblocked Deluxe',
    backgroundColor: '#0c0e12',
    autoHideMenuBar: true,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true
    }
  });

  win.webContents.setWindowOpenHandler(({ url }) => {
    if (url.startsWith('https://') || url.startsWith('http://')) shell.openExternal(url);
    return { action: 'deny' };
  });

  win.webContents.on('will-navigate', (event, url) => {
    if (url === DELUXE_URL || url.startsWith(DELUXE_URL + '#')) return;
    if (url.startsWith('https://zacharyceiley-jpg.github.io/secretunblockeddeluxe/')) return;
    event.preventDefault();
    if (url.startsWith('https://') || url.startsWith('http://')) shell.openExternal(url);
  });

  win.loadURL(DELUXE_URL);
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
