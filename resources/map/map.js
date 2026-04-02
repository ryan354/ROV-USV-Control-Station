// RovoControl Map - Leaflet with satellite + street layers
(function() {
    'use strict';

    const VEHICLE_COLORS = { 1: '#00bcd4', 2: '#ff9800', 0: '#9e9e9e' };
    const VEHICLE_LABELS = { 1: 'ROV', 2: 'USV', 0: 'UNK' };
    const TRACK_MAX_POINTS = 2000;

    let map = null;
    let bridge = null;
    const vehicles = {};

    // ─── Initialize Map ─────────────────────────────────────────────────────
    function initMap() {
        map = L.map('map', {
            center: [0, 0],
            zoom: 3,
            zoomControl: true,
            attributionControl: true
        });

        // ── Tile Layers ──────────────────────────────────────────────────────

        // Google Satellite
        var googleSat = L.tileLayer('https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}', {
            maxZoom: 22,
            attribution: 'Google Satellite'
        });

        // Google Hybrid (satellite + labels)
        var googleHybrid = L.tileLayer('https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}', {
            maxZoom: 22,
            attribution: 'Google Hybrid'
        });

        // Google Streets
        var googleStreets = L.tileLayer('https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}', {
            maxZoom: 22,
            attribution: 'Google Streets'
        });

        // Google Terrain
        var googleTerrain = L.tileLayer('https://mt1.google.com/vt/lyrs=p&x={x}&y={y}&z={z}', {
            maxZoom: 22,
            attribution: 'Google Terrain'
        });

        // Esri Satellite (good alternative)
        var esriSat = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
            maxZoom: 20,
            attribution: 'Esri Satellite'
        });

        // OpenStreetMap (via CartoDB for dark theme)
        var cartoDark = L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
            maxZoom: 20,
            attribution: '&copy; CARTO &copy; OSM',
            subdomains: 'abcd'
        });

        // Default to Google Hybrid
        googleHybrid.addTo(map);

        // Layer control
        var baseLayers = {
            "Satellite + Labels": googleHybrid,
            "Satellite": googleSat,
            "Esri Satellite": esriSat,
            "Streets": googleStreets,
            "Terrain": googleTerrain,
            "Dark": cartoDark
        };

        L.control.layers(baseLayers, null, {
            position: 'topright',
            collapsed: true
        }).addTo(map);

        // ── Scale bar ────────────────────────────────────────────────────────
        L.control.scale({ imperial: false, position: 'bottomright' }).addTo(map);

        console.log('Map initialized with Google Hybrid');
    }

    // ─── Vehicle SVG Icon ───────────────────────────────────────────────────
    function createVehicleSvg(color, heading) {
        var r = heading || 0;
        return '<svg width="44" height="44" viewBox="0 0 44 44" xmlns="http://www.w3.org/2000/svg">' +
            '<circle cx="22" cy="22" r="18" fill="rgba(0,0,0,0.4)" stroke="' + color + '" stroke-width="2"/>' +
            '<g transform="rotate(' + r + ', 22, 22)">' +
            '<polygon points="22,4 13,30 22,26 31,30" fill="' + color + '" stroke="white" stroke-width="0.5" opacity="0.95"/>' +
            '</g>' +
            '<circle cx="22" cy="22" r="3" fill="white"/>' +
            '</svg>';
    }

    // ─── Create Vehicle Marker ──────────────────────────────────────────────
    function createVehicleMarker(sysId, lat, lon, heading, vehicleType) {
        var color = VEHICLE_COLORS[vehicleType] || VEHICLE_COLORS[0];
        var label = VEHICLE_LABELS[vehicleType] || VEHICLE_LABELS[0];

        var icon = L.divIcon({
            className: '',
            html: createVehicleSvg(color, heading),
            iconSize: [44, 44],
            iconAnchor: [22, 22]
        });

        var marker = L.marker([lat, lon], {
            icon: icon,
            zIndexOffset: vehicleType === 1 ? 1000 : 500
        }).addTo(map);

        var track = L.polyline([], {
            color: color, weight: 3, opacity: 0.8, smoothFactor: 1
        }).addTo(map);

        marker.bindTooltip(
            '<div class="vehicle-label">' + label + '-' + sysId + '</div>',
            { permanent: true, direction: 'top', offset: [0, -28], className: 'vehicle-tooltip' }
        );

        vehicles[sysId] = { marker: marker, track: track, vehicleType: vehicleType, heading: heading };
        console.log('Vehicle ' + label + '-' + sysId + ' at ' + lat.toFixed(6) + ',' + lon.toFixed(6));
    }

    // ─── Update Vehicle Position ────────────────────────────────────────────
    function updateVehicle(sysId, lat, lon, heading, vehicleType) {
        if (!map) return;
        if (lat === 0 && lon === 0) return;

        var latlng = L.latLng(lat, lon);

        if (!vehicles[sysId]) {
            createVehicleMarker(sysId, lat, lon, heading, vehicleType);
            map.setView(latlng, 17);
        } else {
            var v = vehicles[sysId];
            var color = VEHICLE_COLORS[vehicleType] || VEHICLE_COLORS[0];

            v.marker.setLatLng(latlng);
            v.marker.setIcon(L.divIcon({
                className: '',
                html: createVehicleSvg(color, heading),
                iconSize: [44, 44],
                iconAnchor: [22, 22]
            }));

            v.track.addLatLng(latlng);
            var pts = v.track.getLatLngs();
            if (pts.length > TRACK_MAX_POINTS) {
                v.track.setLatLngs(pts.slice(-TRACK_MAX_POINTS));
            }
            v.heading = heading;
        }
    }

    // ─── Map Controls ───────────────────────────────────────────────────────
    function fitAll() {
        if (!map) return;
        var bounds = [];
        for (var id in vehicles) { bounds.push(vehicles[id].marker.getLatLng()); }
        if (bounds.length > 0) { map.fitBounds(L.latLngBounds(bounds).pad(0.3)); }
    }

    function clearAllTracks() {
        for (var id in vehicles) { vehicles[id].track.setLatLngs([]); }
    }

    // ─── Global API (called from QML via runJavaScript) ─────────────────────
    window.updateVehiclePosition = function(sysId, lat, lon, heading, vehicleType) {
        updateVehicle(sysId, lat, lon, heading, vehicleType);
    };
    window.fitAllVehicles = fitAll;
    window.clearAllTracks = clearAllTracks;

    // ─── QWebChannel (optional bridge) ──────────────────────────────────────
    function connectBridge() {
        if (typeof QWebChannel === 'undefined' || typeof qt === 'undefined') {
            console.log('QWebChannel not available, using direct JS calls');
            return;
        }
        new QWebChannel(qt.webChannelTransport, function(channel) {
            bridge = channel.objects.mapBridge;
            if (!bridge) return;
            bridge.updateMarker.connect(function(s,la,lo,h,t) { updateVehicle(s,la,lo,h,t); });
            bridge.clearAll.connect(clearAllTracks);
            bridge.fitBounds.connect(fitAll);
            bridge.mapReady();
            console.log('QWebChannel connected');
        });
    }

    // ─── Init ───────────────────────────────────────────────────────────────
    document.addEventListener('DOMContentLoaded', function() {
        initMap();
        map.on('click', function(e) { if (bridge) bridge.mapClicked(e.latlng.lat, e.latlng.lng); });
        connectBridge();
    });

})();
