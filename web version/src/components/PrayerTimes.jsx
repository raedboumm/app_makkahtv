import React, { useEffect, useState, useMemo } from "react";
import "../styles/prayerTimes.css";
import logo from "../assets/smallIcon.png"; // keep this path as you have it
import { PrayerTimes as AdhanPrayerTimes, Coordinates, CalculationMethod, Madhab } from "adhan";

// Helper to format Date objects into HH:MM (24h) respecting Asia/Riyadh timezone
function formatTime(date) {
  if (!date) return "--:--";
  try {
    return date.toLocaleTimeString("en-GB", {
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
      timeZone: "Asia/Riyadh",
    });
  } catch (_) {
    // Fallback without timezone (shouldn't happen in modern browsers)
    const h = date.getHours().toString().padStart(2, "0");
    const m = date.getMinutes().toString().padStart(2, "0");
    return `${h}:${m}`;
  }
}

// Makkah coordinates
const MAKKAH_COORDS = new Coordinates(21.3891, 39.8579);

const PrayerTimes = () => {
  const [today, setToday] = useState(() => new Date());

  // Recompute the prayer times whenever the date changes (at midnight) or hourly for safety
  useEffect(() => {
    const minuteTimer = setInterval(() => {
      setToday(new Date());
    }, 60 * 1000); // update each minute so highlighting can be added later
    return () => clearInterval(minuteTimer);
  }, []);

  const adhanTimes = useMemo(() => {
    try {
      // Use Umm Al-Qura method which is standard for Saudi Arabia
      const params = CalculationMethod.UmmAlQura();
      params.madhab = Madhab.Shafi; // Shafi madhab common for Makkah (affects Asr)
      const pt = new AdhanPrayerTimes(MAKKAH_COORDS, today, params);
      return {
        fajr: pt.fajr,
        sunrise: pt.sunrise,
        dhuhr: pt.dhuhr,
        asr: pt.asr,
        maghrib: pt.maghrib,
        isha: pt.isha,
      };
    } catch (e) {
      console.error("Failed to compute prayer times", e);
      return {};
    }
  }, [today]);

  const times = [
    { name: "الفجر", key: "fajr", time: formatTime(adhanTimes.fajr) },
    { name: "الشروق", key: "sunrise", time: formatTime(adhanTimes.sunrise) },
    { name: "الظهر", key: "dhuhr", time: formatTime(adhanTimes.dhuhr) },
    { name: "العصر", key: "asr", time: formatTime(adhanTimes.asr) },
    { name: "المغرب", key: "maghrib", time: formatTime(adhanTimes.maghrib) },
    { name: "العشاء", key: "isha", time: formatTime(adhanTimes.isha) },
  ];

  return (
    <div className="prayer-box">
      <h3 className="prayer-title">
        <span className="prayer-logoWrap">
          <img style={{ width: "70px", height: "70px" }} src={logo} alt="makkah logo" />
        </span>
        مواقيت الصلاة بمكة المكرمة
      </h3>
      <table className="prayer-table">
        <tbody>
          {times.map((row) => (
            <tr key={row.key}>
              <td className="prayer-name">{row.name}</td>
              <td className="prayer-time">{row.time}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default PrayerTimes;
