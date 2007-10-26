// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.splitter;

private import dfl.control, dfl.internal.winapi, dfl.base, dfl.drawing;
private import dfl.event;


///
class SplitterEventArgs: EventArgs
{
	///
	this(int x, int y, int splitX, int splitY)
	{
		_x = x;
		_y = y;
		_splitX = splitX;
		_splitY = splitY;
	}
	
	
	///
	final int x() // getter
	{
		return _x;
	}
	
	
	///
	final int y() // getter
	{
		return _y;
	}
	
	
	///
	final void splitX(int val) // setter
	{
		_splitX = val;
	}
	
	/// ditto
	final int splitX() // getter
	{
		return _splitX;
	}
	
	
	///
	final void splitY(int val) // setter
	{
		_splitY = val;
	}
	
	/// ditto
	final int splitY() // getter
	{
		return _splitY;
	}
	
	
	private:
	int _x, _y, _splitX, _splitY;
}


alias Event!(SplitterEventArgs) SplitterEventHandler; // deprecated


///
class Splitter: Control // docmain
{
	this()
	{
		// DMD 0.95: need 'this' to access member dock
		this.dock = DockStyle.LEFT;
		
		if(HBRUSH.init == hbrxor)
			inithbrxor();
	}
	
	
	override void anchor(AnchorStyles a) // setter
	{
		throw new DflException("Splitter cannot be anchored");
	}
	
	alias Control.anchor anchor; // Overload.
	
	
	override void dock(DockStyle ds) // setter
	{
		switch(ds)
		{
			case DockStyle.LEFT:
			case DockStyle.RIGHT:
				//cursor = new Cursor(LoadCursorA(null, IDC_SIZEWE), false);
				cursor = Cursors.vSplit;
				break;
			
			case DockStyle.TOP:
			case DockStyle.BOTTOM:
				//cursor = new Cursor(LoadCursorA(null, IDC_SIZENS), false);
				cursor = Cursors.hSplit;
				break;
			
			default:
				throw new DflException("Invalid splitter dock");
		}
		
		super.dock(ds);
	}
	
	alias Control.dock dock; // Overload.
	
	
	///
	void movingGrip(bool byes) // setter
	{
		if(mgrip == byes)
			return;
		
		this.mgrip = byes;
		
		if(created)
		{
			invalidate();
		}
	}
	
	/// ditto
	bool movingGrip() // getter
	{
		return mgrip;
	}
	
	deprecated alias movingGrip moveingGrip;
	deprecated alias movingGrip moveGrip;
	deprecated alias movingGrip sizingGrip;
	
	
	protected override void onPaint(PaintEventArgs ea)
	{
		super.onPaint(ea);
		
		if(mgrip)
		{
			ea.graphics.drawMoveGrip(bounds, DockStyle.LEFT == dock || DockStyle.RIGHT == dock);
		}
	}
	
	
	protected override void onResize(EventArgs ea)
	{
		super.onResize(ea);
		
		if(mgrip)
		{
			invalidate();
		}
	}
	
	
	protected override void onMouseDown(MouseEventArgs mea)
	{
		super.onMouseDown(mea);
		
		if(mea.button == MouseButtons.LEFT)
		{
			capture = true;
			
			downing = true;
			//downpos = Point(mea.x, mea.y);
			
			switch(dock)
			{
				case DockStyle.TOP:
				case DockStyle.BOTTOM:
					downpos = mea.y;
					lastpos = 0;
					drawxorClient(0, lastpos);
					break;
				
				default: // LEFT / RIGHT.
					downpos = mea.x;
					lastpos = 0;
					drawxorClient(lastpos, 0);
			}
		}
	}
	
	
	protected override void onMouseMove(MouseEventArgs mea)
	{
		super.onMouseMove(mea);
		
		if(downing)
		{
			switch(dock)
			{
				case DockStyle.TOP:
				case DockStyle.BOTTOM:
					drawxorClient(0, mea.y - downpos, 0, lastpos);
					lastpos = mea.y - downpos;
					break;
				
				default: // LEFT / RIGHT.
					drawxorClient(mea.x - downpos, 0, lastpos, 0);
					lastpos = mea.x - downpos;
			}
			
			scope sea = new SplitterEventArgs(mea.x, mea.y, left, top);
			onSplitterMoving(sea);
		}
	}
	
	
	protected override void onMove(EventArgs ea)
	{
		super.onMove(ea);
		
		if(downing) // ?
		{
			Point curpos = Cursor.position;
			curpos = pointToClient(curpos);
			scope sea = new SplitterEventArgs(curpos.x, curpos.y, left, top);
			onSplitterMoved(sea);
		}
	}
	
	
	protected override void onMouseUp(MouseEventArgs mea)
	{
		if(downing)
		{
			capture = false;
			
			downing = false;
			
			if(mea.button != MouseButtons.LEFT)
			{
				// Abort.
				switch(dock)
				{
					case DockStyle.TOP:
					case DockStyle.BOTTOM:
						drawxorClient(0, lastpos);
						break;
					
					default: // LEFT / RIGHT.
						drawxorClient(lastpos, 0);
				}
				super.onMouseUp(mea);
				return;
			}
			
			Control splat; // Splitted.
			int adj, val, vx;
			
			// DMD 0.95: need 'this' to access member dock
			//switch(dock())
			switch(this.dock())
			{
				case DockStyle.LEFT:
					drawxorClient(lastpos, 0);
					foreach(Control ctrl; parent.controls())
					{
						if(DockStyle.NONE == ctrl.dock)
							continue;
						// DMD 0.95: overloads int(Object o) and int(Control ctrl) both match argument list for opEquals
						//if(ctrl == this)
						if(ctrl == cast(Control)this)
						{
							if(splat)
							{
								//val = left - splat.left + mea.x - downpos.x;
								val = left - splat.left + mea.x - downpos;
								if(val < msize)
									val = msize;
								splat.width = val;
							}
							break;
						}
						splat = ctrl;
					}
					break;
				
				case DockStyle.RIGHT:
					drawxorClient(lastpos, 0);
					foreach(Control ctrl; parent.controls())
					{
						if(DockStyle.NONE == ctrl.dock)
							continue;
						// DMD 0.95: overloads int(Object o) and int(Control ctrl) both match argument list for opEquals
						//if(ctrl == this)
						if(ctrl == cast(Control)this)
						{
							if(splat)
							{
								//adj = right - splat.left + mea.x - downpos.x;
								adj = right - splat.left + mea.x - downpos;
								val = splat.width - adj;
								vx = splat.left + adj;
								if(val < msize)
								{
									vx -= msize - val;
									val = msize;
								}
								splat.bounds = Rect(vx, splat.top, val, splat.height);
							}
							break;
						}
						splat = ctrl;
					}
					break;
				
				case DockStyle.TOP:
					drawxorClient(0, lastpos);
					foreach(Control ctrl; parent.controls())
					{
						if(DockStyle.NONE == ctrl.dock)
							continue;
						// DMD 0.95: overloads int(Object o) and int(Control ctrl) both match argument list for opEquals
						//if(ctrl == this)
						if(ctrl == cast(Control)this)
						{
							if(splat)
							{
								//val = top - splat.top + mea.y - downpos.y;
								val = top - splat.top + mea.y - downpos;
								if(val < msize)
									val = msize;
								splat.height = val;
							}
							break;
						}
						splat = ctrl;
					}
					break;
				
				case DockStyle.BOTTOM:
					drawxorClient(0, lastpos);
					foreach(Control ctrl; parent.controls())
					{
						if(DockStyle.NONE == ctrl.dock)
							continue;
						// DMD 0.95: overloads int(Object o) and int(Control ctrl) both match argument list for opEquals
						//if(ctrl == this)
						if(ctrl == cast(Control)this)
						{
							if(splat)
							{
								//adj = bottom - splat.top + mea.y - downpos.y;
								adj = bottom - splat.top + mea.y - downpos;
								val = splat.height - adj;
								vx = splat.top + adj;
								if(val < msize)
								{
									vx -= msize - val;
									val = msize;
								}
								splat.bounds = Rect(splat.left, vx, splat.width, val);
							}
							break;
						}
						splat = ctrl;
					}
					break;
			}
			
			// This is needed when the moved control first overlaps the splitter and the splitter
			// gets bumped over, causing a little area to not be updated correctly.
			// I'll fix it someday.
			parent.invalidate(true);
			
			// Event..
		}
		
		super.onMouseUp(mea);
	}
	
	
	/+
	// Not quite sure how to implement this yet.
	// Might need to scan all controls until one of:
	//    Control with opposite dock (right if left dock): stay -mextra- away from it,
	//    Control with fill dock: that control can't have less than -mextra- width,
	//    Reached end of child controls: stay -mextra- away from the edge.
	
	///
	final void minExtra(int min) // setter
	{
		mextra = min;
	}
	
	/// ditto
	final int minExtra() // getter
	{
		return mextra;
	}
	+/
	
	
	///
	final void minSize(int min) // setter
	{
		msize = min;
	}
	
	/// ditto
	final int minSize() // getter
	{
		return msize;
	}
	
	
	/+
	// TODO: implement.
	
	///
	final void splitPosition(int pos) // setter
	{
		
	}
	
	/// ditto
	// -1 if not docked to a control.
	final int splitPosition() // getter
	{
		
	}
	+/
	
	
	//SplitterEventHandler splitterMoved;
	Event!(Splitter, EventArgs) splitterMoved; ///
	//SplitterEventHandler splitterMoving;
	Event!(Splitter, EventArgs) splitterMoving; ///
	
	
	protected:
	
	override Size defaultSize() // getter
	{
		return Size(GetSystemMetrics(SM_CXSIZEFRAME), GetSystemMetrics(SM_CYSIZEFRAME));
	}
	
	
	///
	void onSplitterMoving(SplitterEventArgs sea)
	{
		
		
		splitterMoving(this, sea);
	}
	
	
	///
	void onSplitterMoved(SplitterEventArgs sea)
	{
		splitterMoving(this, sea);
	}
	
	
	private:
	
	bool downing = false;
	bool mgrip = true;
	//Point downpos;
	int downpos;
	int lastpos;
	int msize = 25; // Min size of control that's being sized from the splitter.
	int mextra = 25; // Min size of the control on the opposite side.
	
	static HBRUSH hbrxor;
	
	
	static void inithbrxor()
	{
		const ubyte[] bmbits = [0xAA, 0, 0x55, 0, 0xAA, 0, 0x55, 0,
			0xAA, 0, 0x55, 0, 0xAA, 0, 0x55, 0, ];
		
		HBITMAP hbm;
		hbm = CreateBitmap(8, 8, 1, 1, bmbits.ptr);
		hbrxor = CreatePatternBrush(hbm);
		DeleteObject(hbm);
	}
	
	
	static void drawxor(HDC hdc, Rect r)
	{
		SetBrushOrgEx(hdc, r.x, r.y, null);
		HGDIOBJ hbrold = SelectObject(hdc, hbrxor);
		PatBlt(hdc, r.x, r.y, r.width, r.height, PATINVERT);
		SelectObject(hdc, hbrold);
	}
	
	
	void drawxorClient(HDC hdc, int x, int y)
	{
		POINT pt;
		pt.x = x;
		pt.y = y;
		//ClientToScreen(handle, &pt);
		MapWindowPoints(handle, parent.handle, &pt, 1);
		
		drawxor(hdc, Rect(pt.x, pt.y, width, height));
	}
	
	
	void drawxorClient(int x, int y, int xold = int.min, int yold = int.min)
	{
		HDC hdc;
		//hdc = GetWindowDC(null);
		hdc = GetDCEx(parent.handle, null, DCX_CACHE);
		
		if(xold != int.min)
			drawxorClient(hdc, xold, yold);
		
		drawxorClient(hdc, x, y);
		
		ReleaseDC(null, hdc);
	}
}

