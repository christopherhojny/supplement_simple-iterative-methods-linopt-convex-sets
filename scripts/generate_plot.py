import sys
import matplotlib.pyplot as plt

logfile = sys.argv[1]
title = sys.argv[2]

f = open(logfile, 'r')

# get dual values polar
line = f.readline()
line = f.readline()
dual = line.split()

# get primal values polar
line = f.readline()
line = f.readline()
primal = line.split()

# get LP values
line = f.readline()
line = f.readline()
LP = line.split()

f.close()

# transform string values to float values
for i in range(len(dual)):
    dual[i] = float(dual[i])
for i in range(len(primal)):
    primal[i] = float(primal[i])
for i in range(len(LP)):
    LP[i] = float(LP[i])

x = range(max(len(dual), len(primal), len(LP)))

# create plot with linear-scale
plt.gca().set_axis_off()
plt.subplots_adjust(top = 1, bottom = 0, right = 1, left = 0, 
            hspace = 0, wspace = 0)
plt.margins(0,0)
plt.gca().xaxis.set_major_locator(plt.NullLocator())
plt.gca().yaxis.set_major_locator(plt.NullLocator())
fig = plt.figure(figsize=(6,3.9))
ax1 = fig.add_subplot()

lns = ax1.plot(x[:len(dual)], dual, label='dual from A_t', linewidth=3)
lns += ax1.plot(x[:len(primal)], primal, label='gamma_t', linewidth=3)
lns += ax1.plot(x[:len(LP)], LP, label='dual from LP', color='red', linewidth=3)

labs = [l.get_label() for l in lns]
ax1.legend(lns, labs, fontsize="x-large",loc="lower right")

plt.xlabel('iterations', size=15)
plt.ylabel('objective value', size=15)
plt.xticks(fontsize="x-large" )
plt.yticks(fontsize="x-large" )
# plt.show()
filetitle = title.replace(" ", "_")
plt.savefig("plots_%s.png" % filetitle, padinches=0, bbox_inches = "tight")
