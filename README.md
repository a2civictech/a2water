# a2water

Utilities to download and analyze Ann Arbor water utilities use.

### Downloading water data

If you look on your water bill you'll find a "meterID", like
`12345678-0.12`. Replace that ID with yours in this "curl" command
to get readings for a range of dates.

```
curl -s 'https://secure.a2gov.org/WaterConsumption/DownloadData.aspx?meterID=12345678-0.12&startDate=3/10/2018&endDate=3/12/2018' > water.html
```

### Parsing water data

It's a funky HTML file. This bit of `sed` will normalize it
back down to something easy to parse.

```
cat water.html | sed -e 1,4d -e /tr/d -e /table/d -e 's;</td><td>;,;g' -e 's/.*<td>//' -e 's;.</td>.*;;'
```

### Graphing water data

Use your favorite graphing tool. Examples welcomed; the file `waterusage.sh` here generates a plot.

### City provided alert and monitoring tool, "Aquahawk"

The City of Ann Arbor released a reporting and alert monitoring tool,
[Aquahawk](https://annami.aquahawk.us/login), which you can use once
you've registered your meter. It gives you a day-by-day estimate of use,
as well as monthly or weekly totals, and you can export by hour, day,
or month. The system can also send alerts to a provided cell phone number
if it suspects that you have a leak.
