#!/usr/bin/env python
import re
import curses
import curses.panel
import locale
import os
import signal
import time
import random

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
ptrn21=re.compile(r'^newspr:([^:]*):([^:]*)')
ptrn23=re.compile(r'^box:([^:]*)')
ptrn24=re.compile(r'^grpadd:([^:]*):([^:]*)')
ptrn25=re.compile(r'^grpsub:([^:]*):([^:]*)')
ptrn26=re.compile(r'^grphide:([^:]*)')
ptrn27=re.compile(r'^grpdel:([^:]*)')
ptrn28=re.compile(r'^stats')
ptrn29=re.compile(r'^progspr:([^:]*):([^:]*)')
ptrn30=re.compile(r'^progsprinc:([^:]*)')
ptrn31=re.compile(r'^palette:([^:]*):([^:]*)')
ptrn32=re.compile(r'^pr:([^:]*)')
ptrn33=re.compile(r'^rmparts')
ptrn34=re.compile(r'^paste:([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)')
ptrn35=re.compile(r'^shft:([^:]*):([^:]*)')
ptrn36=re.compile(r'^cstart')
ptrn37=re.compile(r'^cstop')
ptrn38=re.compile(r'^brrr')
ptrn39=re.compile(r'^defspr:([^:]*):([^:]*):([^:]*):([^:]*)')
ptrn40=re.compile(r'^defsprl:([^:]*):([^:]*):([^:]*)') # name, 000line, data (TODO)

locale.setlocale(locale.LC_ALL,'') # had errors
code=locale.getpreferredencoding()
def start1():
	global cs
	cs=curses.initscr()
	try: curses.start_color()
	except: pass
	curses.use_default_colors()
	curses.curs_set(0)
	print "inited"
start1()
cs.clear()
ncolor=0
ca=[]
w=0
panel2=0
lnmode=0
sprite={}
sprite_part={}
OUTPUTFD=os.fdopen(3, 'w', 0)
spr_group={}
progbar={}
progbarmax={}
lowerhalf="\xe2\x96\x84"

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

odd_color=fn(0, 7)

def scrout(w, x, y, fg, bg, s):
	if fg==bg==7:
		cl=odd_color
		s=re.sub(r".", " ", s)
	else:
		cl=fn(fg, bg)
	w.attron(curses.color_pair(cl))
	try: w.addstr(y, x, s)
	except: pass
	w.attroff(curses.color_pair(cl))
def make_sprite(name, w, h):
	w=curses.newwin(h, w, 0, 0)
	#curses.init_pair(29, -1, -1)
	w.bkgdset(' ', curses.color_pair(0)) 
	w.erase()
	p=curses.panel.new_panel(w)
	add_sprite(name, p)
	return p

def move_sprite(panel, fromx, fromy, w, h, x, y):
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
	output("user:scr:resize:"+str(x)+":"+str(y)+"\n") # TODO !

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

#def mainloop():
while True:
	try: a=raw_input()
	except (EOFError, KeyboardInterrupt):
		break
		#on_exit()
		#exit
	except:
		continue
		#return
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
		#on_exit()
		#exit
	elif ptrn4.match(a):
		cs.clear()
	elif ptrn5.match(a):
		ar=ptrn5.match(a).groups()
		scrout(cs, int(ar[0]), int(ar[1]), int(ar[2]), int(ar[3]), ar[4])
	elif ptrn6.match(a):
		(name,w,h)=ptrn6.match(a).groups()
		make_sprite(name, int(w), int(h))
	elif ptrn7.match(a):
		ar=ptrn7.match(a).groups()
		spr=get_sprite(ar[0])
		try: spr.move(int(ar[2]), int(ar[1]))
		except: pass
	elif ptrn8.match(a):
		ar=ptrn8.match(a).groups()
		fg=int(ar[1])
		bg=int(ar[2])
		if fg==bg==7:
			cl=odd_color
		else:
			cl=fn(fg, bg)
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
		scrout(lw, int(ar[1]), int(ar[2]), int(ar[3]), int(ar[4]), ar[5])
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

		neww=sprw
		newh=sprh
		stx=0
		sty=0


		if posx<0:
			neww+=posx

			stx=-posx
			posx=0 
			clip=True
		if excscr>0:
			neww-=excscr

			clip=True
		if posy<0:
			newh+=posy

			sty=-posy
			posy=0
			clip=True
		if excscry>0:
			newh-=excscry

			clip=True
		if clip:
			spr.hide()
			if neww>0 and newh>0:
#				cs.addstr(0, 0, "sty="+str(sty)+\
#						" stx="+str(stx)+\
#						" newh="+str(newh)+\
#						" neww="+str(neww)+\
#						" posy="+str(posy)+\
#						" posx="+str(posx))
				panel2=move_sprite(spr, stx, sty, neww, newh, posx, posy)
				sprite_part[sprname]=panel2
			else:
				if sprname in sprite_part:
					sprite_part[sprname].hide() #FIXME slow
					# add sprite_part to sprite object
					# to search only once.
		else:
			spr.show()
			if sprname in sprite_part:
				sprite_part[sprname].hide()
			spr.move(posy, posx)

	elif ptrn18.match(a):
		ar=ptrn18.match(a).groups()
		cs.addstr(int(ar[1]), int(ar[0]), chr(int(ar[2])))
	elif ptrn19.match(a):
		spr=get_sprite(ptrn19.match(a).groups()[0])
		if spr:
			spr.show()
	elif ptrn20.match(a):
		sprname=ptrn20.match(a).groups()[0]
		spr=get_sprite(sprname)
		if spr:
			spr.hide()
		if sprname in sprite_part:
			sprite_part[sprname].hide()
	elif ptrn21.match(a):
		(newsprnm,oldsprnm)=ptrn21.match(a).groups()
		oldspr=get_sprite(oldsprnm)
		nw=oldspr.window().derwin(0, 0)
		npl=curses.panel.new_panel(nw)
		add_sprite(newsprnm, npl)
	elif ptrn23.match(a):
		spr=get_sprite(ptrn23.match(a).groups()[0])
		spr.window().box()
	elif ptrn24.match(a):
		(grname,sprname)=ptrn24.match(a).groups()
		if not grname in spr_group:
			spr_group[grname]=set()
		spr_group[grname].add(sprname)
	elif ptrn25.match(a):
		(grname,sprname)=ptrn25.match(a).groups()
		if not grname in spr_group:
			continue # TODO: add error message
		spr_group[grname].discard(sprname) # or use 'remove' for exceptions
	elif ptrn26.match(a):
		grname=ptrn26.match(a).groups()[0]
		for i in spr_group[grname]:
			i.hide()
	elif ptrn27.match(a):
		grname=ptrn27.match(a).groups()[0]
		for i in list(spr_group[grname]):
			del sprite[i]
			spr_group[grname].discard(i)
		spr_group.pop(grname,None)
	elif ptrn28.match(a):
		print "Sprites:", len(sprite)
		for i in spr_group:
			print "Group", i, len(spr_group[i])
	elif ptrn29.match(a):
		(prgnm,prgmax)=ptrn29.match(a).groups()
		progbar[prgnm]=0
		progbarmax[prgnm]=int(prgmax)
		(scrh,scrw)=cs.getmaxyx()
		progbarwin=curses.newwin(2, 0, scrh-2-2, 0)
		cl=fn(1, 1)
		progbarwin.bkgdset(' ', curses.color_pair(cl)) 
		progbarwin.erase()
	elif ptrn30.match(a):
		prgnm=ptrn30.match(a).groups()[0]
		(scrh,scrw)=cs.getmaxyx()
		progbar[prgnm]+=1
		#print "pogress: ", progbar[prgnm], "/", progbarmax[prgnm]

	#	print 2, int( float(progbar[prgnm]) / progbarmax[prgnm] * scrw) 
		progbarwin.resize( 2, int( float(progbar[prgnm]) / progbarmax[prgnm] * scrw) or 1 )
		progbarwin.erase()
		progbarwin.refresh()
		if int(progbar[prgnm] / progbarmax[prgnm]) == 1:
			output("user:screen:loaded\n")
	elif ptrn31.match(a):
		(cn,rgb)=ptrn31.match(a).groups()
		print "colors:", curses.can_change_color()
		#if curses.can_change_color():
		curses.init_color(int(cn), 1, 5, 10)
	elif ptrn32.match(a):
		txt=ptrn32.match(a).groups()[0]
		print txt
		#cs.addstr(txt)		
	elif ptrn33.match(a):
		sprite_part={}
	elif ptrn34.match(a):
		(dest,src,sx,sy,dx,dy,w,h)=ptrn34.match(a).groups()
		#print "dbg:", a
		src=get_sprite(src)
		dest=get_sprite(dest)
		if not src or not dest:
			continue
		src=src.window()
		dest=dest.window()
		sx=int(sx)
		sy=int(sy)
		dx=int(dx)
		dy=int(dy)
		dmaxx=int(dx)+int(w)-1 # TODO: check h & w. curses doesn't catch it & s-f's
		dmaxy=int(dy)+int(h)-1
		#print "dbg2:", src, dest, sy, sx, dy, dx, dmaxy, dmaxx
		try:
			src.overwrite(dest, sy, sx, dy, dx, dmaxy, dmaxx)
		except: pass
		#print "nxt"
	elif ptrn35.match(a):
		(spr,shft)=ptrn35.match(a).groups()
		spr=get_sprite(spr)
		if not spr:
			continue
		spr=spr.window()
		spr.mvderwin(int(shft),0)
	elif ptrn36.match(a):
		start1()
	elif ptrn37.match(a):
		curses.endwin()
		print "uninited"
	elif ptrn38.match(a):
		print "brrr--uninited"
	elif ptrn39.match(a):
		(name,w,h,data)=ptrn39.match(a).groups()
		w=int(w)
		h=int(h)
		if len(data) < w * h: next

		win=get_sprite(name)
		if not win:
			win=make_sprite(name, w, h/2)

		if h%2:
			hh=h-1
		else:
			hh=h
		for y in range(0, hh, 2):
			for x in range(w):
				bg = int(data[x + y*w])
				fg = int(data[x + y*w + w])
				scrout(win.window(), x, y/2, fg, bg, lowerhalf)
#while 1:
#	try:
#		mainloop
#	except:
#		time.sleep(20)
#		last

on_exit()


