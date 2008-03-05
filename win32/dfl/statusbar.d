// Written by Christopher E. Miller
// See the included license.txt for copyright and license details.


///
module dfl.statusbar;


private import dfl.control, dfl.base, dfl.internal.winapi, dfl.event,
	dfl.collections, dfl.internal.utf, dfl.internal.dlib, dfl.application;

private import dfl.internal.dlib;


private extern(Windows) void _initStatusbar();


/+
enum StatusBarPanelAutoSize: ubyte
{
	NONE,
	CONTENTS,
	SPRING,
}
+/


///
enum StatusBarPanelBorderStyle: ubyte
{
	NONE, ///
	SUNKEN, /// ditto
	RAISED /// ditto
}


///
class StatusBarPanel: DObject
{
	///
	this(char[] text)
	{
		this._txt = text;
	}
	
	/// ditto
	this(char[] text, int width)
	{
		this._txt = text;
		this._width = width;
	}
	
	/// ditto
	this()
	{
	}
	
	
	override char[] toString()
	{
		return _txt;
	}
	
	
	override int opEquals(Object o)
	{
		return _txt == getObjectString(o); // ?
	}
	
	int opEquals(StatusBarPanel pnl)
	{
		return _txt == pnl._txt;
	}
	
	int opEquals(char[] val)
	{
		return _txt == val;
	}
	
	
	override int opCmp(Object o)
	{
		return stringICmp(_txt, getObjectString(o)); // ?
	}
	
	int opCmp(StatusBarPanel pnl)
	{
		return stringICmp(_txt, pnl._txt);
	}
	
	int opCmp(char[] val)
	{
		return stringICmp(_txt, val);
	}
	
	
	/+
	///
	final void alignment(HorizontalAlignment ha) // setter
	{
		
	}
	
	/// ditto
	final HorizontalAlignment alignment() // getter
	{
		//LEFT
	}
	+/
	
	
	/+
	///
	final void autoSize(StatusBarPanelAutoSize asize) // setter
	{
		
	}
	
	/// ditto
	final StatusBarPanelAutoSize autoSize() // getter
	{
		//NONE
	}
	+/
	
	
	///
	final void borderStyle(StatusBarPanelBorderStyle bs) // setter
	{
		switch(bs)
		{
			case StatusBarPanelBorderStyle.NONE:
				_utype = (_utype & ~SBT_POPOUT) | SBT_NOBORDERS;
				break;
			
			case StatusBarPanelBorderStyle.RAISED:
				_utype = (_utype & ~SBT_NOBORDERS) | SBT_POPOUT;
				break;
			
			case StatusBarPanelBorderStyle.SUNKEN:
				_utype &= ~(SBT_NOBORDERS | SBT_POPOUT);
				break;
			
			default:
				assert(0);
		}
		
		if(_parent && _parent.isHandleCreated)
		{
			_parent.panels._fixtexts(); // Also fixes styles.
		}
	}
	
	/// ditto
	final StatusBarPanelBorderStyle borderStyle() // getter
	{
		if(_utype & SBT_POPOUT)
			return StatusBarPanelBorderStyle.RAISED;
		if(_utype & SBT_NOBORDERS)
			return StatusBarPanelBorderStyle.NONE;
		return StatusBarPanelBorderStyle.RAISED;
	}
	
	
	// icon
	
	
	/+
	///
	final void minWidth(int mw) // setter
	in
	{
		assert(mw >= 0);
	}
	body
	{
		
	}
	
	/// ditto
	final int minWidth() // getter
	{
		//10
	}
	+/
	
	
	///
	final StatusBar parent() // getter
	{
		return _parent;
	}
	
	
	// style
	
	
	///
	final void text(char[] txt) // setter
	{
		if(_parent && _parent.isHandleCreated)
		{
			int idx = _parent.panels.indexOf(this);
			assert(-1 != idx);
			_parent._sendidxtext(idx, _utype, txt);
		}
		
		this._txt = txt;
	}
	
	/// ditto
	final char[] text() // getter
	{
		return _txt;
	}
	
	
	/+
	///
	final void toolTipText(char[] txt) // setter
	{
		
	}
	
	/// ditto
	final char[] toolTipText() // getter
	{
		//null
	}
	+/
	
	
	///
	final void width(int w) // setter
	{
		_width = w;
		
		if(_parent && _parent.isHandleCreated)
		{
			_parent.panels._fixwidths();
		}
	}
	
	/// ditto
	final int width() // getter
	{
		return _width;
	}
	
	
	private:
	
	char[] _txt = null;
	int _width = 100;
	StatusBar _parent = null;
	WPARAM _utype = 0; // StatusBarPanelBorderStyle.SUNKEN.
}


/+
///
class StatusBarPanelClickEventArgs: MouseEventArgs
{
	///
	this(StatusBarPanel sbpanel, MouseButtons btn, int clicks, int x, int y)
	{
		this._sbpanel = sbpanel;
		super(btn, clicks, x, y, 0);
	}
	
	
	private:
	StatusBarPanel _sbpanel;
}
+/


///
class StatusBar: ControlSuperClass // docmain
{
	///
	class StatusBarPanelCollection
	{
		protected this(StatusBar sb)
		in
		{
			assert(sb.lpanels is null);
		}
		body
		{
			this.sb = sb;
		}
		
		
		private:
		
		StatusBar sb;
		package StatusBarPanel[] _panels;
		
		
		package void _fixwidths()
		{
			assert(isHandleCreated);
			
			UINT[20] _pws = void;
			UINT[] pws = _pws;
			if(_panels.length > _pws.length)
				pws = new UINT[_panels.length];
			foreach(idx, pnl; _panels)
			{
				pws[idx] = pnl.width;
			}
			sb.prevwproc(SB_SETPARTS, cast(WPARAM)_panels.length, cast(LPARAM)pws.ptr);
		}
		
		
		void _fixtexts()
		{
			assert(isHandleCreated);
			
			if(dfl.internal.utf.useUnicode)
			{
				foreach(idx, pnl; _panels)
				{
					sb.prevwproc(SB_SETTEXTW, cast(WPARAM)idx | pnl._utype, cast(LPARAM)dfl.internal.utf.toUnicodez(pnl._txt));
				}
			}
			else
			{
				foreach(idx, pnl; _panels)
				{
					sb.prevwproc(SB_SETTEXTA, cast(WPARAM)idx | pnl._utype, cast(LPARAM)dfl.internal.utf.toAnsiz(pnl._txt));
				}
			}
		}
		
		
		void _setcurparts()
		{
			assert(isHandleCreated);
			
			_fixwidths();
			
			_fixtexts();
		}
		
		
		void _removed(size_t idx, Object val)
		{
			if(size_t.max == idx) // Clear all.
			{
				if(sb.isHandleCreated)
				{
					sb.prevwproc(SB_SETPARTS, 0, 0); // 0 parts.
				}
			}
			else
			{
				if(sb.isHandleCreated)
				{
					_setcurparts();
				}
			}
		}
		
		
		void _added(size_t idx, StatusBarPanel val)
		{
			if(val._parent)
				throw new DflException("StatusBarPanel already belongs to a StatusBar");
			
			val._parent = sb;
			
			if(sb.isHandleCreated)
			{
				_setcurparts();
			}
		}
		
		
		void _adding(size_t idx, StatusBarPanel val)
		{
			if(_panels.length >= 254) // Since SB_SETTEXT with 255 has special meaning.
				throw new DflException("Too many status bar panels");
		}
		
		
		public:
		
		mixin ListWrapArray!(StatusBarPanel, _panels,
			_adding, _added,
			_blankListCallback!(StatusBarPanel), _removed,
			true, /+true+/ false, false) _wraparray;
	}
	
	
	///
	this()
	{
		_initStatusbar();
		
		_issimple = true;
		wstyle |= SBARS_SIZEGRIP;
		wclassStyle = statusbarClassStyle;
		//height = ?;
		dock = DockStyle.BOTTOM;
		
		lpanels = new StatusBarPanelCollection(this);
	}
	
	
	// backColor / font / foreColor ...
	
	
	override void dock(DockStyle ds) // setter
	{
		switch(ds)
		{
			case DockStyle.BOTTOM:
			case DockStyle.TOP:
				super.dock = ds;
				break;
			
			default:
				throw new DflException("Invalid status bar dock");
		}
	}
	
	alias Control.dock dock; // Overload.
	
	
	///
	final StatusBarPanelCollection panels() // getter
	{
		return lpanels;
	}
	
	
	///
	final void showPanels(bool byes) // setter
	{
		if(!byes == _issimple)
			return;
		
		if(isHandleCreated)
		{
			prevwproc(SB_SIMPLE, cast(WPARAM)!byes, 0);
			
			/+ // It's kept in sync even if simple.
			if(byes)
			{
				panels._setcurparts();
			}
			+/
			
			if(!byes)
			{
				_sendidxtext(255, 0, _simpletext);
			}
		}
		
		_issimple = !byes;
	}
	
	/// ditto
	final bool showPanels() // getter
	{
		return !_issimple;
	}
	
	
	///
	final void sizingGrip(bool byes) // setter
	{
		if(byes == sizingGrip)
			return;
		
		if(byes)
			_style(_style() | SBARS_SIZEGRIP);
		else
			_style(_style() & ~SBARS_SIZEGRIP);
	}
	
	/// ditto
	final bool sizingGrip() // getter
	{
		if(wstyle & SBARS_SIZEGRIP)
			return true;
		return false;
	}
	
	
	override void text(char[] txt) // setter
	{
		if(isHandleCreated && !showPanels)
		{
			_sendidxtext(255, 0, txt);
		}
		
		this._simpletext = txt;
		
		onTextChanged(EventArgs.empty);
	}
	
	/// ditto
	override char[] text() // getter
	{
		return this._simpletext;
	}
	
	
	protected override void onHandleCreated(EventArgs ea)
	{
		super.onHandleCreated(ea);
		
		if(_issimple)
		{
			prevwproc(SB_SIMPLE, cast(WPARAM)true, 0);
			panels._setcurparts();
			if(_simpletext.length)
				_sendidxtext(255, 0, _simpletext);
		}
		else
		{
			panels._setcurparts();
			prevwproc(SB_SIMPLE, cast(WPARAM)false, 0);
		}
	}
	
	
	protected override void createParams(inout CreateParams cp)
	{
		super.createParams(cp);
		
		cp.className = STATUSBAR_CLASSNAME;
	}
	
	
	protected override void prevWndProc(inout Message msg)
	{
		//msg.result = CallWindowProcA(statusbarPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
		msg.result = dfl.internal.utf.callWindowProc(statusbarPrevWndProc, msg.hWnd, msg.msg, msg.wParam, msg.lParam);
	}
	
	
	/+
	protected override void createHandle()
	{
		//CreateStatusWindow
	}
	+/
	
	
	//StatusBarPanelClickEventHandler panelClick;
	//Event!(StatusBar, StatusBarPanelClickEventArgs) panelClick; ///
	
	
	protected:
	
	// onDrawItem ...
	
	
	/+
	///
	void onPanelClick(StatusBarPanelClickEventArgs ea)
	{
		panelClick(this, ea);
	}
	+/
	
	
	private:
	
	StatusBarPanelCollection lpanels;
	char[] _simpletext = null;
	bool _issimple = true;
	
	
	package:
	final:
	
	LRESULT prevwproc(UINT msg, WPARAM wparam, LPARAM lparam)
	{
		//return CallWindowProcA(statusbarPrevWndProc, hwnd, msg, wparam, lparam);
		return dfl.internal.utf.callWindowProc(statusbarPrevWndProc, hwnd, msg, wparam, lparam);
	}
	
	
	void _sendidxtext(int idx, WPARAM utype, char[] txt)
	{
		assert(isHandleCreated);
		
		if(dfl.internal.utf.useUnicode)
			prevwproc(SB_SETTEXTW, cast(WPARAM)idx | utype, cast(LPARAM)dfl.internal.utf.toUnicodez(txt));
		else
			prevwproc(SB_SETTEXTA, cast(WPARAM)idx | utype, cast(LPARAM)dfl.internal.utf.toAnsiz(txt));
	}
}

