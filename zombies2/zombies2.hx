/*---------------------------------------------------------------------
	Zombie Apocalypse
		=========
		  =   =
		  =   =
		  =   =
		=========
	Java Edition 2000

	Based on the original Blitz Basic 2 game by Vision Software.
	Original Programming: Paul Andrews
	Graphics: Rodney Smith
	Java Port: Paul Andrews
	AXIS Class Libraries: Simon Armstrong
	(c) 1995 Vision Software ( R.Smith & P.Andrews )
	(c) 2000 Acid Software
---------------------------------------------------------------------*/

package zombie2;

import axis.*;
import axis.io.*;

import java.util.Random;

//---------------------------------------------------------------------

//a body part
class z2bodypart
{
	static z2bodypart list = null;
	static ramcanvas bloodgfx[];
	static ramcanvas blooddrop[];
	static Random rnd;
	static String soundnames[]=	//bouncy splat sounds
	{
		"splat1.au","splat2.au","splat3.au"
	};
	static sound sounds[];

	z2bodypart next, prev;
	int type;	//0=part, 1=blooddrops
	int go;		//bouncing or still?
	int frame;
	int count;
	int x,y;	//fixed point co-ors
	int ix,iy;	//integer co-ors
	int	vx,vy;
	int bot;	//land here
	int dribble;//draw runny blood on background bitmap

//methods for individual bloodsplats...
	void add( int t, int xp, int yp )	//add random bodypart...
	{
		if ( yp > 199 )
			return;

		frame = rnd.nextInt() % 6;
		if ( frame < 0 ) frame = -frame;
		count = 0;

		ix = xp + ( rnd.nextInt() % 6 );
		iy = yp + ( rnd.nextInt() % 6 );

		vx = rnd.nextInt() % 4;
		vy = rnd.nextInt() % 4;
		if ( vy < 0 ) vy = -vy;	//make positive
		vy += 3;
		vy = -vy;	//up!

		type = t;
		if ( type !=0 )
		{
			frame = 0;
			vy = vy / 16;
			vx = vx / 16;
		}

		x = ix << 16;	//QUICK!!!
		y = iy << 16;
		vx <<= 16;
		vy <<= 16;

		go = 1;
		dribble = 0;

		if ( yp <= 156 - 12 )
			bot = 156 - 12 + rnd.nextInt() % 3;
		else
			bot = 200 - 14;

		prev=null;
		next=list;
		if ( list != null )
			list.prev = this;
		list=this;
	}

	void remove( )
	{
		if ( list == this )
			list = this.next;
		if ( prev != null )
			prev.next = next;
		if ( next != null )
			next.prev = prev;
	}

	void tick( ramcanvas c )
	{
		int ss;

		if ( ix < 0 || ix > 320 )
		{
			remove();
			return;
		}
		
		if ( type != 0 )	//drop of blood spraying out
		{
			x += vx;
			y += vy;
			vy = vy + (65535/3);
			ix = x >> 16;
			iy = y >> 16;

			count++;
			if ( count == 2 )
			{
				count = 0;
				frame++;
				if ( frame > 4 )
					remove();
			}

			return;
		}

		if ( go == 1 )
		{
			z2bodypart b;

			x += vx;
			y += vy;
			vy = vy + (65535/3);

			ix = x >> 16;
			iy = y >> 16;

			count++;
			if ( count == 2 )
			{
				b = new z2bodypart();
				b.add( 1, ix + 8, iy + 7 );
				count = 0;
			}

			if ( iy > bot && vy > 0 )
			{
				if ( vy > 0x10000 )	//fast fall!
				{
					ss = ix % 3;	//0,1,2
					if ( ss < 0 ) ss = 0;
					if ( sounds[ ss ] != null ) sounds[ ss ].play();
					vy = -( vy / 2 );	//bounce back up...
					c.blit( blooddrop[ ix & 4], ix+7, iy+12, 2 );
				}
				else
				{
					vy = 0;
					go = 0;
					dribble = rnd.nextInt() % 80;
					if ( dribble < 0 ) dribble = -dribble;
					dribble += 5;
					vx = rnd.nextInt() % 6500;

					x = ix + 7;	//when go == 0, x & y are the bloodtrail
					y = iy + 7; //co-ordinates (in fixed point!)
					x = x << 16;
					y = y << 16;
				}
			}
		}
		else
		{
			if ( dribble > 0 )
			{
				if ( (y >> 16) < 200 )
				{
					c.blit( blooddrop[ (y >> 16) & 4], x >> 16, y >> 16, 2 );
					y = y + 0x4000;
					x = x + vx;
					dribble--;
				}
				else
					dribble = 0;
			}
		}
	}

//global, static methods for all bloodsplats
	static void load( int palette[] )
	{
		int i;

		rnd = new Random();
		try
		{
			bloodgfx=amiga.loadshapes("zombie2/bodyparts.shp",palette);
			blooddrop=amiga.loadshapes("zombie2/blooddrop.shp",palette);

			sounds=new sound[soundnames.length];
			for (i=0;i<sounds.length;i++)
			{
				sounds[i]=netlink.loadsound("zombie2/"+soundnames[i]);
			}
		}
		catch (java.io.IOException e)
		{
			system.debug("e:"+e);
		}
	}

	static void clear()
	{
		list = null;
	}

	static void update( ramcanvas c )
	{
		z2bodypart b;

		for (b=list;b!=null;b=b.next) 
		{
			b.tick( c );
		}
	}

	static void draw( canvas c )
	{
		z2bodypart b;

		for (b=list;b!=null;b=b.next) 
		{
			if ( b.type == 0 )
				c.blit( bloodgfx[b.frame], b.ix, b.iy, 1 );
			else
				c.blit( blooddrop[b.frame], b.ix, b.iy, 2 );
		}
	}
}

//---------------------------------------------------------------------
/*
class zombie2
{
	static zombie2 list;
	static ramcanvas zshapes[];

	static String soundnames[]=
	{
		"appear1.au","appear2.au","appear3.au","appear4.au","appear5.au","appear6.au", //2..7
		"splat1.au","splat2.au","splat3.au", //8..10
		"die1.au","die2.au","die3.au", //11..13
		"ouch1.au","ouch2.au","ouch3.au","ouch4.au","ouch5.au" //14..18
	};
	static sound sounds[];

	zombie2		next,prev;
	int			dam;
	int			type,life,frame,count,hitcount;
	int			x,y,vx,vy;

	void add( int t, int xp, int yp )
	{
		int ss;

		type = t;
		life = 0;
		dam = 6;
		frame = t * 10;
		count = 2;
		hitcount = 0;
		x = xp;y = yp;
		vx = 0;vy = 0;

	//appear sound...
		ss = ( ( t + xp ) % 6 );
		ss += 0;
		if (sounds[ss]!=null) sounds[ss].play();

		prev = null;
		next = list;
		if ( list != null )
			list.prev = this;
		list = this;
	}

	void remove( )
	{
		if ( list == this )
			list = this.next;
		if ( prev != null )
			prev.next = next;
		if ( next != null )
			next.prev = prev;
	}

	int damage( int hurt )	//0==splat, 1==dead
	{
		z2bodypart b;
		int i;

		dam -= hurt;
		if ( dam < 0 )
		{
			for ( i = 0; i < 4; i++ )	//increase gore-level here!
			{
				b = new z2bodypart();
				b.add( 0, x, y );
			}

			remove();
			return 1;
		}
		return 0;
	}

  //only check first zombie hit...
	int checkhit( int ax, int ay ) //0=miss,1=hit.2=killed
	{
		blood b;
		int d, ss;

		if ( ax >= x && ax <= x+40 && ay >=y && ay <= y+56 )
		{
//			b = new blood();
//			b.add( ax, ay );

			d = damage( 1 );
			if ( d == 0 )	//just go splat!
			{
				ss = ((ax+life)%3) + 6;// 8 - 10 splat
				if (sounds[ss]!=null) sounds[ss].play();
				return 1;
			}
			else if ( d == 1 )	//die!!
			{
				ss = ((ax+life)%3) + 9;// 11 - 13 die!
				if (sounds[ss]!=null) sounds[ss].play();
				return 2;
			}
		}
		return 0;
	}

	int tick() //return 1 if zombie died and player should suffer
	{
		life++;
		if (--count<0)
		{
			count=anim.speed;
			frame++;
			if (frame>anim.hi) frame=anim.lo;
		}
		x+=vx;y+=vy;
		if ( type == 3 && x > 300) //walker!
		{
			remove();
			return 1;
		}
		if ( type == 4 && frame == 3 )	//thrower...
		{
			remove();
			return 1;
		}
		return 0;
	}

//static, class-wide functions
	static void load( int palette[] )
	{
		int i;
		ramcanvas z1[];
		try
		{
			z1=amiga.loadshapes("zombies/zombies.shp",palette);
			zshapes=new ramcanvas[z1.length];
			for (i=0;i<z1.length;i++) zshapes[i]=z1[i];

			sounds=new sound[soundnames.length];
			for (i=0;i<sounds.length;i++)
			{
				sounds[i]=netlink.loadsound("zombies/"+soundnames[i]);
			}
		}
		catch (java.io.IOException e)
		{
			system.debug("e:"+e);
		}
	}

	static void clear()
	{
		list = null;
	}

	static int update( ) //returns # of zombies that died & hurt player
	{
		zombie z;
		int d;

		d = 0;
		for (z=list;z!=null;z=z.next) 
		{
			d = d + z.tick();
		}
		return d;
	}

	static int checkhits( int ax, int ay )
	{
		zombie z;
		int d;

		for (z=list;z!=null;z=z.next) 
		{
			d = z.checkhit( ax, ay );
			if ( d != 0 )
				return d;	//1=hit, 2=killed (0=missed!)
		}
		return 0;
	}

	static int damageall( int amt ) //return # that died completely
	{
		int d;
		zombie z;

		d = 0;
		for (z=list;z!=null;z=z.next) 
		{
			if ( z.damage( amt ) == 2 )
				d++;
		}
		return d;
	}

	static void draw( canvas c )
	{
		zombie z;

		for (z=list;z!=null;z=z.next) 
		{
			c.blit(zshapes[z.frame],z.x,z.y,1);
		}
	}
}
*/
//---------------------------------------------------------------------

public class zombie2 extends window
{
	ramcanvas	title,sight;
	ramcanvas	background[];
	ramcanvas	backdrop;
	int	zpalette[];

	sound		sounds[];

	Random		zrand;

	int	aimx,aimy;
	int	state;
	int	joybl,joybr;
	int level;

	static String soundnames[]=
	{
		"gun.au","boom.au", //0..1
	};

// game state machine
	final static int TITLE=0;
	final static int INGAME=1;
	final static int LEVELDONE=2;
	final static int GAMEOVER=3;
	final static int DEBOUNCE=4;

	public void init(String name)
	{
		int			i;

		zrand=new Random();

		super.init("Zombie Apocalypse ][");

		try
		{	
			amiga.setgamma( 150 );

			sight=amiga.loadiff("zombie2/pointer.iff");

			title=amiga.loadiff("zombie2/titlescreen.iff");
			background=new ramcanvas[4];
			background[0]=amiga.loadiff("zombie2/backdrop1.iff");
			background[1]=amiga.loadiff("zombie2/backdrop2.iff");
			background[2]=amiga.loadiff("zombie2/backdrop3.iff");
			background[3]=amiga.loadiff("zombie2/backdrop4.iff");
			zpalette=background[0].palette;

			z2bodypart.load( zpalette );

//			zombie2.load( zpalette );

/*			sounds=new sound[soundnames.length];
			for (i=0;i<sounds.length;i++)
			{
				sounds[i]=netlink.loadsound("zombies/"+soundnames[i]);
			}
*/
			backdrop=title;
			state=TITLE;
		}
		catch (java.io.IOException e)
		{
			system.debug("e:"+e);
		}
		color=0x404080;
	}

// Message Loop
	public void play(message m)
	{
		int		i,x,y;

		switch (m.code)
		{
		case m.MOUSECLIK:
			aimx=m.idata[0];
			aimy=m.idata[1];
			if ( ( m.idata[2] & 4 ) != 0 )
				joybr = 1;
			else
				joybl = 1;
			m.reply(new message(message.ATTACH,this));
			break;

		case m.MOUSEDROP:
			joybl = 0;joybr = 0;
			m.reply(new message(message.DETACH,this));
			break;

		case m.MOUSEMOVE:
		case m.MOUSEDRAG:
		case m.MOUSERDRAG:
			aimx+=m.idata[0];
			aimy+=m.idata[1];
			refresh=true;
			break;

		case m.RESIZE:
	//		rethink();
			break;

		case m.TICK:
			ztick();
			break;

		default:
			super.play(m);
			break;
		}
	}

	void zinitgame()
	{
		state = INGAME;
		//score = 0; health = ??? etc
		level = 0;
		zinitlevel();
	}

	void zinitlevel()
	{
		backdrop=background[(level/3)%4];
		
		z2bodypart.clear();
		//zombie2.clear();
	}

	void zleveldone()
	{
	}

// Frame Tick - update game!
	void ztick()
	{
		z2bodypart b;

		if ( state == TITLE )
		{
			if ( joybl !=0 || joybr != 0 )
				zinitgame();
			refresh = true;
			return;
		}
		if ( state == INGAME )
		{
			if ( joybl != 0 )
			{
				b = new z2bodypart();
				b.add( 0, aimx, aimy );
			}

			z2bodypart.update( backdrop );
		}
		refresh = true;
	}

// Draw everything....
	public void render( canvas c )
	{
		if ( backdrop == null ) { c.cls( color ); return;}

		c.blit( backdrop, 0, 0, 0 );

		switch( state )
		{
		case TITLE:
			break;
		case INGAME:
			z2bodypart.draw( c );
			break;
		default:
			break;
		}

		c.blit( sight, aimx, aimy, 1 );

	}

}
