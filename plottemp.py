import sqlite3
from matplotlib import pyplot,pylab
import dateutil

conn = sqlite3.connect('data_log.db')
c = conn.cursor()
c.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '28.%';")
sensors = []
for row in c:
	sensors.append(row[0])

print(sensors)

sdates = [];
svalues = [];
i = 1

for s in sensors:
	c.execute("SELECT `datetime`, value FROM `%s` ORDER BY `datetime` DESC LIMIT 150" % (sensors[i-1]))
	dates = []
	values = []

	for row in c:
		dates.append(dateutil.parser.parse(row[0]))
		values.append(row[1])
		
	plo = pyplot.subplot(310+i)
	if i < 3:
		pylab.setp( plo.get_xticklabels(), visible=False)
	plo.plot_date(pylab.date2num(dates),values)
	i=i+1

pyplot.show()
