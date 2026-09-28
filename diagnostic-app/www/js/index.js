document.addEventListener('deviceready', onDeviceReady, false);

var currentReport = null;

function showError(msg) {
    var el = document.getElementById('error-msg');
    el.textContent = msg;
    el.style.display = 'block';
    console.error('Diagnostic error: ' + msg);
}

function setLoading(show) {
    document.getElementById('loading').style.display = show ? 'block' : 'none';
}

function onDeviceReady() {
    console.log('Running cordova-' + cordova.platformId + '@' + cordova.version);
    document.getElementById('deviceready').classList.add('ready');
    setLoading(true);
    generateReport();
}

function getConnectionTypeName(type) {
    var map = {
        'none': 'No connection', 'unknown': 'Unknown', 'ethernet': 'Ethernet',
        'wifi': 'WiFi', 'cell_2g': 'Cell 2G', 'cell_3g': 'Cell 3G',
        'cell_4g': 'Cell 4G', 'cell_5g': 'Cell 5G', 'cell': 'Cellular'
    };
    return map[type] || type;
}

function getBatteryInfo(callback) {
    var level = null;
    var isPlugged = null;
    var handler = function(info) {
        level = info.level;
        isPlugged = info.isPlugged;
        window.removeEventListener('batterystatus', handler);
        callback({ level: level, isPlugged: isPlugged });
    };
    window.addEventListener('batterystatus', handler);
    setTimeout(function() {
        if (level === null) {
            window.removeEventListener('batterystatus', handler);
            callback({ level: null, isPlugged: null });
        }
    }, 2000);
}

function getNetworkInfo() {
    var conn = navigator.connection || navigator.webkitConnection;
    if (conn) {
        return { online: navigator.onLine, type: getConnectionTypeName(conn.type) };
    }
    return { online: navigator.onLine, type: null };
}

function getDisplayInfo() {
    var orientation = 'unknown';
    if (screen && screen.orientation && screen.orientation.type) {
        orientation = screen.orientation.type;
    } else if (window.orientation !== undefined) {
        orientation = (window.orientation === 0 || window.orientation === 180) ? 'portrait' : 'landscape';
    }
    return {
        width: screen.width || null,
        height: screen.height || null,
        pixelRatio: window.devicePixelRatio || null,
        orientation: orientation
    };
}

function getStorageInfo(callback) {
    if (window.resolveLocalFileSystemURL && cordova.file.dataDirectory) {
        window.resolveLocalFileSystemURL(cordova.file.dataDirectory, function(entry) {
            entry.getMetadata(function(metadata) {
                callback({ totalBytes: metadata.size || null, freeBytes: metadata.freeSize || null });
            }, function() { callback({ totalBytes: null, freeBytes: null }); });
        }, function() { callback({ totalBytes: null, freeBytes: null }); });
    } else {
        callback({ totalBytes: null, freeBytes: null });
    }
}

function getPermissionsInfo(callback) {
    var result = { camera: 'unknown', microphone: 'unknown', notifications: 'unknown' };
    if (navigator.permissions && navigator.permissions.query) {
        Promise.all([
            navigator.permissions.query({ name: 'camera' }).then(function(p) { result.camera = p.state; }).catch(function() {}),
            navigator.permissions.query({ name: 'microphone' }).then(function(p) { result.microphone = p.state; }).catch(function() {}),
            navigator.permissions.query({ name: 'android.permission.POST_NOTIFICATIONS' }).then(function(p) { result.notifications = p.state; }).catch(function() { result.notifications = 'unknown'; })
        ]).then(function() { callback(result); });
    } else {
        callback(result);
    }
}

function buildReport(deviceInfo, batteryInfo, networkInfo, displayInfo, storageInfo, permissionsInfo) {
    var now = new Date();
    return {
        generatedAt: now.toISOString(),
        device: {
            manufacturer: deviceInfo.manufacturer || null,
            model: deviceInfo.model || null,
            serial: deviceInfo.serial || null,
            uuid: deviceInfo.uuid || null
        },
        android: {
            version: deviceInfo.version || null,
            sdk: deviceInfo.sdkVersion ? parseInt(deviceInfo.sdkVersion) : null,
            cordovaVersion: deviceInfo.cordova || null,
            appVersion: '1.0.0'
        },
        battery: { level: batteryInfo.level, plugged: batteryInfo.isPlugged },
        network: { online: networkInfo.online, type: networkInfo.type },
        display: { width: displayInfo.width, height: displayInfo.height, pixelRatio: displayInfo.pixelRatio, orientation: displayInfo.orientation },
        storage: { totalBytes: storageInfo.totalBytes, freeBytes: storageInfo.freeBytes },
        permissions: permissionsInfo,
        adb: null
    };
}

function renderReport(report) {
    currentReport = report;
    var container = document.getElementById('report-container');
    container.style.display = 'block';

    document.getElementById('report-summary').innerHTML = '<h2>Device Summary</h2>' +
        '<p><strong>Manufacturer:</strong> ' + (report.device.manufacturer || 'N/A') + '</p>' +
        '<p><strong>Model:</strong> ' + (report.device.model || 'N/A') + '</p>' +
        '<p><strong>Android Version:</strong> ' + (report.android.version || 'N/A') + '</p>' +
        '<p><strong>Battery:</strong> ' + (report.battery.level !== null ? report.battery.level + '%' : 'N/A') + ' (' + (report.battery.isPlugged !== null ? (report.battery.isPlugged ? 'Charging' : 'Discharging') : 'N/A') + ')</p>' +
        '<p><strong>Network:</strong> ' + (report.network.type || 'N/A') + ' (' + (report.network.online !== null ? (report.network.online ? 'Online' : 'Offline') : 'N/A') + ')</p>';

    document.getElementById('report-details').innerHTML = '<h2>Details</h2>' +
        '<p><strong>Serial:</strong> ' + (report.device.serial || 'N/A') + '</p>' +
        '<p><strong>UUID:</strong> ' + (report.device.uuid || 'N/A') + '</p>' +
        '<p><strong>Cordova Version:</strong> ' + (report.android.cordovaVersion || 'N/A') + '</p>' +
        '<p><strong>App Version:</strong> ' + (report.android.appVersion || 'N/A') + '</p>' +
        '<p><strong>Screen:</strong> ' + (report.display.width || '?') + 'x' + (report.display.height || '?') + ' @ ' + (report.display.pixelRatio || '?') + 'x</p>' +
        '<p><strong>Orientation:</strong> ' + (report.display.orientation || 'N/A') + '</p>' +
        '<p><strong>Storage:</strong> ' + (report.storage.totalBytes ? (report.storage.totalBytes / 1073741824).toFixed(1) + ' GB' : 'N/A') + ' total / ' + (report.storage.freeBytes ? (report.storage.freeBytes / 1073741824).toFixed(1) + ' GB' : 'N/A') + ' free</p>';

    var permsDiv = document.getElementById('permissions-list');
    var permLabels = { camera: 'Camera', microphone: 'Microphone', notifications: 'Notifications' };
    var permHtml = '';
    for (var key in report.permissions) {
        if (report.permissions.hasOwnProperty(key)) {
            permHtml += '<p><strong>' + (permLabels[key] || key) + ':</strong> ' + report.permissions[key] + '</p>';
        }
    }
    permsDiv.innerHTML = permHtml;

    document.getElementById('json-report').textContent = JSON.stringify(report, null, 2);
}

function generateReport() {
    setLoading(true);
    document.getElementById('report-container').style.display = 'none';

    var deviceInfo = {
        manufacturer: device.manufacturer || null,
        model: device.model || null,
        uuid: device.uuid || null,
        serial: device.serial || null,
        version: device.version || null,
        cordova: device.cordova || null,
        sdkVersion: device.sdkVersion || null
    };

    getBatteryInfo(function(batteryInfo) {
        var networkInfo = getNetworkInfo();
        var displayInfo = getDisplayInfo();
        getStorageInfo(function(storageInfo) {
            getPermissionsInfo(function(permissionsInfo) {
                try {
                    var report = buildReport(deviceInfo, batteryInfo, networkInfo, displayInfo, storageInfo, permissionsInfo);
                    renderReport(report);
                    setLoading(false);
                } catch (err) {
                    showError('Failed to build report: ' + err.message);
                    setLoading(false);
                }
            });
        });
    });
}

function requestPermissions() {
    var requested = false;
    if (navigator.permissions && navigator.permissions.request) {
        navigator.permissions.request({ name: 'camera' }).then(function() {
            requested = true; showError('Camera permission requested');
        }).catch(function() {});
        navigator.permissions.request({ name: 'microphone' }).then(function() {
            requested = true; showError('Microphone permission requested');
        }).catch(function() {});
        try {
            navigator.permissions.request({ name: 'android.permission.POST_NOTIFICATIONS' }).then(function() {
                requested = true; showError('Notifications permission requested');
            }).catch(function() {});
        } catch(e) {}
    }
    if (!requested) {
        showError('Could not request permissions. Please check app settings.');
    }
}

function copyJSON() {
    if (!currentReport) { showError('No report to copy'); return; }
    var jsonText = JSON.stringify(currentReport, null, 2);
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(jsonText).then(function() { showError('JSON copied to clipboard'); }).catch(function() { fallbackCopy(jsonText); });
    } else { fallbackCopy(jsonText); }
}

function fallbackCopy(text) {
    var textarea = document.createElement('textarea');
    textarea.value = text; textarea.style.position = 'fixed'; textarea.style.opacity = '0';
    document.body.appendChild(textarea); textarea.select();
    try { document.execCommand('copy'); showError('JSON copied to clipboard'); } catch(e) { showError('Failed to copy'); }
    document.body.removeChild(textarea);
}

document.addEventListener('deviceready', function() {
    document.getElementById('request-permissions-btn').addEventListener('click', requestPermissions);
    document.getElementById('copy-json-btn').addEventListener('click', copyJSON);
    document.getElementById('refresh-btn').addEventListener('click', generateReport);
}, false);
