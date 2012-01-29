import sqlite3
from matplotlib import pyplot,pylab
import dateutil

conn = sqlite3.connect('data_log.db')
c = conn.cursor()
c.execute('SELECT `datetime`,value FROM `28.xxxxxxxx` ORDER BY `datetime` DESC')

dates = []
values = []

for row in c:
	dates.append(dateutil.parser.parse(row[0]))
	values.append(row[1])

print(dates)
print(values)

pyplot.plot_date(pylab.date2num(dates), values)
pyplot.show()
