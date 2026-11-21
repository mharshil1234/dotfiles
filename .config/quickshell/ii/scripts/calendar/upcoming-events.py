#!/usr/bin/env python3
"""Print today's and tomorrow's calendar events as JSON, for the bar's clock popup.

Calendars are iCal (.ics) links, one per line, in ~/.config/illogical-impulse/calendars.txt
(that file is private and kept out of the dotfiles repo). For Google Calendar use:
  Settings > (your calendar) > Integrate calendar > "Secret address in iCal format".
Downloads are cached for 10 minutes in ~/.cache/quickshell/calendar/.
"""
import datetime as dt
import hashlib
import json
import os
import sys
import time
import urllib.request
from pathlib import Path

CONFIG = Path.home() / ".config/illogical-impulse/calendars.txt"
CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "quickshell/calendar"
CACHE_SECONDS = 600


def out(obj):
    print(json.dumps(obj))
    sys.exit(0)


def calendar_urls():
    if not CONFIG.exists():
        return []
    lines = (l.strip() for l in CONFIG.read_text().splitlines())
    return [l for l in lines if l and not l.startswith("#")]


def fetch(url):
    CACHE.mkdir(parents=True, exist_ok=True)
    path = CACHE / (hashlib.sha256(url.encode()).hexdigest()[:16] + ".ics")
    if not path.exists() or time.time() - path.stat().st_mtime > CACHE_SECONDS:
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "quickshell-calendar"})
            with urllib.request.urlopen(req, timeout=10) as r:
                path.write_bytes(r.read())
        except Exception:
            pass  # offline: fall back to the cached copy
    return path.read_bytes() if path.exists() else None


def main():
    urls = calendar_urls()
    if not urls:
        out({"configured": False, "events": []})
    try:
        import icalendar
        import recurring_ical_events
    except ImportError:
        out({"configured": True, "error": "missing Python package recurring-ical-events", "events": []})

    local_tz = dt.datetime.now().astimezone().tzinfo
    now = dt.datetime.now(local_tz)
    today = now.date()
    end = dt.datetime.combine(today + dt.timedelta(days=2), dt.time(), local_tz)
    events = []
    for url in urls:
        data = fetch(url)
        if not data:
            continue
        try:
            cal = icalendar.Calendar.from_ical(data)
            for ev in recurring_ical_events.of(cal).between(now.replace(hour=0, minute=0, second=0, microsecond=0), end):
                start = ev.get("DTSTART").dt
                stop = ev.get("DTEND").dt if ev.get("DTEND") else start
                all_day = not isinstance(start, dt.datetime)
                if all_day:
                    day = start
                    if stop <= today:
                        continue
                    start_key = dt.datetime.combine(start, dt.time(), local_tz)
                else:
                    start = start.astimezone(local_tz)
                    stop = stop.astimezone(local_tz)
                    if stop < now:
                        continue  # already over
                    day = start.date()
                    start_key = start
                events.append({
                    "title": str(ev.get("SUMMARY", "(No title)")),
                    "day": "today" if day <= today else "tomorrow",
                    "allDay": all_day,
                    "time": "" if all_day else start.strftime("%H:%M"),
                    "endTime": "" if all_day else stop.strftime("%H:%M"),
                    "now": (not all_day) and start <= now < stop,
                    "_sort": start_key.timestamp(),
                })
        except Exception:
            continue
    events.sort(key=lambda e: (e["_sort"], not e["allDay"]))
    for e in events:
        del e["_sort"]
    out({"configured": True, "events": events[:8]})


if __name__ == "__main__":
    main()
