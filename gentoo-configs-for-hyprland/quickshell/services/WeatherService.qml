pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Open-Meteo (free, keyless). Refreshes every 15 minutes and when the location changes.
Singleton {
    id: root

    property bool ready: false
    property bool failed: false
    property real temp: 0
    property real feels: 0
    property real humidity: 0
    property real wind: 0
    property real hi: 0
    property real lo: 0
    property int code: 0
    property bool isDay: true
    property var forecast: []
    property date updated: new Date()

    readonly property string unit: Config.useFahrenheit ? "°F" : "°C"
    readonly property string desc: describe(code)
    readonly property string kind: kindOf(code)

    readonly property string url:
        "https://api.open-meteo.com/v1/forecast?latitude=" + Config.weatherLat + "&longitude=" + Config.weatherLon +
        "&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,is_day" +
        "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max" +
        "&timezone=auto&forecast_days=6&wind_speed_unit=kmh" +
        (Config.useFahrenheit ? "&temperature_unit=fahrenheit" : "") +
        (Config.weatherModel !== "" ? "&models=" + Config.weatherModel : "")

    function describe(c) {
        if (c === 0) return "Clear sky";
        if (c === 1) return "Mainly clear";
        if (c === 2) return "Partly cloudy";
        if (c === 3) return "Overcast";
        if (c === 45 || c === 48) return "Fog";
        if (c >= 51 && c <= 57) return "Drizzle";
        if (c >= 61 && c <= 67) return "Rain";
        if (c >= 71 && c <= 77) return "Snow";
        if (c >= 80 && c <= 82) return "Rain showers";
        if (c === 85 || c === 86) return "Snow showers";
        if (c >= 95) return "Thunderstorm";
        return "Unknown";
    }

    function kindOf(c) {
        if (c === 0 || c === 1) return "clear";
        if (c === 2) return "partly";
        if (c === 3) return "cloud";
        if (c === 45 || c === 48) return "fog";
        if ((c >= 51 && c <= 67) || (c >= 80 && c <= 82)) return "rain";
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "snow";
        if (c >= 95) return "storm";
        return "cloud";
    }

    function parse(text) {
        try {
            const j = JSON.parse(text);
            const c = j.current, d = j.daily;
            temp = c.temperature_2m;
            feels = c.apparent_temperature;
            humidity = c.relative_humidity_2m;
            wind = c.wind_speed_10m;
            code = c.weather_code;
            isDay = c.is_day === 1;
            hi = d.temperature_2m_max[0];
            lo = d.temperature_2m_min[0];
            const out = [];
            for (let i = 1; i < d.time.length; i++) {
                out.push({
                    day: Qt.formatDate(new Date(d.time[i] + "T12:00:00"), "ddd"),
                    code: d.weather_code[i],
                    hi: d.temperature_2m_max[i],
                    lo: d.temperature_2m_min[i],
                    rain: d.precipitation_probability_max[i]
                });
            }
            forecast = out;
            updated = new Date();
            ready = true;
            failed = false;
        } catch (e) {
            failed = true;
        }
    }

    function refresh() { if (!fetcher.running) fetcher.running = true; }
    onUrlChanged: refresh()

    Process {
        id: fetcher
        command: ["curl", "-sf", "--max-time", "12", root.url]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
        onExited: code => { if (code !== 0) root.failed = true; }
    }

    Timer { interval: 900000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
