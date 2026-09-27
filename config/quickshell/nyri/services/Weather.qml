pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Open-Meteo, no key. One request every 30 minutes (and on demand if the
// data is older than 15 minutes when the dashboard opens).
Singleton {
    id: root

    property var current: null          // { temp, feels, humidity, wind, code, day }
    property var daily: []              // [{ date, code, max, min }]
    property real fetchedAt: 0
    readonly property bool ready: current !== null

    readonly property string city: Config.o.weather.city

    function describe(code, day) {
        const d = day !== false;
        if (code === 0) return { icon: d ? "clear_day" : "clear_night", text: "Ясно" };
        if (code <= 2) return { icon: d ? "partly_cloudy_day" : "partly_cloudy_night", text: "Переменная облачность" };
        if (code === 3) return { icon: "cloud", text: "Пасмурно" };
        if (code <= 48) return { icon: "foggy", text: "Туман" };
        if (code <= 57) return { icon: "rainy_light", text: "Морось" };
        if (code <= 67) return { icon: code >= 65 ? "rainy_heavy" : "rainy", text: "Дождь" };
        if (code <= 77) return { icon: "weather_snowy", text: "Снег" };
        if (code <= 82) return { icon: "rainy_heavy", text: "Ливень" };
        if (code <= 86) return { icon: "weather_snowy", text: "Снегопад" };
        return { icon: "thunderstorm", text: "Гроза" };
    }

    function refresh() {
        const c = Config.o.weather;
        fetcher.command = ["curl", "-s", "--max-time", "15",
            "https://api.open-meteo.com/v1/forecast?latitude=" + c.lat + "&longitude=" + c.lon
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=5&wind_speed_unit=ms"];
        fetcher.running = true;
    }

    function refreshIfStale() {
        if (Date.now() - fetchedAt > 15 * 60000)
            refresh();
    }

    Process {
        id: fetcher
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    const c = d.current;
                    root.current = {
                        temp: Math.round(c.temperature_2m), feels: Math.round(c.apparent_temperature),
                        humidity: c.relative_humidity_2m, wind: c.wind_speed_10m,
                        code: c.weather_code, day: c.is_day === 1
                    };
                    root.daily = d.daily.time.map((t, i) => ({
                        date: new Date(t + "T12:00:00"), code: d.daily.weather_code[i],
                        max: Math.round(d.daily.temperature_2m_max[i]), min: Math.round(d.daily.temperature_2m_min[i])
                    }));
                    root.fetchedAt = Date.now();
                } catch (e) {
                    console.warn("weather: bad response");
                }
            }
        }
    }

    Timer {
        running: true
        interval: 30 * 60000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
