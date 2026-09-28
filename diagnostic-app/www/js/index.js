(function () {
    'use strict';

    var POST_NOTIFICATIONS_MIN_SDK = 33;

    var state = {
        report: null,
        errors: []
    };

    function showError(msg) {
        state.errors.push(String(msg));
        var el = document.getElementById('error-msg');
        el.textContent = state.errors.join('\n');
        el.style.display = 'block';
        console.error('Diagnostic error:', msg);
    }

    function setLoading(show) {
        document.getElementById('loading').style.display = show ? 'block' : 'none';
        document.getElementById('report-container').style.display = show ? 'none' : 'block';
    }

    function nullIfUnknown(value) {
        if (value === null || value === undefined) return null;
        var s = String(value).trim();
        if (s === '' || s.toLowerCase() === 'unknown') return null;
        return s;
    }

    function getDeviceInfo() {
        try {
            return {
                manufacturer: nullIfUnknown(window.device && device.manufacturer),
                model: nullIfUnknown(window.device && device.model),
                serial: nullIfUnknown(window.device && device.serial),
                uuid: nullIfUnknown(window.device && device.uuid)
            };
        } catch (e) {
            showError('device info: ' + e.message);
            return { manufacturer: null, model: null, serial: null, uuid: null };
        }
    }

    function getAndroidInfo() {
        var info = { version: null, sdk: null, cordovaVersion: null, appVersion: null };
        try {
            if (window.device) {
                info.version = nullIfUnknown(device.version);
                if (device.sdkVersion !== undefined && device.sdkVersion !== null) {
                    var sdkNum = parseInt(device.sdkVersion, 10);
                    info.sdk = isNaN(sdkNum) ? null : sdkNum;
                }
                info.cordovaVersion = nullIfUnknown(device.cordova);
            }
        } catch (e) {
            showError('android info: ' + e.message);
        }
        return info;
    }

    function getAppVersion(done) {
        var fallback = function () { done(null); };
        try {
            if (!cordova.getAppVersion || typeof cordova.getAppVersion.getVersionNumber !== 'function') {
                console.error('app version: cordova.getAppVersion unavailable');
                return fallback();
            }
            var p = cordova.getAppVersion.getVersionNumber();
            if (p && typeof p.then === 'function') {
                p.then(function (v) {
                    console.log('app version resolved: ' + v);
                    done(nullIfUnknown(v));
                }, function (err) {
                    console.error('app version rejected: ' + (err && err.message ? err.message : err));
                    fallback();
                });
            } else if (typeof p === 'string') {
                done(nullIfUnknown(p));
            } else {
                console.error('app version: unexpected return ' + typeof p);
                done(null);
            }
        } catch (e) {
            showError('app version: ' + e.message);
            done(null);
        }
    }

    var batteryStatus = { level: null, plugged: null };

    function onBatteryStatus(status) {
        batteryStatus = {
            level: (status && typeof status.level === 'number') ? status.level : null,
            plugged: (status && typeof status.isPlugged === 'boolean') ? status.isPlugged : null
        };
    }

    // The battery plugin registers a BroadcastReceiver on ACTION_BATTERY_CHANGED
    // and emits batterystatus events on changes. A permanent listener keeps the
    // last known value; on a fresh start the sticky broadcast usually delivers
    // one event right after the plugin starts, so we wait briefly for it.
    function getBatteryInfo(done) {
        if (batteryStatus.level !== null || batteryStatus.plugged !== null) {
            return done({ level: batteryStatus.level, plugged: batteryStatus.plugged });
        }
        if (typeof window.addEventListener !== 'function') return done({ level: null, plugged: null });
        var finished = false;
        var handler = function (status) {
            if (finished) return;
            finished = true;
            done({
                level: (status && typeof status.level === 'number') ? status.level : null,
                plugged: (status && typeof status.isPlugged === 'boolean') ? status.isPlugged : null
            });
        };
        try {
            window.addEventListener('batterystatus', handler);
        } catch (e) {
            showError('battery: ' + e.message);
            return done({ level: null, plugged: null });
        }
        setTimeout(function () {
            if (finished) return;
            finished = true;
            window.removeEventListener('batterystatus', handler);
            done({ level: null, plugged: null });
        }, 3000);
    }

    function getNetworkInfo() {
        var info = { online: null, type: null };
        try {
            info.online = (typeof navigator.onLine === 'boolean') ? navigator.onLine : null;
            if (navigator.connection) {
                info.type = nullIfUnknown(navigator.connection.type);
            }
        } catch (e) {
            showError('network: ' + e.message);
        }
        return info;
    }

    function getDisplayInfo() {
        var info = { width: null, height: null, pixelRatio: null, orientation: null };
        try {
            var dpr = (typeof window.devicePixelRatio === 'number') ? window.devicePixelRatio : null;
            // screen.width/height are in CSS pixels; multiply by dpr for the
            // physical screen resolution (off by <=1px due to CSS rounding).
            info.width = (window.screen && window.screen.width && dpr)
                ? Math.round(window.screen.width * dpr) : null;
            info.height = (window.screen && window.screen.height && dpr)
                ? Math.round(window.screen.height * dpr) : null;
            info.pixelRatio = dpr;
            if (window.screen && screen.orientation && screen.orientation.type) {
                info.orientation = nullIfUnknown(screen.orientation.type);
            } else if (info.width && info.height) {
                info.orientation = info.width > info.height ? 'landscape' : 'portrait';
            }
        } catch (e) {
            showError('display: ' + e.message);
        }
        return info;
    }

    function getStorageInfo(done) {
        if (!navigator.storage || typeof navigator.storage.estimate !== 'function') {
            return done({ totalBytes: null, freeBytes: null });
        }
        navigator.storage.estimate().then(function (est) {
            var total = (est && typeof est.quota === 'number') ? est.quota : null;
            var free = (total !== null && est && typeof est.usage === 'number')
                ? Math.max(0, total - est.usage)
                : null;
            done({ totalBytes: total, freeBytes: free });
        }, function (err) {
            showError('storage estimate: ' + (err && err.message ? err.message : err));
            done({ totalBytes: null, freeBytes: null });
        });
    }

    function permissionsApi() {
        return (window.cordova && cordova.plugins && cordova.plugins.permissions) || null;
    }

    function permissionState(permission, done) {
        var api = permissionsApi();
        if (!api) { console.error('permissions api unavailable'); return done('unknown'); }
        try {
            api.checkPermission(permission, function (status) {
                console.log('checkPermission ' + permission + ' -> ' + JSON.stringify(status));
                done(status && status.hasPermission ? 'granted' : 'denied');
            }, function (err) {
                console.error('checkPermission ' + permission + ' error: ' + (err && err.message ? err.message : err));
                done('unknown');
            });
        } catch (e) {
            showError('permission check ' + permission + ': ' + e.message);
            done('unknown');
        }
    }

    function getPermissionsInfo(sdk, done) {
        var api = permissionsApi();
        var result = { camera: 'unknown', microphone: 'unknown', notifications: 'unknown' };
        if (!api) {
            result.notifications = sdk !== null && sdk < POST_NOTIFICATIONS_MIN_SDK ? 'not-applicable' : 'unknown';
            return done(result);
        }
        permissionState(api.CAMERA, function (s) { result.camera = s; });
        permissionState(api.RECORD_AUDIO, function (s) { result.microphone = s; });
        if (sdk !== null && sdk < POST_NOTIFICATIONS_MIN_SDK) {
            result.notifications = 'not-applicable';
            done(result);
        } else {
            permissionState(api.POST_NOTIFICATIONS, function (s) {
                result.notifications = s;
                done(result);
            });
        }
    }

    function requestRuntimePermissions(sdk) {
        var api = permissionsApi();
        if (!api) {
            showError('request permissions: cordova-plugin-android-permissions unavailable');
            return;
        }
        var list = [api.CAMERA, api.RECORD_AUDIO];
        if (sdk === null || sdk >= POST_NOTIFICATIONS_MIN_SDK) {
            list.push(api.POST_NOTIFICATIONS);
        }
        try {
            api.requestPermissions(list, function (status) {
                console.log('requestPermissions result:', JSON.stringify(status));
                refresh();
            }, function (err) {
                showError('request permissions failed: ' + (err && err.message ? err.message : err));
            });
        } catch (e) {
            showError('request permissions: ' + e.message);
        }
    }

    function buildReport(parts) {
        return {
            generatedAt: parts.generatedAt,
            device: parts.device,
            android: parts.android,
            battery: parts.battery,
            network: parts.network,
            display: parts.display,
            storage: parts.storage,
            permissions: parts.permissions
        };
    }

    function refresh() {
        setLoading(true);
        state.errors = [];
        document.getElementById('error-msg').style.display = 'none';

        var device = getDeviceInfo();
        var android = getAndroidInfo();

        getAppVersion(function (appVersion) {
            android.appVersion = appVersion;
            getBatteryInfo(function (battery) {
                var network = getNetworkInfo();
                var display = getDisplayInfo();
                getStorageInfo(function (storage) {
                    getPermissionsInfo(android.sdk, function (permissions) {
                        var report = buildReport({
                            generatedAt: new Date().toISOString(),
                            device: device,
                            android: android,
                            battery: battery,
                            network: network,
                            display: display,
                            storage: storage,
                            permissions: permissions
                        });
                        state.report = report;
                        render(report);
                        setLoading(false);
                    });
                });
            });
        });
    }

    function fmtBytes(n) {
        if (n === null || n === undefined) return '-';
        var units = ['B', 'KB', 'MB', 'GB', 'TB'];
        var v = n;
        var i = 0;
        while (v >= 1024 && i < units.length - 1) { v /= 1024; i++; }
        return v.toFixed(v >= 100 || i === 0 ? 0 : 1) + ' ' + units[i];
    }

    function fmtValue(v) {
        if (v === null || v === undefined) return '-';
        return String(v);
    }

    function permClass(v) {
        return 'perm-' + String(v);
    }

    function render(report) {
        var d = report.device, a = report.android, b = report.battery,
            n = report.network, di = report.display, s = report.storage, p = report.permissions;

        document.getElementById('app-version').textContent =
            a.appVersion ? 'v' + a.appVersion : '';

        document.getElementById('d-manufacturer').textContent = fmtValue(d.manufacturer);
        document.getElementById('d-model').textContent = fmtValue(d.model);
        document.getElementById('d-serial').textContent = fmtValue(d.serial);
        document.getElementById('d-uuid').textContent = fmtValue(d.uuid);

        document.getElementById('a-version').textContent = fmtValue(a.version);
        document.getElementById('a-sdk').textContent = fmtValue(a.sdk);
        document.getElementById('a-cordova').textContent = fmtValue(a.cordovaVersion);
        document.getElementById('a-app').textContent = fmtValue(a.appVersion);

        document.getElementById('b-level').textContent =
            (b.level === null || b.level === undefined) ? '-' : b.level + ' %';
        document.getElementById('b-plugged').textContent =
            (b.plugged === null || b.plugged === undefined) ? '-' : (b.plugged ? 'yes' : 'no');

        document.getElementById('n-online').textContent =
            (n.online === null || n.online === undefined) ? '-' : (n.online ? 'yes' : 'no');
        document.getElementById('n-type').textContent = fmtValue(n.type);

        document.getElementById('di-resolution').textContent =
            (di.width === null || di.height === null) ? '-' : di.width + ' x ' + di.height;
        document.getElementById('di-pixelratio').textContent = fmtValue(di.pixelRatio);
        document.getElementById('di-orientation').textContent = fmtValue(di.orientation);

        document.getElementById('s-total').textContent = fmtBytes(s.totalBytes);
        document.getElementById('s-free').textContent = fmtBytes(s.freeBytes);

        var pc = document.getElementById('p-camera');
        pc.textContent = p.camera; pc.className = permClass(p.camera);
        var pm = document.getElementById('p-microphone');
        pm.textContent = p.microphone; pm.className = permClass(p.microphone);
        var pn = document.getElementById('p-notifications');
        pn.textContent = p.notifications; pn.className = permClass(p.notifications);

        document.getElementById('json-report').textContent = JSON.stringify(report, null, 2);
    }

    function copyJson() {
        var text = state.report ? JSON.stringify(state.report, null, 2) : '';
        function fallbackCopy() {
            var ta = document.createElement('textarea');
            ta.value = text;
            document.body.appendChild(ta);
            ta.select();
            try { document.execCommand('copy'); } catch (e) { showError('copy failed: ' + e.message); }
            document.body.removeChild(ta);
        }
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text).catch(fallbackCopy);
        } else {
            fallbackCopy();
        }
    }

    function onDeviceReady() {
        console.log('deviceready: cordova ' + cordova.version + ' on ' + cordova.platformId);
        document.getElementById('app-version').textContent = '';

        document.getElementById('refresh-btn').addEventListener('click', refresh);
        document.getElementById('copy-json-btn').addEventListener('click', copyJson);
        document.getElementById('request-permissions-btn').addEventListener('click', function () {
            var sdk = null;
            try { sdk = (window.device && typeof device.sdkVersion === 'number') ? device.sdkVersion : null; }
            catch (e) { sdk = null; }
            requestRuntimePermissions(sdk);
        });

        window.addEventListener('orientationchange', function () {
            if (state.report) {
                state.report.display = getDisplayInfo();
                render(state.report);
            }
        });

        window.addEventListener('batterystatus', onBatteryStatus);
        window.addEventListener('batterystatus', function () {
            if (state.report) refresh();
        });
        window.addEventListener('online', function () {
            if (state.report) refresh();
        });
        window.addEventListener('offline', function () {
            if (state.report) refresh();
        });

        refresh();
    }

    document.addEventListener('deviceready', onDeviceReady, false);
})();
