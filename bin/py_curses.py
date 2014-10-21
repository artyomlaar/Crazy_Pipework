#!/usr/bin/env python
import re
import curses
import curses.panel
import locale
import os
import signal
import time

ptrn1=re.compile(r'^pr:([^:]*):([^:]*):([^:]*)')
ptrn2=re.compile(r'^ref')
ptrn3=re.compile(r'^quit')
ptrn4=re.compile(r'^clr')
ptrn5=re.compile(r'^prc:([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)$')
ptrn6=re.compile(r'^spr:([^:]*):([^:]*):([^:]*)')
ptrn7=re.compile(r'^mvs:([^:]*):([^:]*):([^:]*)')
ptrn8=re.compile(r'^bkgd:([^:]*):([^:]*):([^:]*)')
ptrn9=re.compile(r'^curs:([^:]*)')
ptrn10=re.compile(r'^prc:([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)')
#ptrn11=re.compile(r'^hide:([^:]*)')
ptrn12=re.compile(r'^inch:([^:]*)')
ptrn13=re.compile(r'^copy:([^:]*)')
ptrn14=re.compile(r'^lnmode:([^:]*)')
ptrn16=re.compile(r'^time')
ptrn17=re.compile(r'^mvs2:([^:]*):([^:]*):([^:]*)')
ptrn18=re.compile(r'^chr:([^:]*):([^:]*):([^:]*)')
ptrn19=re.compile(r'^show:(.*)')
ptrn20=re.compile(r'^hide:([^:]*)')
ptrn23=re.compile(r'^box:([^:]*)')
locale.setlocale(locale.LC_ALL,'') # had errors
code=locale.getpreferredencoding()
cs=curses.initscr()
try: curses.start_color()
except: pass
curses.use_default_colors()
curses.curs_set(0)
cs.clear()
ncolor=0
ca=[]
w=0
panel2=0
lnmode=0
sprite={}
sprite_part={}
OUTPUTFD=os.fdopen(3, 'w', 0)

for i in range(8): # TODO: add alpha support (color_id=-1)
	ca.append([])
	for j in range(8):
		ca[i].append("n")

def fn(fg, bg): # TODO: add 2d array, look the id up there, if 404, inc id
	global ncolor
	if ca[fg][bg]=="n":
		ncolor+=1
		c=ncolor
		curses.init_pair(c, fg, bg)
		ca[fg][bg]=c
	else:
		c=ca[fg][bg]
	return c

def move_sprite(panel, fromx, fromy, w, h, x, y):
	panel.hide()
	nw=panel.window().derwin(h, w, fromy, fromx)
	cutspr=curses.panel.new_panel(nw)
	cutspr.move(y, x)
	return cutspr

def get_screen_coords(x, y):
	if lnmode==0:
		return int(x), int(y), False
	elif lnmode&1:	# bit 0 - double lines count
		return int(x), int(y)/2, int(y)%2 
	elif lnmode&2:	# bit 1 - float coords 
		return int(x), int(y), y-int(y)>.5 

def get_user_coords(x, y):
	if lnmode==0:
		return x, y
	elif lnmode&1:	# bit 0 - double lines count
		return x, y*2
	elif lnmode&2:	# bit 1 - float coords 
		return x, y 

def add_sprite(name, panel):
	sprite[name]=panel

def get_sprite(name):
	if name in sprite:
		return sprite[name]

def output(str):
	try: OUTPUTFD.write(str)
	except: pass

def on_exit():
	try: os.close(OUTPUTFD)
	except: pass
	curses.endwin()

def send_win_size():
	(y,x)=cs.getmaxyx()
	(x,y)=get_user_coords(x, y)
	output("user:resize:"+str(x)+":"+str(y)+"\n")

def sigwinch_handler(signal, frame):
	curses.endwin()
	curses.initscr()
	send_win_size()

def on_start():
	signal.signal(signal.SIGWINCH, sigwinch_handler)
	add_sprite("stdscr", curses.panel.new_panel(cs))
	#if os.environ['NULL_CLIENT']:
	#	output("mod:ready:in\n")
 	send_win_size()

on_start()

while 1:
	try: a=raw_input()
	except (EOFError, KeyboardInterrupt):
		break
	except:
		continue
	#tick()
	if ptrn1.match(a):
		ar=ptrn1.match(a).groups()
		try: cs.addstr(int(ar[1]), int(ar[0]), ar[2])
		except: pass
	elif ptrn2.match(a):
		curses.panel.update_panels()	
		cs.refresh()
	elif ptrn3.match(a):
		break
	elif ptrn4.match(a):
		cs.clear()
	elif ptrn5.match(a):
		ar=ptrn5.match(a).groups()
		cl=fn(int(ar[2]), int(ar[3]))
		cs.attron(curses.color_pair(cl))
		try: cs.addstr(int(ar[1]), int(ar[0]), ar[4])
		except: pass
		cs.attroff(curses.color_pair(cl))
	elif ptrn6.match(a):
		ar=ptrn6.match(a).groups()
		w=curses.newwin(int(ar[2]), int(ar[1]), 1, 1)
		curses.init_pair(29, -1, -1)
		w.bkgdset(' ', curses.color_pair(29)) 
		w.erase()
		add_sprite(ar[0], curses.panel.new_panel(w))
	elif ptrn7.match(a):
		ar=ptrn7.match(a).groups()
		spr=get_sprite(ar[0])
		try: spr.move(int(ar[2]), int(ar[1]))
		except: pass
	elif ptrn8.match(a):
		ar=ptrn8.match(a).groups()
		cl=fn(int(ar[1]), int(ar[2]))
		cs.bkgdset(' ', curses.color_pair(cl)) 
	elif ptrn9.match(a):
		ar=ptrn9.match(a).groups()
		curses.curs_set(int(ar[0]))
	elif ptrn10.match(a):
		ar=ptrn10.match(a).groups()
		spr=get_sprite(ar[0])
		if not spr:
			continue
		lw=spr.window()
		cl=fn(int(ar[3]), int(ar[4]))
		lw.attron(curses.color_pair(cl))
		try: lw.addstr(int(ar[2]), int(ar[1]), ar[5])
		except: pass
		lw.attroff(curses.color_pair(cl))
	elif ptrn12.match(a):
		panel.window().inch(1,1)
	elif ptrn13.match(a):
		pass # TODO copy command
	elif ptrn14.match(a):
		lnmode=int(ptrn14.match(a).groups()[0]) # 0-def, 1-2xln, 2-float
		send_win_size()
	elif ptrn16.match(a):
		output('user:client-time='+'{0:.6f}\n'.format(time.time()))
	elif ptrn17.match(a):
		(sprname,posx,posy)=ptrn17.match(a).groups()
		(posx,posy,is_shifted)=get_screen_coords(float(posx), float(posy))
		(scrh,scrw)=cs.getmaxyx()
		spr=get_sprite(sprname)
		spr1=get_sprite(sprname+".+1")
		if not spr:
			continue
		if spr1:
			if is_shifted:
				spr.hide()
				#spr1.show()
				spr=spr1
			else:
				spr1.hide()
				#spr.show()
		#(spry,sprx)=w.getbegyx()
		(sprh,sprw)=spr.window().getmaxyx()
		(newh,neww)=(sprh,sprw)
		(sty,stx)=(0,0)
		sprend=posx+sprw
		sprendy=posy+sprh
		excscr=sprend-scrw
		excscry=sprendy-scrh
		befscr=posx
		clip=False
		if posx<0:
			neww=sprw+posx
			stx=-posx
			posx=0 
			clip=True
		elif excscr>0:
			neww=sprw-excscr
			stx=0
			clip=True
		if posy<0:
			newh=sprh+posy
			sty=-posy
			posy=0
			clip=True
		elif excscry>0:
			newh=sprh-excscry
			sty=0
			clip=True
		if clip:
			if neww>0 and newh>0:
#				cs.addstr(0, 0, "sty="+str(sty)+\
#						" stx="+str(stx)+\
#						" newh="+str(newh)+\
#						" neww="+str(neww)+\
#						" posy="+str(posy)+\
#						" posx="+str(posx))
				panel2=move_sprite(spr, stx, sty, neww, newh, posx, posy)
				sprite_part[ar[0]]=panel2
			else:
				panel2.hide()
		else:
			spr.show()
			if panel2: panel2.hide()
			spr.move(posy, posx)

	elif ptrn18.match(a):
		ar=ptrn18.match(a).groups()
		cs.addstr(int(ar[1]), int(ar[0]), chr(int(ar[2])))
	elif ptrn19.match(a):
		spr=get_sprite(ptrn19.match(a).groups()[0])
		if spr:
			spr.show()
	elif ptrn20.match(a):
		spr=get_sprite(ptrn20.match(a).groups()[0])
		if spr:
			spr.hide()
	elif ptrn23.match(a):
		spr=get_sprite(ptrn23.match(a).groups()[0])
		spr.window().box()

on_exit()

